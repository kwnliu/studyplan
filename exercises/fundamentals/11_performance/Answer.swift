import UIKit
import CoreData

// MARK: - Exercise 1: Memory Management

class PhotoGalleryViewController: UICollectionViewController {
    private let imageLoader = ImageLoader()
    private var photos: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell",
                                                     for: indexPath) as! PhotoCell
        
        let photo = photos[indexPath.item]
        
        // Load image with proper memory management
        imageLoader.loadImage(from: photo.url) { [weak cell] image in
            cell?.imageView.image = image
        }
        
        return cell
    }
    
    @objc private func handleMemoryWarning() {
        imageLoader.clearMemory()
    }
}

class ImageLoader {
    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "ImageLoader", qos: .utility)
    private let fileManager = FileManager.default
    
    init() {
        // Configure cache limits
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        cache.countLimit = 100
    }
    
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString as NSString
        
        // Check memory cache
        if let cachedImage = cache.object(forKey: key) {
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        if let diskCachedImage = loadImageFromDisk(for: key) {
            cache.setObject(diskCachedImage, forKey: key)
            completion(diskCachedImage)
            return
        }
        
        // Download image
        queue.async {
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Save to caches
            self.cache.setObject(image, forKey: key)
            self.saveImageToDisk(image, for: key)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    func clearMemory() {
        cache.removeAllObjects()
    }
    
    private func loadImageFromDisk(for key: NSString) -> UIImage? {
        let fileURL = getCacheURL().appendingPathComponent(key.hash.description)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    private func saveImageToDisk(_ image: UIImage, for key: NSString) {
        let fileURL = getCacheURL().appendingPathComponent(key.hash.description)
        try? image.pngData()?.write(to: fileURL)
    }
    
    private func getCacheURL() -> URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("ImageCache")
    }
}

// MARK: - Exercise 2: UI Performance

class OptimizedTableViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private let cellReuseIdentifier = "Cell"
    private let imageLoader = ImageLoader()
    private var items: [Item] = []
    private var prefetchOperations: [IndexPath: Operation] = [:]
    private let operationQueue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable prefetching
        tableView.prefetchDataSource = self
        
        // Pre-calculate cell heights
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        // Configure operation queue
        operationQueue.maxConcurrentOperationCount = 3
    }
    
    override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier,
                                               for: indexPath) as! CustomCell
        
        let item = items[indexPath.row]
        
        // Configure text off main thread
        DispatchQueue.global(qos: .userInitiated).async {
            let attributedText = self.prepareAttributedText(for: item)
            
            DispatchQueue.main.async {
                cell.titleLabel.attributedText = attributedText
            }
        }
        
        // Load image
        imageLoader.loadImage(from: item.imageURL) { [weak cell] image in
            cell?.itemImageView.image = image
        }
        
        return cell
    }
    
    // MARK: - UITableViewDataSourcePrefetching
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let item = items[indexPath.row]
            
            let operation = BlockOperation {
                self.imageLoader.loadImage(from: item.imageURL) { _ in }
            }
            
            prefetchOperations[indexPath] = operation
            operationQueue.addOperation(operation)
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let operation = prefetchOperations[indexPath] {
                operation.cancel()
                prefetchOperations.removeValue(forKey: indexPath)
            }
        }
    }
    
    private func prepareAttributedText(for item: Item) -> NSAttributedString {
        // Complex text processing
        return NSAttributedString(string: item.title)
    }
}

// MARK: - Exercise 3: Data Management

class CoreDataOptimizer {
    private let context: NSManagedObjectContext
    private let batchSize = 1000
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func optimizedFetch<T: NSManagedObject>(
        entityName: String,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        // Configure fetch batch size
        request.fetchBatchSize = batchSize
        
        // Use NSDictionaryResultType for better performance when possible
        if sortDescriptors == nil {
            request.resultType = .dictionaryResultType
        }
        
        return try context.fetch(request)
    }
    
    func batchUpdate(
        entityName: String,
        propertiesToUpdate: [AnyHashable: Any],
        predicate: NSPredicate? = nil
    ) throws {
        let request = NSBatchUpdateRequest(entityName: entityName)
        request.predicate = predicate
        request.propertiesToUpdate = propertiesToUpdate
        request.resultType = .updatedObjectIDsResultType
        
        let result = try context.execute(request) as? NSBatchUpdateResult
        
        // Merge changes into context
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes = [NSUpdatedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes,
                into: [context]
            )
        }
    }
    
    func batchDelete(
        entityName: String,
        predicate: NSPredicate? = nil
    ) throws {
        let request = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: entityName))
        request.predicate = predicate
        request.resultType = .resultTypeObjectIDs
        
        let result = try context.execute(request) as? NSBatchDeleteResult
        
        // Merge changes into context
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes,
                into: [context]
            )
        }
    }
}

// MARK: - Exercise 4: Network Performance

class NetworkOptimizer {
    private let session: URLSession
    private let cache = URLCache(
        memoryCapacity: 10 * 1024 * 1024,  // 10MB
        diskCapacity: 50 * 1024 * 1024,    // 50MB
        diskPath: "NetworkCache"
    )
    
    init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = cache
        
        session = URLSession(configuration: config)
    }
    
    func optimizedRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        // Check cache first
        if let cachedResponse = cache.cachedResponse(for: request),
           let decodedObject = try? JSONDecoder().decode(T.self, from: cachedResponse.data) {
            return decodedObject
        }
        
        // Make network request
        let (data, response) = try await session.data(for: request)
        
        // Cache response
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200 {
            let cachedResponse = CachedURLResponse(
                response: response,
                data: data,
                userInfo: nil,
                storagePolicy: .allowed
            )
            cache.storeCachedResponse(cachedResponse, for: request)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func batchRequests<T: Decodable>(_ requests: [URLRequest]) async throws -> [T] {
        try await withThrowingTaskGroup(of: T.self) { group in
            for request in requests {
                group.addTask {
                    try await self.optimizedRequest(request)
                }
            }
            
            var results: [T] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}

// MARK: - Exercise 5: Resource Management

class ResourceManager {
    private let cache = NSCache<NSString, AnyObject>()
    private let fileManager = FileManager.default
    private var loadedResources: [String: Any] = [:]
    private var observers: [NSObjectProtocol] = []
    
    init() {
        setupMemoryWarningObserver()
    }
    
    func loadResource<T>(name: String, extension: String) throws -> T {
        // Check memory cache
        let key = "\(name).\(`extension`)" as NSString
        if let resource = cache.object(forKey: key) as? T {
            return resource
        }
        
        // Load from bundle
        guard let url = Bundle.main.url(forResource: name, withExtension: `extension`) else {
            throw ResourceError.notFound
        }
        
        let data = try Data(contentsOf: url)
        
        // Parse and cache resource
        let resource: T
        switch T.self {
        case is UIImage.Type:
            guard let image = UIImage(data: data) as? T else {
                throw ResourceError.invalidFormat
            }
            resource = image
        case is [String: Any].Type:
            guard let json = try JSONSerialization.jsonObject(with: data) as? T else {
                throw ResourceError.invalidFormat
            }
            resource = json
        default:
            throw ResourceError.unsupportedType
        }
        
        cache.setObject(resource as AnyObject, forKey: key)
        return resource
    }
    
    func clearCache() {
        cache.removeAllObjects()
        loadedResources.removeAll()
    }
    
    private func setupMemoryWarningObserver() {
        let observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearCache()
        }
        
        observers.append(observer)
    }
    
    deinit {
        observers.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }
}

enum ResourceError: Error {
    case notFound
    case invalidFormat
    case unsupportedType
}

// MARK: - Support Types

struct Photo {
    let url: URL
}

struct Item {
    let title: String
    let imageURL: URL
}

class CustomCell: UITableViewCell {
    let titleLabel = UILabel()
    let itemImageView = UIImageView()
} 
import Foundation
import XCTest

// MARK: - Exercise 1: Photo Gallery Implementation

struct Photo {
    let id: UUID
    let url: URL
}

class PhotoGalleryManager {
    private var photos: [Photo] = []
    var onPhotoSelected: ((Photo) -> Void)?
    var onGalleryUpdated: (() -> Void)?
    
    func selectPhoto(_ photo: Photo) {
        photos.append(photo)
        onPhotoSelected?(photo)
    }
    
    func updateGallery() {
        // Simulate gallery update
        onGalleryUpdated?()
    }
    
    deinit {
        print("PhotoGalleryManager deallocated")
    }
}

class PhotoGalleryViewController {
    let manager: PhotoGalleryManager
    weak var photoDetailViewController: PhotoDetailViewController?
    
    init(manager: PhotoGalleryManager) {
        self.manager = manager
    }
    
    func setupCallbacks() {
        // Use capture list to avoid retain cycle
        manager.onPhotoSelected = { [weak self] photo in
            let detailVC = PhotoDetailViewController()
            detailVC.galleryViewController = self
            self?.photoDetailViewController = detailVC
            detailVC.setup()
        }
    }
    
    deinit {
        print("PhotoGalleryViewController deallocated")
    }
}

class PhotoDetailViewController {
    weak var galleryViewController: PhotoGalleryViewController?
    var onDismiss: (() -> Void)?
    
    func setup() {
        // Use capture list to avoid retain cycle
        onDismiss = { [weak self] in
            self?.galleryViewController?.photoDetailViewController = nil
        }
    }
    
    deinit {
        print("PhotoDetailViewController deallocated")
    }
}

// MARK: - Exercise 2: Cache System Implementation

class CacheManager {
    var storage: [String: CacheItem] = [:]
    var cleanupHandler: (() -> Void)?
    
    func store(_ item: CacheItem, forKey key: String) {
        storage[key] = item
    }
    
    func retrieve(forKey key: String) -> CacheItem? {
        return storage[key]
    }
    
    func cleanup() {
        storage.removeAll()
        cleanupHandler?()
    }
    
    deinit {
        cleanup()
        print("CacheManager deallocated")
    }
}

class CacheItem {
    let data: Data
    weak var manager: CacheManager?
    private var _dependencies: [WeakCacheItem] = []
    
    var dependencies: [CacheItem] {
        get { _dependencies.compactMap { $0.item } }
        set { _dependencies = newValue.map { WeakCacheItem(item: $0) } }
    }
    
    var onEviction: (() -> Void)?
    
    init(data: Data) {
        self.data = data
    }
    
    deinit {
        onEviction?()
        print("CacheItem deallocated")
    }
}

// Wrapper to hold weak references to cache items
private class WeakCacheItem {
    weak var item: CacheItem?
    
    init(item: CacheItem) {
        self.item = item
    }
}

// MARK: - Exercise 3: Delegation Pattern Implementation

protocol ContainerViewDelegate: AnyObject {
    func containerViewDidUpdate(_ view: ContainerView)
    func containerView(_ view: ContainerView, didSelect item: Int)
}

class ContainerView {
    weak var delegate: ContainerViewDelegate?
    private var _items: [WeakItemView] = []
    
    var items: [ItemView] {
        return _items.compactMap { $0.item }
    }
    
    func addItem(_ item: ItemView) {
        item.containerView = self
        _items.append(WeakItemView(item: item))
        updateLayout()
    }
    
    func removeItem(_ item: ItemView) {
        _items.removeAll { $0.item === item }
        item.containerView = nil
        updateLayout()
    }
    
    func updateLayout() {
        delegate?.containerViewDidUpdate(self)
    }
    
    deinit {
        print("ContainerView deallocated")
    }
}

private class WeakItemView {
    weak var item: ItemView?
    
    init(item: ItemView) {
        self.item = item
    }
}

protocol ItemViewDelegate: AnyObject {
    func itemViewDidTap(_ view: ItemView)
}

class ItemView {
    weak var delegate: ItemViewDelegate?
    weak var containerView: ContainerView?
    var updateHandler: (() -> Void)?
    
    func setup() {
        // Use capture list to avoid retain cycle
        updateHandler = { [weak self] in
            guard let self = self else { return }
            self.update()
        }
    }
    
    func update() {
        // Update implementation
    }
    
    deinit {
        print("ItemView deallocated")
    }
}

// MARK: - Exercise 4: Network Operation Implementation

class NetworkOperationManager {
    private var _operations: [WeakOperation] = []
    
    var operations: [Operation] {
        return _operations.compactMap { $0.operation }
    }
    
    var completionHandler: (() -> Void)?
    
    func addOperation(_ operation: Operation) {
        operation.manager = self
        _operations.append(WeakOperation(operation: operation))
        operation.start()
    }
    
    func cancelAllOperations() {
        operations.forEach { $0.cancel() }
        _operations.removeAll()
    }
    
    func handleCompletion() {
        completionHandler?()
    }
    
    deinit {
        cancelAllOperations()
        print("NetworkOperationManager deallocated")
    }
}

private class WeakOperation {
    weak var operation: Operation?
    
    init(operation: Operation) {
        self.operation = operation
    }
}

class Operation {
    weak var manager: NetworkOperationManager?
    var onProgress: ((Float) -> Void)?
    var onCompletion: ((Result<Data, Error>) -> Void)?
    private var isRunning = false
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        // Simulate network operation
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // Report progress
            self.onProgress?(0.5)
            
            // Simulate completion
            DispatchQueue.main.async {
                self.isRunning = false
                self.onCompletion?(.success(Data()))
                self.manager?.handleCompletion()
            }
        }
    }
    
    func cancel() {
        isRunning = false
        onProgress = nil
        onCompletion = nil
    }
    
    deinit {
        cancel()
        print("Operation deallocated")
    }
}

// MARK: - Tests

class MemoryManagementTests: XCTestCase {
    func testPhotoGalleryMemoryManagement() {
        var galleryVC: PhotoGalleryViewController? = PhotoGalleryViewController(manager: PhotoGalleryManager())
        weak var weakGalleryVC = galleryVC
        
        galleryVC?.setupCallbacks()
        galleryVC?.manager.selectPhoto(Photo(id: UUID(), url: URL(string: "https://example.com")!))
        
        // Release strong reference
        galleryVC = nil
        
        // Assert deallocation
        XCTAssertNil(weakGalleryVC, "PhotoGalleryViewController should be deallocated")
    }
    
    func testCacheMemoryManagement() {
        var cacheManager: CacheManager? = CacheManager()
        weak var weakManager = cacheManager
        
        let item1 = CacheItem(data: Data())
        let item2 = CacheItem(data: Data())
        
        cacheManager?.store(item1, forKey: "item1")
        cacheManager?.store(item2, forKey: "item2")
        
        // Create circular dependency
        item1.dependencies = [item2]
        item2.dependencies = [item1]
        
        // Release strong reference
        cacheManager = nil
        
        // Assert deallocation
        XCTAssertNil(weakManager, "CacheManager should be deallocated")
    }
    
    func testDelegationMemoryManagement() {
        var containerView: ContainerView? = ContainerView()
        weak var weakContainerView = containerView
        
        let item = ItemView()
        containerView?.addItem(item)
        
        // Release strong reference
        containerView = nil
        
        // Assert deallocation
        XCTAssertNil(weakContainerView, "ContainerView should be deallocated")
    }
    
    func testNetworkOperationMemoryManagement() {
        var manager: NetworkOperationManager? = NetworkOperationManager()
        weak var weakManager = manager
        
        let operation = Operation()
        manager?.addOperation(operation)
        
        // Release strong reference
        manager = nil
        
        // Assert deallocation
        XCTAssertNil(weakManager, "NetworkOperationManager should be deallocated")
    }
}

// Note: This is a sample implementation. A complete solution would include:
// 1. More comprehensive error handling
// 2. Additional test cases for edge cases
// 3. Better documentation
// 4. More robust networking implementation
// 5. UI integration
// 6. Proper threading and synchronization
// 7. Resource cleanup
// 8. Performance optimizations 
import UIKit
import BackgroundTasks
import CoreLocation

// MARK: - Exercise 1: State Management

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let logger = Logger.shared
    private let resourceManager = ResourceManager.shared
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        logger.log("Application did finish launching")
        
        // Setup core services
        setupServices()
        
        // Register for notifications
        registerForNotifications()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        logger.log("Application will resign active")
        resourceManager.pauseNonEssentialTasks()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        logger.log("Application did enter background")
        resourceManager.beginBackgroundTask()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.log("Application will enter foreground")
        resourceManager.prepareForForeground()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        logger.log("Application did become active")
        resourceManager.resumeAllTasks()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        logger.log("Application will terminate")
        resourceManager.cleanup()
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        logger.log("Received memory warning")
        resourceManager.handleMemoryWarning()
    }
    
    private func setupServices() {
        resourceManager.setup()
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleSignificantTimeChange),
                                             name: UIApplication.significantTimeChangeNotification,
                                             object: nil)
    }
    
    @objc private func handleSignificantTimeChange() {
        logger.log("Significant time change occurred")
        resourceManager.handleTimeChange()
    }
}

// MARK: - Exercise 2: Background Processing

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private let backgroundFetchIdentifier = "com.app.backgroundFetch"
    private let backgroundProcessingIdentifier = "com.app.backgroundProcessing"
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundFetchIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundFetch(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundProcessingIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundProcessing(task: task as! BGProcessingTask)
        }
    }
    
    func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundFetchIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.shared.log("Failed to schedule background fetch: \(error)")
        }
    }
    
    private func handleBackgroundFetch(task: BGAppRefreshTask) {
        scheduleBackgroundFetch()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = BackgroundFetchOperation()
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        queue.addOperation(operation)
    }
    
    private func handleBackgroundProcessing(task: BGProcessingTask) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = BackgroundProcessingOperation()
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        queue.addOperation(operation)
    }
}

// MARK: - Exercise 3: State Restoration

class RestorableViewController: UIViewController {
    private enum RestorationKeys {
        static let viewState = "viewState"
        static let scrollPosition = "scrollPosition"
        static let selectedItems = "selectedItems"
    }
    
    private var viewState: ViewState = .initial
    private var scrollPosition: CGPoint = .zero
    private var selectedItems: Set<String> = []
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        coder.encode(viewState.rawValue, forKey: RestorationKeys.viewState)
        coder.encode(scrollPosition, forKey: RestorationKeys.scrollPosition)
        coder.encode(Array(selectedItems), forKey: RestorationKeys.selectedItems)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        if let rawState = coder.decodeObject(forKey: RestorationKeys.viewState) as? Int,
           let state = ViewState(rawValue: rawState) {
            viewState = state
        }
        
        scrollPosition = coder.decodeCGPoint(forKey: RestorationKeys.scrollPosition)
        
        if let items = coder.decodeObject(forKey: RestorationKeys.selectedItems) as? [String] {
            selectedItems = Set(items)
        }
        
        restoreUserInterface()
    }
    
    private func restoreUserInterface() {
        // Restore UI based on saved state
        scrollView.contentOffset = scrollPosition
        
        selectedItems.forEach { itemId in
            if let cell = collectionView.cellForItem(withId: itemId) {
                cell.isSelected = true
            }
        }
        
        updateViewState(viewState)
    }
}

// MARK: - Exercise 4: Launch Time Optimization

class AppLaunchOptimizer {
    static let shared = AppLaunchOptimizer()
    private let launchProfiler = LaunchProfiler()
    
    func optimizeLaunch() {
        launchProfiler.startProfiling()
        
        // Perform critical initialization
        initializeCriticalSystems()
        
        // Defer non-critical work
        DispatchQueue.global(qos: .utility).async {
            self.initializeNonCriticalSystems()
        }
        
        launchProfiler.endProfiling()
    }
    
    private func initializeCriticalSystems() {
        // Initialize core services
        DatabaseManager.shared.initialize()
        NetworkManager.shared.initialize()
        
        // Load minimal UI resources
        ResourceLoader.shared.loadCriticalResources()
    }
    
    private func initializeNonCriticalSystems() {
        // Initialize analytics
        AnalyticsManager.shared.initialize()
        
        // Prefetch resources
        ResourceLoader.shared.prefetchCommonResources()
        
        // Setup background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }
}

// MARK: - Exercise 5: Memory Management

class ResourceManager {
    static let shared = ResourceManager()
    private var memoryWarningCount = 0
    private let cache = NSCache<NSString, AnyObject>()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func setup() {
        setupCache()
        setupMemoryWarningObserver()
    }
    
    func handleMemoryWarning() {
        memoryWarningCount += 1
        
        // Clear memory based on warning level
        switch memoryWarningCount {
        case 1:
            clearNonEssentialMemory()
        case 2:
            clearAllCaches()
        default:
            performEmergencyCleanup()
        }
    }
    
    func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        performBackgroundWork()
    }
    
    private func clearNonEssentialMemory() {
        cache.removeAllObjects()
        ResourceLoader.shared.clearNonEssentialResources()
    }
    
    private func clearAllCaches() {
        clearNonEssentialMemory()
        ImageCache.shared.clearMemory()
        DatabaseManager.shared.clearMemoryCache()
    }
    
    private func performEmergencyCleanup() {
        clearAllCaches()
        cancelAllOperations()
        notifyLowMemory()
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

// MARK: - Support Classes

class Logger {
    static let shared = Logger()
    
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(timestamp)] \(message)")
    }
}

enum ViewState: Int {
    case initial
    case loading
    case loaded
    case error
}

class LaunchProfiler {
    private var startTime: CFAbsoluteTime = 0
    
    func startProfiling() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func endProfiling() {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        Logger.shared.log("Launch completed in \(elapsed) seconds")
    }
}

// MARK: - Background Operations

class BackgroundFetchOperation: Operation {
    override func main() {
        guard !isCancelled else { return }
        
        // Simulate network request
        Thread.sleep(forTimeInterval: 2)
        
        // Process fetched data
        processData()
    }
    
    private func processData() {
        // Process fetched data
    }
}

class BackgroundProcessingOperation: Operation {
    override func main() {
        guard !isCancelled else { return }
        
        // Simulate heavy processing
        Thread.sleep(forTimeInterval: 5)
        
        // Process data
        processData()
    }
    
    private func processData() {
        // Process data
    }
}

// MARK: - Extensions

extension UICollectionView {
    func cellForItem(withId id: String) -> UICollectionViewCell? {
        // Find cell with matching id
        return nil
    }
} 
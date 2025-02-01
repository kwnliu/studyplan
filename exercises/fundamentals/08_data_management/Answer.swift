import Foundation
import CoreData

// MARK: - Exercise 1: Core Data Implementation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let modelName = "TaskModel"
    private let storeType = NSSQLiteStoreType
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        // Configure store description
        let description = NSPersistentStoreDescription()
        description.type = storeType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - CRUD Operations
    
    func createTask(title: String, category: Category) throws -> Task {
        let task = Task(context: context)
        task.id = UUID()
        task.title = title
        task.createdAt = Date()
        task.category = category
        
        try context.save()
        return task
    }
    
    func fetchTasks(matching predicate: NSPredicate? = nil,
                    sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        return try context.fetch(request)
    }
    
    func updateTask(_ task: Task) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
    
    func deleteTask(_ task: Task) throws {
        context.delete(task)
        try context.save()
    }
    
    // MARK: - Migration Support
    
    func performMigration() throws {
        let coordinator = persistentContainer.persistentStoreCoordinator
        
        guard let url = coordinator.persistentStores.first?.url else {
            throw NSError(domain: "CoreDataError", code: -1, userInfo: nil)
        }
        
        try coordinator.destroyPersistentStore(at: url, ofType: storeType, options: nil)
        try persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: storeType, configurationName: nil, at: url, options: nil)
    }
}

// MARK: - Exercise 2: File System Operations

class FileSystemManager {
    static let shared = FileSystemManager()
    private let fileManager = FileManager.default
    private let coordinator = NSFileCoordinator()
    
    enum FileError: Error {
        case invalidPath
        case readError
        case writeError
        case deleteError
        case moveError
    }
    
    func saveData(_ data: Data, to path: String) throws {
        var error: NSError?
        coordinator.coordinate(writingItemAt: URL(fileURLWithPath: path), options: [], error: &error) { url in
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                print("Write error: \(error)")
            }
        }
        
        if let error = error {
            throw FileError.writeError
        }
    }
    
    func readData(from path: String) throws -> Data {
        var resultData: Data?
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: URL(fileURLWithPath: path), options: [], error: &error) { url in
            do {
                resultData = try Data(contentsOf: url)
            } catch {
                print("Read error: \(error)")
            }
        }
        
        if let error = error {
            throw FileError.readError
        }
        
        guard let data = resultData else {
            throw FileError.readError
        }
        
        return data
    }
    
    func moveFile(from sourcePath: String, to destinationPath: String) throws {
        var error: NSError?
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        coordinator.coordinate(writingItemAt: sourceURL, options: .forMoving,
                             writingItemAt: destinationURL, options: .forReplacing,
                             error: &error) { fromURL, toURL in
            do {
                try fileManager.moveItem(at: fromURL, to: toURL)
            } catch {
                print("Move error: \(error)")
            }
        }
        
        if let error = error {
            throw FileError.moveError
        }
    }
    
    func deleteFile(at path: String) throws {
        var error: NSError?
        coordinator.coordinate(writingItemAt: URL(fileURLWithPath: path), options: .forDeleting, error: &error) { url in
            do {
                try fileManager.removeItem(at: url)
            } catch {
                print("Delete error: \(error)")
            }
        }
        
        if let error = error {
            throw FileError.deleteError
        }
    }
}

// MARK: - Exercise 3: UserDefaults and Property Lists

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            NotificationCenter.default.post(name: PreferencesManager.preferencesChangedNotification,
                                         object: nil,
                                         userInfo: [PreferencesManager.changedKeyUserInfoKey: key])
        }
    }
}

class PreferencesManager {
    static let shared = PreferencesManager()
    static let preferencesChangedNotification = Notification.Name("PreferencesChanged")
    static let changedKeyUserInfoKey = "ChangedKey"
    
    @UserDefault(key: "isDarkMode", defaultValue: false)
    var isDarkMode: Bool
    
    @UserDefault(key: "fontSize", defaultValue: 14)
    var fontSize: Int
    
    @UserDefault(key: "userSettings", defaultValue: [:])
    private var userSettings: [String: Any]
    
    func observe(key: String, change: @escaping (Any?) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: PreferencesManager.preferencesChangedNotification,
                                                    object: nil,
                                                    queue: .main) { notification in
            guard let changedKey = notification.userInfo?[PreferencesManager.changedKeyUserInfoKey] as? String,
                  changedKey == key else {
                return
            }
            
            let value = UserDefaults.standard.object(forKey: key)
            change(value)
        }
    }
    
    func reset() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }
}

// MARK: - Exercise 4: Keychain Integration

enum KeychainError: Error {
    case duplicateEntry
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

class KeychainManager {
    static let shared = KeychainManager()
    
    func save(_ password: String, for account: String,
              accessControl: SecAccessControl? = nil) throws {
        let passwordData = password.data(using: .utf8)!
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData
        ]
        
        if let accessControl = accessControl {
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicateEntry
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func retrievePassword(for account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            throw KeychainError.unexpectedPasswordData
        }
        
        return password
    }
    
    func updatePassword(_ password: String, for account: String) throws {
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func deletePassword(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

// MARK: - Exercise 5: Data Synchronization

class SyncManager {
    static let shared = SyncManager()
    private let queue = OperationQueue()
    private var changeTracker = ChangeTracker()
    
    func sync() async throws {
        // Get changes since last sync
        let changes = try await changeTracker.getChanges()
        
        // Upload local changes
        try await uploadChanges(changes)
        
        // Download remote changes
        let remoteChanges = try await fetchRemoteChanges()
        
        // Resolve conflicts
        let resolvedChanges = try await resolveConflicts(local: changes, remote: remoteChanges)
        
        // Apply resolved changes
        try await applyChanges(resolvedChanges)
        
        // Update last sync timestamp
        changeTracker.updateLastSync()
    }
    
    private func uploadChanges(_ changes: [Change]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for change in changes {
                group.addTask {
                    try await self.uploadChange(change)
                }
            }
            try await group.waitForAll()
        }
    }
    
    private func uploadChange(_ change: Change) async throws {
        // Implement change upload
    }
    
    private func fetchRemoteChanges() async throws -> [Change] {
        // Implement remote change fetching
        return []
    }
    
    private func resolveConflicts(local: [Change], remote: [Change]) async throws -> [Change] {
        var resolved: [Change] = []
        
        for localChange in local {
            if let remoteChange = remote.first(where: { $0.id == localChange.id }) {
                let resolvedChange = try resolveConflict(local: localChange, remote: remoteChange)
                resolved.append(resolvedChange)
            } else {
                resolved.append(localChange)
            }
        }
        
        return resolved
    }
    
    private func resolveConflict(local: Change, remote: Change) throws -> Change {
        // Implement conflict resolution strategy
        return local
    }
    
    private func applyChanges(_ changes: [Change]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for change in changes {
                group.addTask {
                    try await self.applyChange(change)
                }
            }
            try await group.waitForAll()
        }
    }
    
    private func applyChange(_ change: Change) async throws {
        // Implement change application
    }
}

// MARK: - Support Classes

struct Change {
    let id: String
    let type: ChangeType
    let data: Data
    let timestamp: Date
}

enum ChangeType {
    case create
    case update
    case delete
}

class ChangeTracker {
    private var lastSyncTimestamp: Date?
    
    func getChanges() async throws -> [Change] {
        // Implement change tracking
        return []
    }
    
    func updateLastSync() {
        lastSyncTimestamp = Date()
    }
} 
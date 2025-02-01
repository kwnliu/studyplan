# iOS Data Management

## Overview
Data management is a critical aspect of iOS development. This section covers fundamental concepts and best practices for managing data effectively in iOS applications, including persistence, caching, and synchronization strategies.

## Key Concepts

### 1. Core Data
- Data modeling
- Managed objects
- Contexts
- Persistence
- Relationships
- Migrations

### 2. File System
- Sandbox structure
- File operations
- Directory management
- Resource handling
- File coordination

### 3. UserDefaults
- Simple persistence
- Property lists
- Default values
- Data types
- Synchronization

### 4. Keychain
- Secure storage
- Credentials
- Encryption
- Access control
- Sharing

### 5. Data Synchronization
- iCloud
- CloudKit
- Background sync
- Conflict resolution
- Delta updates

## Best Practices

1. **Data Model Design**
   - Normalization
   - Relationships
   - Validation
   - Versioning
   - Documentation

2. **Performance**
   - Batch operations
   - Indexing
   - Caching
   - Prefetching
   - Memory management

3. **Security**
   - Encryption
   - Access control
   - Data sanitization
   - Secure deletion
   - Audit logging

4. **Error Handling**
   - Data validation
   - Recovery strategies
   - Consistency checks
   - Backup mechanisms
   - Error reporting

## Common Use Cases

1. **Core Data Setup**
   ```swift
   class CoreDataStack {
       static let shared = CoreDataStack()
       
       lazy var persistentContainer: NSPersistentContainer = {
           let container = NSPersistentContainer(name: "DataModel")
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
       
       func saveContext() {
           guard context.hasChanges else { return }
           
           do {
               try context.save()
           } catch {
               print("Failed to save context: \(error)")
           }
       }
   }
   ```

2. **File Operations**
   ```swift
   class FileManager {
       static let shared = FileManager.default
       
       func saveData(_ data: Data, to filename: String) throws {
           let url = try fileURL(for: filename)
           try data.write(to: url, options: .atomic)
       }
       
       func loadData(from filename: String) throws -> Data {
           let url = try fileURL(for: filename)
           return try Data(contentsOf: url)
       }
       
       private func fileURL(for filename: String) throws -> URL {
           let documentsURL = try shared.url(
               for: .documentDirectory,
               in: .userDomainMask,
               appropriateFor: nil,
               create: true
           )
           return documentsURL.appendingPathComponent(filename)
       }
   }
   ```

3. **Keychain Access**
   ```swift
   class KeychainManager {
       static func save(_ password: String, for account: String) throws {
           let passwordData = password.data(using: .utf8)!
           
           let query: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: account,
               kSecValueData as String: passwordData
           ]
           
           let status = SecItemAdd(query as CFDictionary, nil)
           guard status == errSecSuccess else {
               throw KeychainError.saveFailed(status)
           }
       }
   }
   ```

## Debug Tools
- Core Data debug tools
- File system inspection
- Memory analysis
- Database browser
- Network inspector

## Common Pitfalls
1. Not handling Core Data migrations
2. Memory leaks in observers
3. Improper error handling
4. Inefficient data access patterns
5. Not implementing proper backup

## Additional Resources
- [Core Data Documentation](https://developer.apple.com/documentation/coredata)
- [File System Programming Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/Introduction/Introduction.html)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [iCloud Documentation](https://developer.apple.com/icloud/) 
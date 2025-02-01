# Memory Management Exercises

## Exercise 1: Retain Cycle Detection and Resolution

### Objective
Identify and fix memory leaks in a photo gallery application that uses closures and delegation.

### Requirements

1. **Photo Gallery Manager**
   ```swift
   class PhotoGalleryManager {
       var onPhotoSelected: ((Photo) -> Void)?
       var onGalleryUpdated: (() -> Void)?
       private var photos: [Photo] = []
       
       func selectPhoto(_ photo: Photo) {
           // Implementation needed
       }
       
       func updateGallery() {
           // Implementation needed
       }
   }
   ```

2. **Photo Gallery View Controller**
   ```swift
   class PhotoGalleryViewController {
       let manager: PhotoGalleryManager
       var photoDetailViewController: PhotoDetailViewController?
       
       func setupCallbacks() {
           // Implementation needed
       }
   }
   ```

3. **Photo Detail View Controller**
   ```swift
   class PhotoDetailViewController {
       var galleryViewController: PhotoGalleryViewController?
       var onDismiss: (() -> Void)?
       
       func setup() {
           // Implementation needed
       }
   }
   ```

### Tasks
1. Identify potential retain cycles in the code
2. Implement the missing methods while avoiding memory leaks
3. Add proper memory management using weak/unowned references
4. Write test cases to verify proper deallocation

## Exercise 2: Collection Cycle Management

### Objective
Create a cache system that properly manages memory for stored objects and their relationships.

### Requirements

1. **Cache Manager**
   ```swift
   class CacheManager {
       var storage: [String: CacheItem] = [:]
       var cleanupHandler: (() -> Void)?
       
       func store(_ item: CacheItem, forKey key: String)
       func retrieve(forKey key: String) -> CacheItem?
       func cleanup()
   }
   ```

2. **Cache Item**
   ```swift
   class CacheItem {
       let data: Data
       var dependencies: [CacheItem]
       var onEviction: (() -> Void)?
       
       init(data: Data)
   }
   ```

### Tasks
1. Implement the CacheManager methods
2. Handle circular dependencies between cache items
3. Implement proper cleanup and memory management
4. Create test cases for memory leak detection

## Exercise 3: Delegation Pattern Implementation

### Objective
Implement a proper delegation pattern for a custom view hierarchy while maintaining correct memory management.

### Requirements

1. **Custom Container View**
   ```swift
   protocol ContainerViewDelegate: AnyObject {
       func containerViewDidUpdate(_ view: ContainerView)
       func containerView(_ view: ContainerView, didSelect item: Int)
   }
   
   class ContainerView {
       var delegate: ContainerViewDelegate?
       var items: [ItemView] = []
       
       func addItem(_ item: ItemView)
       func removeItem(_ item: ItemView)
       func updateLayout()
   }
   ```

2. **Item View**
   ```swift
   protocol ItemViewDelegate: AnyObject {
       func itemViewDidTap(_ view: ItemView)
   }
   
   class ItemView {
       var delegate: ItemViewDelegate?
       var updateHandler: (() -> Void)?
       
       func setup()
       func update()
   }
   ```

### Tasks
1. Implement the delegate pattern with proper memory management
2. Add closure-based callbacks while avoiding retain cycles
3. Handle parent-child relationships between views
4. Create test cases for memory management verification

## Exercise 4: Network Operation Management

### Objective
Create a network operation system that properly manages memory for long-running operations and their callbacks.

### Requirements

1. **Network Operation Manager**
   ```swift
   class NetworkOperationManager {
       var operations: [Operation] = []
       var completionHandler: (() -> Void)?
       
       func addOperation(_ operation: Operation)
       func cancelAllOperations()
       func handleCompletion()
   }
   ```

2. **Operation**
   ```swift
   class Operation {
       var manager: NetworkOperationManager?
       var onProgress: ((Float) -> Void)?
       var onCompletion: ((Result<Data, Error>) -> Void)?
       
       func start()
       func cancel()
   }
   ```

### Tasks
1. Implement proper memory management for operations
2. Handle callback closures without creating retain cycles
3. Implement cleanup for cancelled operations
4. Create test cases for memory leak detection

## Evaluation Criteria
- Proper use of weak/unowned references
- Correct implementation of closure capture lists
- Effective memory cleanup in deinitializers
- Proper handling of parent-child relationships
- Comprehensive test coverage
- Code organization and clarity

## Time Estimate
- Exercise 1: 1-2 hours
- Exercise 2: 2-3 hours
- Exercise 3: 1-2 hours
- Exercise 4: 2-3 hours

## Submission Requirements
1. Complete implementation of all required components
2. Unit tests demonstrating proper memory management
3. Documentation of memory management strategies used
4. Example usage of each component
5. Memory leak detection test cases 
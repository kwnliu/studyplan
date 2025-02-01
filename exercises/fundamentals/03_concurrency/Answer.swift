import Foundation
import UIKit

// MARK: - Exercise 1: Async Image Loading System

actor ImageCache: ImageCaching {
    private var cache: [URL: Image] = [:]
    
    func store(_ image: Image, for url: URL) {
        cache[url] = image
    }
    
    func retrieve(for url: URL) -> Image? {
        return cache[url]
    }
    
    func clear() {
        cache.removeAll()
    }
}

class ImageLoader: ImageLoading {
    private let cache: ImageCache
    private var activeTasks: [URL: Task<Image, Error>] = [:]
    private let taskQueue = DispatchQueue(label: "com.imageloader.queue")
    
    init(cache: ImageCache = ImageCache()) {
        self.cache = cache
    }
    
    func loadImage(from url: URL) async throws -> Image {
        // Check cache first
        if let cachedImage = await cache.retrieve(for: url) {
            return cachedImage
        }
        
        // Create or reuse existing task
        let task = taskQueue.sync { () -> Task<Image, Error> in
            if let existingTask = activeTasks[url] {
                return existingTask
            }
            
            let newTask = Task {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = Image(data: data) else {
                    throw ImageLoadingError.invalidData
                }
                
                await cache.store(image, for: url)
                taskQueue.sync { activeTasks.removeValue(forKey: url) }
                return image
            }
            
            activeTasks[url] = newTask
            return newTask
        }
        
        do {
            return try await task.value
        } catch is CancellationError {
            throw ImageLoadingError.cancelled
        } catch {
            throw ImageLoadingError.networkError(error)
        }
    }
    
    func cancelLoad(for url: URL) {
        taskQueue.sync {
            activeTasks[url]?.cancel()
            activeTasks.removeValue(forKey: url)
        }
    }
    
    func clearCache() {
        Task {
            await cache.clear()
        }
    }
}

// MARK: - Exercise 2: Task Group Data Processing

protocol DataProcessing {
    associatedtype Input
    associatedtype Output
    
    func process(_ input: Input) async throws -> Output
}

protocol BatchProcessing {
    associatedtype Processor: DataProcessing
    
    func processBatch(_ items: [Processor.Input]) async throws -> [Result<Processor.Output, Error>]
    func cancelProcessing()
}

class BatchProcessor<P: DataProcessing>: BatchProcessing {
    typealias Processor = P
    
    private let processor: P
    private let maxConcurrent: Int
    private var currentTask: Task<Void, Never>?
    
    init(processor: P, maxConcurrent: Int = 4) {
        self.processor = processor
        self.maxConcurrent = maxConcurrent
    }
    
    func processBatch(_ items: [P.Input]) async throws -> [Result<P.Output, Error>] {
        let task = Task {
            try await withThrowingTaskGroup(of: (Int, Result<P.Output, Error>).self) { group in
                // Add tasks with limited concurrency
                var added = 0
                var results = Array<Result<P.Output, Error>?>(repeating: nil, count: items.count)
                
                for (index, item) in items.enumerated() {
                    if group.cancelledCount > 0 {
                        break
                    }
                    
                    // Respect concurrency limit
                    while added - group.completedCount >= maxConcurrent {
                        if let result = try await group.next() {
                            results[result.0] = result.1
                            added -= 1
                        }
                    }
                    
                    group.addTask {
                        do {
                            let output = try await self.processor.process(item)
                            return (index, .success(output))
                        } catch {
                            return (index, .failure(error))
                        }
                    }
                    added += 1
                }
                
                // Collect remaining results
                for try await result in group {
                    results[result.0] = result.1
                }
                
                return results.compactMap { $0 }
            }
        }
        
        currentTask = task
        return try await task.value
    }
    
    func cancelProcessing() {
        currentTask?.cancel()
        currentTask = nil
    }
}

// MARK: - Exercise 3: Actor-Based State Management

actor StateManager<State>: StateContainer {
    private var state: State
    private var subscribers: [(State) -> Void] = []
    private var history: [State] = []
    private let maxHistoryItems = 10
    
    init(initialState: State) {
        self.state = initialState
        self.history.append(initialState)
    }
    
    var currentState: State {
        state
    }
    
    func update(_ mutation: (inout State) -> Void) {
        history.append(state)
        if history.count > maxHistoryItems {
            history.removeFirst()
        }
        
        mutation(&state)
        notifySubscribers()
    }
    
    func subscribe(_ handler: @escaping (State) -> Void) {
        subscribers.append(handler)
        handler(state)
    }
    
    func rollback() -> Bool {
        guard let previousState = history.popLast() else {
            return false
        }
        
        state = previousState
        notifySubscribers()
        return true
    }
    
    private func notifySubscribers() {
        subscribers.forEach { $0(state) }
    }
}

// MARK: - Exercise 4: Async Sequence Processing

class StreamProcessor<Element>: StreamProcessing {
    private var continuation: AsyncStream<Element>.Continuation?
    private let transformationPipeline: [(Element) async throws -> Element]
    
    init(transformations: [(Element) async throws -> Element] = []) {
        self.transformationPipeline = transformations
    }
    
    func process(_ stream: AsyncStream<Element>) async throws {
        for try await element in stream {
            var processed = element
            
            for transformation in transformationPipeline {
                processed = try await transformation(processed)
            }
            
            continuation?.yield(processed)
        }
        
        continuation?.finish()
    }
    
    func transform<T>(_ element: Element) async throws -> T {
        fatalError("Must be implemented by concrete subclass")
    }
}

// MARK: - Exercise 5: Distributed Task Management

enum TaskStatus {
    case pending
    case running
    case completed(Any)
    case failed(Error)
    case cancelled
}

actor TaskDistributor<T, R>: TaskDistributing {
    typealias Task = T
    typealias Result = R
    
    private var workers: [Worker<T, R>] = []
    private var taskStatus: [UUID: TaskStatus] = [:]
    private var runningTasks: [UUID: Swift.Task<R, Error>] = [:]
    
    func submit(_ task: T) async throws -> R {
        let taskId = UUID()
        taskStatus[taskId] = .pending
        
        guard let worker = await getLeastLoadedWorker() else {
            throw DistributorError.noAvailableWorkers
        }
        
        let workerTask = Task {
            taskStatus[taskId] = .running
            do {
                let result = try await worker.process(task)
                taskStatus[taskId] = .completed(result)
                return result
            } catch {
                taskStatus[taskId] = .failed(error)
                throw error
            }
        }
        
        runningTasks[taskId] = workerTask
        
        do {
            let result = try await workerTask.value
            runningTasks.removeValue(forKey: taskId)
            return result
        } catch {
            runningTasks.removeValue(forKey: taskId)
            throw error
        }
    }
    
    func cancelTask(id: UUID) {
        runningTasks[id]?.cancel()
        taskStatus[id] = .cancelled
        runningTasks.removeValue(forKey: id)
    }
    
    func getTaskStatus(id: UUID) async -> TaskStatus {
        return taskStatus[id] ?? .pending
    }
    
    private func getLeastLoadedWorker() async -> Worker<T, R>? {
        var leastLoadedWorker: Worker<T, R>?
        var minLoad = Double.infinity
        
        for worker in workers {
            let load = await worker.getLoad()
            if load < minLoad {
                minLoad = load
                leastLoadedWorker = worker
            }
        }
        
        return leastLoadedWorker
    }
}

enum DistributorError: Error {
    case noAvailableWorkers
    case taskCancelled
    case workerFailed
}

// MARK: - Tests

class ConcurrencyTests: XCTestCase {
    func testImageLoading() async throws {
        let loader = ImageLoader()
        let url = URL(string: "https://example.com/image.jpg")!
        
        do {
            let image = try await loader.loadImage(from: url)
            XCTAssertNotNil(image)
        } catch {
            XCTFail("Image loading failed: \(error)")
        }
    }
    
    func testBatchProcessing() async throws {
        class NumberProcessor: DataProcessing {
            func process(_ input: Int) async throws -> Int {
                try await Task.sleep(nanoseconds: 100_000_000)
                return input * 2
            }
        }
        
        let processor = BatchProcessor(processor: NumberProcessor())
        let numbers = Array(1...10)
        
        let results = try await processor.processBatch(numbers)
        XCTAssertEqual(results.count, numbers.count)
    }
    
    func testStateManagement() async {
        let manager = StateManager(initialState: 0)
        
        await manager.update { state in
            state += 1
        }
        
        let state = await manager.currentState
        XCTAssertEqual(state, 1)
    }
}

// Note: This is a sample implementation. A complete solution would include:
// 1. More comprehensive error handling
// 2. Better resource management
// 3. More test cases
// 4. Proper cleanup
// 5. Documentation
// 6. Logging
// 7. Metrics collection
// 8. Performance optimizations 
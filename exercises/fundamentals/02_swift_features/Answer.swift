import Foundation
import XCTest

// MARK: - Exercise 1: Protocol-Oriented Programming

protocol DataProcessor {
    associatedtype Input
    associatedtype Output
    
    func process(_ input: Input) throws -> Output
}

protocol Validatable {
    func validate() throws
}

enum ProcessingError: Error {
    case invalidInput
    case processingFailed
    case validationFailed(String)
}

// Example Data Processors
struct JSONProcessor: DataProcessor {
    typealias Input = Data
    typealias Output = [String: Any]
    
    func process(_ input: Input) throws -> Output {
        guard let json = try? JSONSerialization.jsonObject(with: input) as? [String: Any] else {
            throw ProcessingError.processingFailed
        }
        return json
    }
}

struct StringProcessor: DataProcessor {
    typealias Input = String
    typealias Output = [String]
    
    func process(_ input: Input) throws -> Output {
        guard !input.isEmpty else {
            throw ProcessingError.invalidInput
        }
        return input.components(separatedBy: ",")
    }
}

// Pipeline Implementation
class ProcessingPipeline<T: DataProcessor> {
    private let processor: T
    
    init(processor: T) {
        self.processor = processor
    }
    
    func execute(_ input: T.Input) -> Result<T.Output, Error> {
        do {
            let output = try processor.process(input)
            return .success(output)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Exercise 2: Property Wrappers

@propertyWrapper
struct Persisted<T: Codable> {
    private let key: String
    private let defaultValue: T
    
    var wrappedValue: T {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else {
                return defaultValue
            }
            return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

@propertyWrapper
struct Validated<T> {
    private var value: T
    private let validator: (T) -> Bool
    
    var wrappedValue: T {
        get { value }
        set {
            guard validator(newValue) else {
                return
            }
            value = newValue
        }
    }
    
    init(wrappedValue: T, validator: @escaping (T) -> Bool) {
        self.value = wrappedValue
        self.validator = validator
    }
}

@propertyWrapper
struct Observable<T> {
    private var value: T
    private let onChange: (T) -> Void
    
    var wrappedValue: T {
        get { value }
        set {
            value = newValue
            onChange(newValue)
        }
    }
    
    init(wrappedValue: T, onChange: @escaping (T) -> Void) {
        self.value = wrappedValue
        self.onChange = onChange
    }
}

// MARK: - Exercise 3: Advanced Error Handling

enum NetworkError: Error {
    case invalidURL
    case noData
    case serverError(Int)
    case decodingError
}

enum ValidationError: Error {
    case invalidFormat
    case missingRequired
    case invalidValue(String)
}

protocol ResultHandler {
    associatedtype Success
    associatedtype Failure: Error
    
    func handle(_ result: Result<Success, Failure>)
}

protocol ErrorRecoverable {
    associatedtype RecoveryType
    
    func recover(from error: Error) -> RecoveryType?
}

class NetworkService: ErrorRecoverable {
    typealias RecoveryType = Data
    
    func recover(from error: Error) -> Data? {
        switch error as? NetworkError {
        case .noData:
            return Data() // Return empty data
        case .serverError(let code) where code >= 500:
            return cachedResponse() // Return cached data for server errors
        default:
            return nil
        }
    }
    
    private func cachedResponse() -> Data {
        // Implementation for cached response
        return Data()
    }
}

// MARK: - Exercise 4: Generic Collections

struct PriorityQueue<Element: Comparable> {
    private var elements: [Element] = []
    
    mutating func enqueue(_ element: Element) {
        elements.append(element)
        siftUp(from: elements.count - 1)
    }
    
    mutating func dequeue() -> Element? {
        guard !elements.isEmpty else { return nil }
        
        elements.swapAt(0, elements.count - 1)
        let element = elements.removeLast()
        if !elements.isEmpty {
            siftDown(from: 0)
        }
        return element
    }
    
    private func parentIndex(of index: Int) -> Int {
        (index - 1) / 2
    }
    
    private func leftChildIndex(of index: Int) -> Int {
        2 * index + 1
    }
    
    private func rightChildIndex(of index: Int) -> Int {
        2 * index + 2
    }
    
    private mutating func siftUp(from index: Int) {
        var child = index
        var parent = parentIndex(of: child)
        
        while child > 0 && elements[child] < elements[parent] {
            elements.swapAt(child, parent)
            child = parent
            parent = parentIndex(of: child)
        }
    }
    
    private mutating func siftDown(from index: Int) {
        var parent = index
        
        while true {
            let leftChild = leftChildIndex(of: parent)
            let rightChild = rightChildIndex(of: parent)
            var candidate = parent
            
            if leftChild < elements.count && elements[leftChild] < elements[candidate] {
                candidate = leftChild
            }
            
            if rightChild < elements.count && elements[rightChild] < elements[candidate] {
                candidate = rightChild
            }
            
            if candidate == parent {
                return
            }
            
            elements.swapAt(parent, candidate)
            parent = candidate
        }
    }
}

// MARK: - Exercise 5: Pattern Matching

protocol Pattern {
    associatedtype Target
    func matches(_ target: Target) -> Bool
}

struct RegexPattern: Pattern {
    let pattern: String
    
    func matches(_ target: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        
        let range = NSRange(location: 0, length: target.utf16.count)
        return regex.firstMatch(in: target, options: [], range: range) != nil
    }
}

precedencegroup CompositionPrecedence {
    associativity: left
    higherThan: ApplicationPrecedence
}

precedencegroup ApplicationPrecedence {
    associativity: left
    higherThan: AssignmentPrecedence
}

infix operator <>: CompositionPrecedence
infix operator |>: ApplicationPrecedence

func <> <A, B, C>(lhs: @escaping (B) -> C, rhs: @escaping (A) -> B) -> (A) -> C {
    return { lhs(rhs($0)) }
}

func |> <A, B>(value: A, function: (A) -> B) -> B {
    return function(value)
}

// MARK: - Tests

class SwiftFeaturesTests: XCTestCase {
    // Test Protocol-Oriented Programming
    func testDataProcessing() {
        let jsonProcessor = JSONProcessor()
        let pipeline = ProcessingPipeline(processor: jsonProcessor)
        
        let jsonData = """
        {"name": "Test", "value": 123}
        """.data(using: .utf8)!
        
        let result = pipeline.execute(jsonData)
        
        switch result {
        case .success(let output):
            XCTAssertEqual(output["name"] as? String, "Test")
            XCTAssertEqual(output["value"] as? Int, 123)
        case .failure:
            XCTFail("Processing should succeed")
        }
    }
    
    // Test Property Wrappers
    func testPropertyWrappers() {
        class Settings {
            @Persisted(key: "username", defaultValue: "")
            var username: String
            
            @Validated(wrappedValue: 0) { $0 >= 0 }
            var age: Int
            
            @Observable(wrappedValue: false) { print("Value changed to: \($0)") }
            var isEnabled: Bool
        }
        
        let settings = Settings()
        settings.username = "test_user"
        settings.age = -1 // Should not change due to validation
        settings.isEnabled = true // Should print change notification
        
        XCTAssertEqual(settings.username, "test_user")
        XCTAssertEqual(settings.age, 0)
        XCTAssertTrue(settings.isEnabled)
    }
    
    // Test Error Handling
    func testErrorRecovery() {
        let service = NetworkService()
        let recovery = service.recover(from: NetworkError.noData)
        
        XCTAssertNotNil(recovery)
    }
    
    // Test Generic Collections
    func testPriorityQueue() {
        var queue = PriorityQueue<Int>()
        queue.enqueue(3)
        queue.enqueue(1)
        queue.enqueue(2)
        
        XCTAssertEqual(queue.dequeue(), 1)
        XCTAssertEqual(queue.dequeue(), 2)
        XCTAssertEqual(queue.dequeue(), 3)
    }
    
    // Test Pattern Matching
    func testPatternMatching() {
        let emailPattern = RegexPattern(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
        
        XCTAssertTrue(emailPattern.matches("test@example.com"))
        XCTAssertFalse(emailPattern.matches("invalid-email"))
    }
}

// Note: This is a sample implementation. A complete solution would include:
// 1. More comprehensive error handling
// 2. Additional test cases
// 3. Better documentation
// 4. More robust implementations
// 5. Performance optimizations
// 6. Thread safety considerations
// 7. Memory management
// 8. Logging and debugging support 
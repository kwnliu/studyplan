import XCTest
import CoreData

// MARK: - Exercise 1: Unit Testing Basics

class Calculator {
    enum CalculatorError: Error {
        case divisionByZero
        case overflow
    }
    
    func add(_ a: Int, _ b: Int) throws -> Int {
        let result = a.addingReportingOverflow(b)
        guard !result.overflow else {
            throw CalculatorError.overflow
        }
        return result.partialValue
    }
    
    func subtract(_ a: Int, _ b: Int) throws -> Int {
        let result = a.subtractingReportingOverflow(b)
        guard !result.overflow else {
            throw CalculatorError.overflow
        }
        return result.partialValue
    }
    
    func multiply(_ a: Int, _ b: Int) throws -> Int {
        let result = a.multipliedReportingOverflow(by: b)
        guard !result.overflow else {
            throw CalculatorError.overflow
        }
        return result.partialValue
    }
    
    func divide(_ a: Int, _ b: Int) throws -> Int {
        guard b != 0 else {
            throw CalculatorError.divisionByZero
        }
        return a / b
    }
}

class CalculatorTests: XCTestCase {
    var calculator: Calculator!
    
    override func setUp() {
        super.setUp()
        calculator = Calculator()
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    func testAddition() throws {
        // Test normal addition
        XCTAssertEqual(try calculator.add(5, 3), 8)
        
        // Test negative numbers
        XCTAssertEqual(try calculator.add(-5, 3), -2)
        
        // Test zero
        XCTAssertEqual(try calculator.add(0, 0), 0)
        
        // Test overflow
        XCTAssertThrowsError(try calculator.add(Int.max, 1)) { error in
            XCTAssertEqual(error as? Calculator.CalculatorError, .overflow)
        }
    }
    
    func testDivision() throws {
        // Test normal division
        XCTAssertEqual(try calculator.divide(10, 2), 5)
        
        // Test division by zero
        XCTAssertThrowsError(try calculator.divide(10, 0)) { error in
            XCTAssertEqual(error as? Calculator.CalculatorError, .divisionByZero)
        }
        
        // Test negative numbers
        XCTAssertEqual(try calculator.divide(-10, 2), -5)
    }
    
    func testPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = try? calculator.multiply(5, 3)
            }
        }
    }
}

// MARK: - Exercise 2: Mock Objects and Dependencies

protocol NetworkService {
    func fetchData() async throws -> Data
    func sendData(_ data: Data) async throws
}

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case noData
}

class MockNetworkService: NetworkService {
    var shouldSucceed = true
    var data: Data?
    var error: Error?
    var requestCount = 0
    
    func fetchData() async throws -> Data {
        requestCount += 1
        
        if let error = error {
            throw error
        }
        
        if shouldSucceed {
            return data ?? Data()
        } else {
            throw NetworkError.requestFailed
        }
    }
    
    func sendData(_ data: Data) async throws {
        requestCount += 1
        
        if let error = error {
            throw error
        }
        
        if !shouldSucceed {
            throw NetworkError.requestFailed
        }
    }
}

class DataManager {
    private let networkService: NetworkService
    private let maxRetries = 3
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func fetchDataWithRetry() async throws -> Data {
        var lastError: Error?
        
        for _ in 0..<maxRetries {
            do {
                return try await networkService.fetchData()
            } catch {
                lastError = error
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                continue
            }
        }
        
        throw lastError ?? NetworkError.requestFailed
    }
}

class NetworkTests: XCTestCase {
    var mockService: MockNetworkService!
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        mockService = MockNetworkService()
        dataManager = DataManager(networkService: mockService)
    }
    
    func testFetchDataSuccess() async throws {
        // Given
        let expectedData = "Test".data(using: .utf8)!
        mockService.data = expectedData
        mockService.shouldSucceed = true
        
        // When
        let result = try await dataManager.fetchDataWithRetry()
        
        // Then
        XCTAssertEqual(result, expectedData)
        XCTAssertEqual(mockService.requestCount, 1)
    }
    
    func testFetchDataRetry() async throws {
        // Given
        mockService.shouldSucceed = false
        
        // When/Then
        do {
            _ = try await dataManager.fetchDataWithRetry()
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockService.requestCount, 3)
        }
    }
}

// MARK: - Exercise 3: UI Testing

class LoginUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        app.launch()
    }
    
    func testLoginSuccess() {
        // Given
        let emailField = app.textFields["EmailTextField"]
        let passwordField = app.secureTextFields["PasswordTextField"]
        let loginButton = app.buttons["LoginButton"]
        
        // When
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        loginButton.tap()
        
        // Then
        let dashboardView = app.otherElements["DashboardView"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 5))
    }
    
    func testLoginValidationError() {
        // Given
        let emailField = app.textFields["EmailTextField"]
        let loginButton = app.buttons["LoginButton"]
        
        // When
        emailField.tap()
        emailField.typeText("invalid-email")
        
        loginButton.tap()
        
        // Then
        let errorLabel = app.staticTexts["ErrorLabel"]
        XCTAssertTrue(errorLabel.exists)
        XCTAssertEqual(errorLabel.label, "Invalid email format")
    }
}

// MARK: - Exercise 4: Integration Testing

class CoreDataTests: XCTestCase {
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        container = NSPersistentContainer(name: "TestModel")
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        
        context = container.viewContext
    }
    
    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }
    
    func testTaskCreation() throws {
        // Given
        let task = Task(context: context)
        task.id = UUID()
        task.title = "Test Task"
        task.createdAt = Date()
        
        // When
        try context.save()
        
        // Then
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        let tasks = try context.fetch(request)
        
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Test Task")
    }
    
    func testBatchOperations() throws {
        // Given
        let batchInsert = NSBatchInsertRequest(entity: Task.entity()) { dict in
            dict["title"] = "Task \(dict["index"] as! Int)"
            dict["id"] = UUID()
            dict["createdAt"] = Date()
            return true
        }
        
        // When
        try context.execute(batchInsert)
        
        // Then
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        let tasks = try context.fetch(request)
        
        XCTAssertEqual(tasks.count, 5)
    }
}

// MARK: - Exercise 5: Test-Driven Development

protocol TaskManager {
    func createTask(title: String) throws -> Task
    func fetchTasks(matching predicate: NSPredicate?) throws -> [Task]
    func updateTask(_ task: Task) throws
    func deleteTask(_ task: Task) throws
}

class TaskManagerTests: XCTestCase {
    var manager: TaskManager!
    var container: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        
        container = NSPersistentContainer(name: "TestModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        
        manager = CoreDataTaskManager(container: container)
    }
    
    func testCreateTask() throws {
        // Given
        let title = "Test Task"
        
        // When
        let task = try manager.createTask(title: title)
        
        // Then
        XCTAssertEqual(task.title, title)
        XCTAssertNotNil(task.id)
        XCTAssertNotNil(task.createdAt)
    }
    
    func testFetchTasksWithPredicate() throws {
        // Given
        let task1 = try manager.createTask(title: "Task 1")
        let task2 = try manager.createTask(title: "Task 2")
        
        // When
        let predicate = NSPredicate(format: "title CONTAINS[c] %@", "1")
        let tasks = try manager.fetchTasks(matching: predicate)
        
        // Then
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, task1.id)
    }
    
    func testUpdateTask() throws {
        // Given
        let task = try manager.createTask(title: "Original")
        
        // When
        task.title = "Updated"
        try manager.updateTask(task)
        
        // Then
        let predicate = NSPredicate(format: "id == %@", task.id! as CVarArg)
        let tasks = try manager.fetchTasks(matching: predicate)
        
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Updated")
    }
    
    func testDeleteTask() throws {
        // Given
        let task = try manager.createTask(title: "To Delete")
        
        // When
        try manager.deleteTask(task)
        
        // Then
        let predicate = NSPredicate(format: "id == %@", task.id! as CVarArg)
        let tasks = try manager.fetchTasks(matching: predicate)
        
        XCTAssertEqual(tasks.count, 0)
    }
} 
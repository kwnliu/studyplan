// MARK: - Domain Layer (Entities)

import Foundation

// Core Entities
struct Product {
    let id: UUID
    let name: String
    let description: String
    let price: Decimal
    private(set) var stockQuantity: Int
    
    mutating func updateStock(_ quantity: Int) throws {
        guard quantity >= 0 else {
            throw DomainError.invalidStockQuantity
        }
        stockQuantity = quantity
    }
}

struct Order {
    let id: UUID
    let items: [OrderItem]
    private(set) var status: OrderStatus
    let customerInfo: CustomerInfo
    let createdAt: Date
    
    var totalAmount: Decimal {
        items.reduce(Decimal.zero) { $0 + $1.subtotal }
    }
    
    mutating func updateStatus(_ newStatus: OrderStatus) throws {
        guard status.canTransitionTo(newStatus) else {
            throw DomainError.invalidStatusTransition
        }
        status = newStatus
    }
}

// Value Objects
struct OrderItem {
    let product: Product
    let quantity: Int
    let priceAtOrder: Decimal
    
    var subtotal: Decimal {
        priceAtOrder * Decimal(quantity)
    }
    
    init(product: Product, quantity: Int) throws {
        guard quantity > 0 else {
            throw DomainError.invalidQuantity
        }
        guard quantity <= product.stockQuantity else {
            throw DomainError.insufficientStock
        }
        
        self.product = product
        self.quantity = quantity
        self.priceAtOrder = product.price
    }
}

struct CustomerInfo {
    let id: UUID
    let name: String
    let email: String
    let address: Address
    
    init(id: UUID = UUID(), name: String, email: String, address: Address) throws {
        guard Self.isValidEmail(email) else {
            throw DomainError.invalidEmail
        }
        guard !name.isEmpty else {
            throw DomainError.invalidName
        }
        
        self.id = id
        self.name = name
        self.email = email
        self.address = address
    }
    
    private static func isValidEmail(_ email: String) -> Bool {
        // Implement email validation
        return email.contains("@")
    }
}

struct Address {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
}

// Enums
enum OrderStatus: String {
    case pending
    case confirmed
    case processing
    case shipped
    case delivered
    case cancelled
    
    func canTransitionTo(_ newStatus: OrderStatus) -> Bool {
        switch (self, newStatus) {
        case (.pending, .confirmed),
             (.confirmed, .processing),
             (.processing, .shipped),
             (.shipped, .delivered),
             (.pending, .cancelled),
             (.confirmed, .cancelled):
            return true
        default:
            return false
        }
    }
}

enum DomainError: Error {
    case invalidQuantity
    case insufficientStock
    case invalidStockQuantity
    case invalidStatusTransition
    case invalidEmail
    case invalidName
}

// MARK: - Application Layer (Use Cases)

protocol OrderRepository {
    func save(_ order: Order) throws
    func getById(_ id: UUID) throws -> Order?
    func update(_ order: Order) throws
}

protocol ProductRepository {
    func save(_ product: Product) throws
    func getById(_ id: UUID) throws -> Product?
    func update(_ product: Product) throws
}

class CreateOrderUseCase {
    private let orderRepository: OrderRepository
    private let productRepository: ProductRepository
    
    init(orderRepository: OrderRepository, productRepository: ProductRepository) {
        self.orderRepository = orderRepository
        self.productRepository = productRepository
    }
    
    func execute(items: [(productId: UUID, quantity: Int)], customerInfo: CustomerInfo) throws -> Order {
        var orderItems: [OrderItem] = []
        
        // Validate and create order items
        for item in items {
            guard let product = try productRepository.getById(item.productId) else {
                throw UseCaseError.productNotFound
            }
            
            let orderItem = try OrderItem(product: product, quantity: item.quantity)
            orderItems.append(orderItem)
            
            // Update product stock
            var updatedProduct = product
            try updatedProduct.updateStock(product.stockQuantity - item.quantity)
            try productRepository.update(updatedProduct)
        }
        
        // Create and save order
        let order = Order(
            id: UUID(),
            items: orderItems,
            status: .pending,
            customerInfo: customerInfo,
            createdAt: Date()
        )
        
        try orderRepository.save(order)
        return order
    }
}

enum UseCaseError: Error {
    case productNotFound
    case orderNotFound
}

// MARK: - Interface Adapters Layer

// DTO
struct OrderDTO {
    let id: String
    let items: [OrderItemDTO]
    let status: String
    let totalAmount: String
    let customerName: String
    let customerEmail: String
    
    init(from domain: Order) {
        self.id = domain.id.uuidString
        self.items = domain.items.map(OrderItemDTO.init)
        self.status = domain.status.rawValue
        self.totalAmount = domain.totalAmount.description
        self.customerName = domain.customerInfo.name
        self.customerEmail = domain.customerInfo.email
    }
}

struct OrderItemDTO {
    let productName: String
    let quantity: Int
    let price: String
    let subtotal: String
    
    init(from domain: OrderItem) {
        self.productName = domain.product.name
        self.quantity = domain.quantity
        self.price = domain.priceAtOrder.description
        self.subtotal = domain.subtotal.description
    }
}

// Controller
class OrderController {
    private let createOrderUseCase: CreateOrderUseCase
    
    init(createOrderUseCase: CreateOrderUseCase) {
        self.createOrderUseCase = createOrderUseCase
    }
    
    func createOrder(request: CreateOrderRequest) throws -> OrderDTO {
        let customerInfo = try CustomerInfo(
            name: request.customerName,
            email: request.customerEmail,
            address: Address(
                street: request.street,
                city: request.city,
                state: request.state,
                zipCode: request.zipCode,
                country: request.country
            )
        )
        
        let order = try createOrderUseCase.execute(
            items: request.items,
            customerInfo: customerInfo
        )
        
        return OrderDTO(from: order)
    }
}

// Request Model
struct CreateOrderRequest {
    let items: [(productId: UUID, quantity: Int)]
    let customerName: String
    let customerEmail: String
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
}

// MARK: - Frameworks & Drivers Layer

// Example of a concrete repository implementation
class SQLiteOrderRepository: OrderRepository {
    func save(_ order: Order) throws {
        // Implement SQLite persistence
    }
    
    func getById(_ id: UUID) throws -> Order? {
        // Implement SQLite retrieval
        return nil
    }
    
    func update(_ order: Order) throws {
        // Implement SQLite update
    }
}

// Note: This is a sample implementation. A complete solution would include:
// 1. Complete repository implementations
// 2. Proper error handling and logging
// 3. Transaction management
// 4. External service integrations
// 5. Comprehensive unit tests
// 6. API documentation
// 7. Dependency injection container
// 8. More use cases and controllers

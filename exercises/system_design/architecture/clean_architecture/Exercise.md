# Clean Architecture Exercise: E-Commerce Order Management System

## Objective
Create an order management system for an e-commerce platform using Clean Architecture principles. This exercise will help you understand how to properly separate concerns, implement business rules, and maintain independence from external frameworks.

## Requirements

### Domain Layer (Entities)

1. Core Entities:
   - `Product`
     - id: UUID
     - name: String
     - description: String
     - price: Decimal
     - stockQuantity: Int

   - `Order`
     - id: UUID
     - items: [OrderItem]
     - status: OrderStatus
     - totalAmount: Decimal
     - customerInfo: CustomerInfo
     - createdAt: Date

   - `CustomerInfo`
     - id: UUID
     - name: String
     - email: String
     - address: Address

2. Value Objects:
   - `OrderItem`
   - `Address`
   - `Money`

3. Enums:
   - `OrderStatus`
   - `PaymentStatus`

### Use Cases Layer

1. Order Management:
   - Create new order
   - Update order status
   - Cancel order
   - Calculate order total
   - Validate order

2. Product Management:
   - Add product
   - Update product
   - Check product availability
   - Update stock

3. Customer Management:
   - Register customer
   - Update customer information
   - Get customer order history

### Interface Adapters Layer

1. Controllers:
   - OrderController
   - ProductController
   - CustomerController

2. Presenters:
   - OrderPresenter
   - ProductPresenter
   - CustomerPresenter

3. Gateways:
   - OrderRepository
   - ProductRepository
   - CustomerRepository

### Frameworks & Drivers Layer

1. Database:
   - Implement persistence using any database
   - Create repository implementations

2. External Services:
   - Payment gateway integration
   - Email service
   - Shipping service

## Specific Requirements

1. Follow Clean Architecture Principles:
   - Dependency rule must be strictly followed
   - Inner layers should not know about outer layers
   - Use interfaces for dependency inversion

2. Implement Business Rules:
   - Order total calculation
   - Stock validation
   - Order status transitions
   - Customer validation

3. Error Handling:
   - Domain-specific exceptions
   - Use case level validation
   - Proper error propagation

4. Testing:
   - Unit tests for entities
   - Use case tests
   - Integration tests
   - Mock external dependencies

## Bonus Challenges
1. Implement event sourcing
2. Add CQRS pattern
3. Implement async operations
4. Add caching layer
5. Implement retry mechanisms

## Evaluation Criteria
- Clean Architecture principles adherence
- Proper separation of concerns
- Business rules implementation
- Error handling
- Test coverage
- Code organization
- Documentation

## Time Estimate
- Basic Implementation: 4-5 hours
- With Bonus Features: 8-10 hours

## Submission
Your solution should include:
1. Complete source code with proper layer separation
2. Unit and integration tests
3. Documentation explaining the architecture
4. Setup instructions
5. API documentation (if applicable)

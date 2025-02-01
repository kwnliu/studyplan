# Clean Architecture

## Overview
Clean Architecture is a software design philosophy that separates the elements of a design into ring levels. The main rule of clean architecture is that source code dependencies can only point inwards, toward higher-level policies.

## Core Principles

### The Dependency Rule
- Source code dependencies must point only inward, toward higher-level policies
- Nothing in an inner circle can know anything about something in an outer circle
- Data formats declared in an outer circle should not be used by an inner circle

### Layers (from innermost to outermost)

1. **Entities (Enterprise Business Rules)**
   - Encapsulate enterprise-wide business rules
   - Can be used by different applications in the enterprise
   - Least likely to change when something external changes

2. **Use Cases (Application Business Rules)**
   - Contains application-specific business rules
   - Orchestrates the flow of data to and from entities
   - Implements all use cases in the system

3. **Interface Adapters**
   - Converts data between use cases/entities and external agencies
   - Contains presenters, views, and controllers
   - Transforms data from the format most convenient for entities/use cases

4. **Frameworks & Drivers**
   - Contains frameworks and tools
   - Database, web framework, devices
   - Glue code that communicates with the internal layers

## Key Concepts

### Entities
- Business objects of the application
- Encapsulate the most general and high-level rules
- Least likely to change when something external changes

### Use Cases
- Contains application-specific business rules
- Orchestrates the flow of data to and from entities
- Implements all the use cases of the system

### Interface Adapters
- Converts data between the format most convenient for entities and use cases
- Includes presenters, views, and controllers
- Gateway implementations

### Frameworks
- Tools and frameworks
- Database, web framework
- External interfaces
- Device interfaces

## Benefits
1. Independent of Frameworks
2. Testable
3. Independent of UI
4. Independent of Database
5. Independent of any external agency

## Best Practices
1. Follow the Dependency Rule strictly
2. Use dependency injection
3. Create clear boundaries between layers
4. Keep the domain logic independent
5. Use interfaces for flexibility
6. Write comprehensive tests

## Common Use Cases
- Enterprise Applications
- Complex Domain Logic
- Long-term Maintainable Systems
- Microservices Architecture
- Systems requiring high testability

## Related Patterns
- Hexagonal Architecture (Ports and Adapters)
- Onion Architecture
- DDD (Domain-Driven Design)

## Additional Resources
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [The Clean Architecture (detailed guide)](https://www.freecodecamp.org/news/a-quick-introduction-to-clean-architecture-990c014448d2/)
- [Implementing Clean Architecture](https://www.youtube.com/watch?v=CnailTcJV_U)

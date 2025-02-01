# Swift Language Features Exercises

## Overview
This set of exercises focuses on advanced Swift features including protocols, generics, and closures. You'll implement various patterns and solve problems using these features.

## Exercise 1: Protocol and Protocol Extensions

### Problem
Create a caching system using protocols and protocol extensions.

### Task
1. Define a caching protocol
2. Implement default behavior using protocol extensions
3. Create concrete implementations

### Answer

```swift
protocol Cacheable {
    associatedtype Item
    var items: [String: Item] { get set }
    func cache(_ item: Item, forKey key: String)
    func retrieve(forKey key: String) -> Item?
}

extension Cacheable {
    mutating func cache(_ item: Item, forKey key: String) {
        items[key] = item
    }
    
    func retrieve(forKey key: String) -> Item? {
        return items[key]
    }
}

// Implementation example
class ImageCache: Cacheable {
    var items: [String: UIImage] = [:]
}

class DataCache: Cacheable {
    var items: [String: Data] = [:]
}
```

## Exercise 2: Generic Collection Processing

### Problem
Create a generic function that can process any collection type and transform its elements.

### Task
1. Implement a generic transform function
2. Add type constraints
3. Create example usage with different types

### Answer

```swift
extension Collection {
    func transformed<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        return try map(transform)
    }
    
    func filtered<T>(_ transform: (Element) throws -> T?) rethrows -> [T] {
        return try compactMap(transform)
    }
}

// Example usage
let numbers = [1, 2, 3, 4, 5]
let strings = numbers.transformed { String($0) }
let evenNumbers = numbers.filtered { $0 % 2 == 0 ? $0 : nil }

// More complex example
struct User {
    let id: Int
    let name: String
}

let users = [User(id: 1, name: "John"), User(id: 2, name: "Jane")]
let userNames = users.transformed { $0.name }
```

## Exercise 3: Advanced Closure Patterns

### Problem
Implement a command pattern using closures.

### Task
1. Create a command system using closures
2. Implement undo functionality
3. Add command composition

### Answer

```swift
class CommandSystem {
    typealias Command = () -> Void
    typealias UndoableCommand = (() -> Void, () -> Void)
    
    private var commands: [UndoableCommand] = []
    private var undoneCommands: [UndoableCommand] = []
    
    func execute(command: @escaping Command, undo: @escaping Command) {
        command()
        commands.append((command, undo))
        undoneCommands.removeAll()
    }
    
    func undo() {
        guard let last = commands.popLast() else { return }
        last.1()  // Execute undo
        undoneCommands.append(last)
    }
    
    func redo() {
        guard let last = undoneCommands.popLast() else { return }
        last.0()  // Execute command
        commands.append(last)
    }
}

// Example usage
let system = CommandSystem()

var text = "Hello"
system.execute(
    command: { text += " World" },
    undo: { text = String(text.dropLast(6)) }
)
print(text)  // "Hello World"

system.undo()
print(text)  // "Hello"

system.redo()
print(text)  // "Hello World"
```

## Exercise 4: Protocol Composition

### Problem
Create a system that uses protocol composition to define behavior.

### Task
1. Define multiple protocols
2. Create a type that composes these protocols
3. Implement required functionality

### Answer

```swift
protocol Identifiable {
    var id: String { get }
}

protocol Nameable {
    var name: String { get set }
}

protocol Validatable {
    func validate() -> Bool
}

class User: Identifiable & Nameable & Validatable {
    let id: String
    var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    func validate() -> Bool {
        return !name.isEmpty && id.count >= 3
    }
}

// Extension to add functionality to types conforming to both protocols
extension Identifiable where Self: Nameable {
    func displayString() -> String {
        return "\(id): \(name)"
    }
}
```

## Testing Your Knowledge

1. What are the benefits of protocol-oriented programming?
2. How do generics improve code reusability?
3. When would you use associated types vs generic constraints?
4. What are the different closure capture semantics?
5. How do you handle type erasure with protocols?

## Additional Resources
- [Swift Language Guide - Protocols](https://docs.swift.org/swift-book/LanguageGuide/Protocols.html)
- [Swift Language Guide - Generics](https://docs.swift.org/swift-book/LanguageGuide/Generics.html)
- [WWDC Session: Protocol and Value Oriented Programming](https://developer.apple.com/videos/play/wwdc2016/419/) 
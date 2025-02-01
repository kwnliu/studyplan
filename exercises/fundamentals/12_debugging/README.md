# iOS Debugging

## Overview
Debugging is a critical skill in iOS development. This section covers fundamental debugging concepts, tools, and techniques for identifying and resolving issues in iOS applications effectively.

## Key Concepts

### 1. Xcode Debugger
- Breakpoints
- Variables inspection
- Stack trace analysis
- Memory inspection
- Thread debugging

### 2. Logging and Monitoring
- Console logging
- OSLog framework
- Crash reporting
- Performance metrics
- System monitoring

### 3. Memory Debugging
- Memory leaks
- Retain cycles
- Allocations
- Memory graph
- Heap analysis

### 4. Runtime Debugging
- Exception handling
- Symbolic breakpoints
- Condition breakpoints
- Runtime issues
- Dynamic analysis

### 5. Network Debugging
- Request monitoring
- Response analysis
- Traffic inspection
- SSL/TLS debugging
- Network conditions

## Best Practices

1. **Systematic Debugging**
   - Reproduce consistently
   - Isolate the problem
   - Verify assumptions
   - Test hypotheses
   - Document findings

2. **Logging Strategy**
   - Structured logging
   - Log levels
   - Context capture
   - Performance impact
   - Privacy concerns

3. **Memory Management**
   - Track allocations
   - Monitor leaks
   - Profile memory usage
   - Handle warnings
   - Implement cleanup

4. **Error Handling**
   - Proper error types
   - Error propagation
   - Recovery strategies
   - User feedback
   - Logging

## Common Use Cases

1. **Debug Logging**
   ```swift
   class DebugLogger {
       enum Level: String {
           case debug, info, warning, error
       }
       
       static func log(_ message: String,
                      level: Level = .debug,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
           #if DEBUG
           let filename = (file as NSString).lastPathComponent
           let prefix = "[\(level.rawValue.uppercased())][\(filename):\(line)]"
           print("\(prefix) \(message)")
           #endif
       }
   }
   ```

2. **Memory Leak Detection**
   ```swift
   class MemoryTracker {
       static func trackObject(_ object: AnyObject,
                             identifier: String) {
           // Create weak reference
           weak var weakRef = object
           
           // Check after delay
           DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
               if weakRef != nil {
                   print("Potential memory leak: \(identifier)")
               }
           }
       }
   }
   ```

3. **Network Debugging**
   ```swift
   class NetworkDebugger {
       static func logRequest(_ request: URLRequest) {
           print("--- Request ---")
           print("URL: \(request.url?.absoluteString ?? "nil")")
           print("Method: \(request.httpMethod ?? "GET")")
           print("Headers: \(request.allHTTPHeaderFields ?? [:])")
           if let body = request.httpBody,
              let str = String(data: body, encoding: .utf8) {
               print("Body: \(str)")
           }
       }
       
       static func logResponse(_ response: URLResponse?,
                             data: Data?,
                             error: Error?) {
           print("--- Response ---")
           if let httpResponse = response as? HTTPURLResponse {
               print("Status: \(httpResponse.statusCode)")
           }
           if let error = error {
               print("Error: \(error)")
           }
           if let data = data,
              let str = String(data: data, encoding: .utf8) {
               print("Data: \(str)")
           }
       }
   }
   ```

## Debug Tools
- Xcode Debugger
- Instruments
- Console
- Network Link Conditioner
- Memory Graph Debugger

## Common Pitfalls
1. Insufficient logging
2. Missing error handling
3. Ignoring memory warnings
4. Poor crash reporting
5. Incomplete debugging info

## Additional Resources
- [Debugging with Xcode](https://developer.apple.com/documentation/xcode/debugging-with-xcode)
- [Instruments Help](https://developer.apple.com/documentation/instruments)
- [Console Help](https://developer.apple.com/documentation/os/logging)
- [Memory Debugging](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early) 
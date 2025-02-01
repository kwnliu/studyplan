import Foundation
import UIKit

// MARK: - Exercise 1: Crash Investigation

class CrashDebugger {
    // Debug logging system
    static func log(_ message: String,
                   file: String = #file,
                   function: String = #function,
                   line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("[\(filename):\(line)] \(function): \(message)")
        #endif
    }
    
    // Safe array access
    static func safeArrayAccess<T>(_ array: [T], index: Int) -> T? {
        guard index >= 0, index < array.count else {
            log("Array index out of bounds: \(index), count: \(array.count)")
            return nil
        }
        return array[index]
    }
    
    // Optional unwrapping with logging
    static func unwrap<T>(_ optional: T?,
                         default defaultValue: T,
                         context: String) -> T {
        guard let value = optional else {
            log("Nil value unwrapped in context: \(context)")
            return defaultValue
        }
        return value
    }
}

// MARK: - Exercise 2: Performance Debugging

class PerformanceDebugger {
    static let shared = PerformanceDebugger()
    private var measurements: [String: CFTimeInterval] = [:]
    
    // Measure execution time
    func measure(_ block: () -> Void, name: String) {
        let start = CACurrentMediaTime()
        block()
        let end = CACurrentMediaTime()
        let duration = end - start
        
        measurements[name] = duration
        CrashDebugger.log("Measurement '\(name)': \(duration)s")
    }
    
    // Track memory usage
    func trackMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }
}

// MARK: - Exercise 3: Network Debugging

class NetworkDebugger {
    static let shared = NetworkDebugger()
    private var requests: [URLRequest] = []
    
    // Log network request
    func logRequest(_ request: URLRequest) {
        requests.append(request)
        
        var log = "🌐 Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")\n"
        log += "Headers: \(request.allHTTPHeaderFields ?? [:])\n"
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            log += "Body: \(bodyString)\n"
        }
        
        CrashDebugger.log(log)
    }
    
    // Log network response
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        var log = "📥 Response:\n"
        
        if let httpResponse = response as? HTTPURLResponse {
            log += "Status: \(httpResponse.statusCode)\n"
            log += "Headers: \(httpResponse.allHeaderFields)\n"
        }
        
        if let error = error {
            log += "Error: \(error)\n"
        }
        
        if let data = data,
           let bodyString = String(data: data, encoding: .utf8) {
            log += "Body: \(bodyString)\n"
        }
        
        CrashDebugger.log(log)
    }
}

// MARK: - Exercise 4: UI Debugging

class UIDebugger {
    // Debug view hierarchy
    static func debugViewHierarchy(_ view: UIView, level: Int = 0) {
        let indent = String(repeating: "  ", count: level)
        let frame = view.frame
        let className = String(describing: type(of: view))
        
        CrashDebugger.log("\(indent)[\(className)] frame: \(frame)")
        
        for constraint in view.constraints {
            CrashDebugger.log("\(indent)  constraint: \(constraint)")
        }
        
        for subview in view.subviews {
            debugViewHierarchy(subview, level: level + 1)
        }
    }
    
    // Track layout cycles
    static func trackLayoutCycle(_ view: UIView) {
        var layoutCount = 0
        
        let originalLayoutSubviews = view.layoutSubviews
        view.layoutSubviews = {
            layoutCount += 1
            if layoutCount > 100 {
                CrashDebugger.log("⚠️ Possible layout cycle detected: \(layoutCount) layouts")
            }
            originalLayoutSubviews()
        }
    }
}

// MARK: - Exercise 5: State Debugging

class StateDebugger {
    static let shared = StateDebugger()
    private var stateHistory: [(state: Any, timestamp: Date)] = []
    
    // Track state changes
    func trackState<T>(_ state: T, context: String) {
        stateHistory.append((state, Date()))
        
        let stateDescription = String(describing: state)
        CrashDebugger.log("State changed in \(context): \(stateDescription)")
    }
    
    // Analyze state transitions
    func analyzeTransitions() {
        guard stateHistory.count >= 2 else { return }
        
        for i in 1..<stateHistory.count {
            let previous = stateHistory[i-1]
            let current = stateHistory[i]
            
            let timeInterval = current.timestamp.timeIntervalSince(previous.timestamp)
            CrashDebugger.log("State transition took \(timeInterval)s")
            CrashDebugger.log("From: \(previous.state)")
            CrashDebugger.log("To: \(current.state)")
        }
    }
}

// Note: This is a sample implementation. A complete solution would include:
// 1. More comprehensive crash reporting
// 2. Advanced memory tracking
// 3. Network request/response mocking
// 4. UI testing helpers
// 5. State validation
// 6. Thread safety checks
// 7. Error recovery mechanisms
// 8. Performance optimization tools 
import Foundation
import Network

// MARK: - Exercise 1: Basic Networking

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case invalidData
    case decodingError(Error)
    case serverError(Int)
    case timeout
}

class NetworkClient {
    static let shared = NetworkClient()
    private let session: URLSession
    private let timeout: TimeInterval = 30
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        session = URLSession(configuration: config)
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add headers
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Add parameters
        if let parameters = parameters {
            switch method {
            case .get:
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                components?.queryItems = parameters.map {
                    URLQueryItem(name: $0.key, value: "\($0.value)")
                }
                request.url = components?.url
            case .post, .put:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
            default:
                break
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(T.self, from: data)
            case 400...499:
                throw NetworkError.serverError(httpResponse.statusCode)
            case 500...599:
                throw NetworkError.serverError(httpResponse.statusCode)
            default:
                throw NetworkError.invalidResponse
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
}

// MARK: - Exercise 2: Authentication

enum AuthError: Error {
    case invalidCredentials
    case tokenExpired
    case refreshFailed
    case invalidToken
    case unauthorized
}

class AuthenticationManager {
    static let shared = AuthenticationManager()
    private let keychain = KeychainWrapper()
    
    private var accessToken: String?
    private var refreshToken: String?
    
    func authenticate(username: String, password: String) async throws {
        // Simulate OAuth request
        let parameters = [
            "grant_type": "password",
            "username": username,
            "password": password
        ]
        
        let tokens: TokenResponse = try await NetworkClient.shared.request(
            endpoint: "https://api.example.com/oauth/token",
            method: .post,
            parameters: parameters
        )
        
        // Store tokens
        try keychain.store(key: "accessToken", value: tokens.accessToken)
        try keychain.store(key: "refreshToken", value: tokens.refreshToken)
        
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
    }
    
    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw AuthError.unauthorized
        }
        
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        let tokens: TokenResponse = try await NetworkClient.shared.request(
            endpoint: "https://api.example.com/oauth/token",
            method: .post,
            parameters: parameters
        )
        
        // Update tokens
        try keychain.store(key: "accessToken", value: tokens.accessToken)
        try keychain.store(key: "refreshToken", value: tokens.refreshToken)
        
        accessToken = tokens.accessToken
        self.refreshToken = tokens.refreshToken
    }
    
    func getAccessToken() throws -> String {
        guard let token = accessToken else {
            throw AuthError.unauthorized
        }
        return token
    }
}

// MARK: - Exercise 3: Image Download and Caching

class ImageLoader {
    static let shared = ImageLoader()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    
    init() {
        let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cacheURL.appendingPathComponent("ImageCache")
        
        try? fileManager.createDirectory(at: diskCacheURL,
                                       withIntermediateDirectories: true)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    func loadImage(from url: URL) async throws -> UIImage {
        // Check memory cache
        let key = url.absoluteString as NSString
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }
        
        // Check disk cache
        let diskURL = diskCacheURL.appendingPathComponent(key.hash.description)
        if let data = try? Data(contentsOf: diskURL),
           let image = UIImage(data: data) {
            cache.setObject(image, forKey: key)
            return image
        }
        
        // Download image
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw NetworkError.invalidData
        }
        
        // Save to caches
        cache.setObject(image, forKey: key)
        try? data.write(to: diskURL)
        
        return image
    }
    
    @objc private func clearMemoryCache() {
        cache.removeAllObjects()
    }
    
    func clearDiskCache() throws {
        let contents = try fileManager.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: nil
        )
        
        try contents.forEach { url in
            try fileManager.removeItem(at: url)
        }
    }
}

// MARK: - Exercise 4: Network Reachability

enum NetworkStatus {
    case available
    case unavailable
}

class ReachabilityManager {
    static let shared = ReachabilityManager()
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var status: NetworkStatus = .unavailable
    private var observers: [UUID: (NetworkStatus) -> Void] = [:]
    
    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let newStatus: NetworkStatus = path.status == .satisfied ? .available : .unavailable
            self?.updateStatus(newStatus)
        }
        monitor.start(queue: queue)
    }
    
    func addObserver(_ observer: @escaping (NetworkStatus) -> Void) -> UUID {
        let id = UUID()
        observers[id] = observer
        return id
    }
    
    func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }
    
    private func updateStatus(_ newStatus: NetworkStatus) {
        status = newStatus
        observers.values.forEach { $0(newStatus) }
    }
}

// MARK: - Exercise 5: Advanced Networking

class AdvancedNetworkClient {
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    private var rateLimiter: RateLimiter
    
    init() {
        rateLimiter = RateLimiter(requestsPerSecond: 10)
    }
    
    func executeWithRetry<T: Decodable>(
        request: () async throws -> T,
        retries: Int = 0
    ) async throws -> T {
        do {
            return try await request()
        } catch {
            if retries < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                return try await executeWithRetry(request: request, retries: retries + 1)
            }
            throw error
        }
    }
    
    func executeChain<T>(_ operations: [() async throws -> T]) async throws -> [T] {
        var results: [T] = []
        
        for operation in operations {
            let result = try await operation()
            results.append(result)
        }
        
        return results
    }
    
    func executeConcurrent<T>(_ operations: [() async throws -> T]) async throws -> [T] {
        try await withThrowingTaskGroup(of: T.self) { group in
            for operation in operations {
                group.addTask {
                    try await self.rateLimiter.execute {
                        try await operation()
                    }
                }
            }
            
            var results: [T] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}

// MARK: - Support Classes

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

class KeychainWrapper {
    func store(key: String, value: String) throws {
        // Implement secure storage
    }
    
    func retrieve(key: String) throws -> String {
        // Implement secure retrieval
        return ""
    }
    
    func delete(key: String) throws {
        // Implement secure deletion
    }
}

class RateLimiter {
    private let requestsPerSecond: Int
    private let queue = DispatchQueue(label: "RateLimiter")
    private var timestamps: [Date] = []
    
    init(requestsPerSecond: Int) {
        self.requestsPerSecond = requestsPerSecond
    }
    
    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NetworkError.requestFailed(NSError()))
                    return
                }
                
                let now = Date()
                self.timestamps = self.timestamps.filter { now.timeIntervalSince($0) < 1 }
                
                if self.timestamps.count >= self.requestsPerSecond {
                    let oldestTimestamp = self.timestamps[0]
                    let delay = 1.0 - now.timeIntervalSince(oldestTimestamp)
                    if delay > 0 {
                        Thread.sleep(forTimeInterval: delay)
                    }
                }
                
                self.timestamps.append(now)
                
                Task {
                    do {
                        let result = try await operation()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
} 
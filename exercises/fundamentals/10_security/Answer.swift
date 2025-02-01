import Foundation
import Security
import LocalAuthentication
import CryptoKit

// MARK: - Exercise 1: Secure Data Storage

class EncryptionService {
    enum EncryptionError: Error {
        case keyGenerationFailed
        case encryptionFailed
        case decryptionFailed
        case invalidKey
    }
    
    private let keychain = KeychainWrapper()
    
    func generateKey() throws -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        try keychain.store(key: "encryptionKey", value: keyData)
        return key
    }
    
    func encrypt(_ data: Data) throws -> Data {
        guard let keyData = try? keychain.retrieve(key: "encryptionKey"),
              let key = try? SymmetricKey(data: keyData) else {
            throw EncryptionError.invalidKey
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined ?? Data()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        guard let keyData = try? keychain.retrieve(key: "encryptionKey"),
              let key = try? SymmetricKey(data: keyData) else {
            throw EncryptionError.invalidKey
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func secureDelete() throws {
        try keychain.delete(key: "encryptionKey")
    }
}

class KeychainWrapper {
    enum KeychainError: Error {
        case duplicateEntry
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }
    
    func store(key: String, value: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicateEntry
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func retrieve(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.unexpectedPasswordData
        }
        
        return data
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

// MARK: - Exercise 2: Certificate Pinning

class CertificatePinningManager: NSObject, URLSessionDelegate {
    private let pinnedCertificates: [Data]
    private let revokedCertificates: [Data]
    
    init(certificates: [Data], revokedCertificates: [Data] = []) {
        self.pinnedCertificates = certificates
        self.revokedCertificates = revokedCertificates
        super.init()
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverCertificateData = SecCertificateCopyData(certificate) as Data
        
        // Check if certificate is revoked
        guard !revokedCertificates.contains(serverCertificateData) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Verify against pinned certificates
        if pinnedCertificates.contains(serverCertificateData) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Exercise 3: Biometric Authentication

class BiometricAuthService {
    enum BiometricError: Error {
        case notAvailable
        case notEnrolled
        case lockout
        case canceled
        case failed
    }
    
    private let context = LAContext()
    private let policy: LAPolicy
    private let reason: String
    private let fallbackTitle: String?
    
    init(policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics,
         reason: String = "Authenticate to access secure data",
         fallbackTitle: String? = "Use Passcode") {
        self.policy = policy
        self.reason = reason
        self.fallbackTitle = fallbackTitle
    }
    
    func canAuthenticate() throws {
        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            switch error?.code {
            case LAError.biometryNotAvailable.rawValue:
                throw BiometricError.notAvailable
            case LAError.biometryNotEnrolled.rawValue:
                throw BiometricError.notEnrolled
            case LAError.biometryLockout.rawValue:
                throw BiometricError.lockout
            default:
                throw BiometricError.failed
            }
        }
    }
    
    func authenticate() async throws -> Bool {
        try canAuthenticate()
        
        if let fallbackTitle = fallbackTitle {
            context.localizedFallbackTitle = fallbackTitle
        }
        
        do {
            return try await context.evaluatePolicy(policy,
                                                  localizedReason: reason)
        } catch let error as LAError {
            switch error.code {
            case .userCancel:
                throw BiometricError.canceled
            case .biometryLockout:
                throw BiometricError.lockout
            default:
                throw BiometricError.failed
            }
        }
    }
}

// MARK: - Exercise 4: Secure Networking

class SecureNetworkClient {
    private let session: URLSession
    private let authManager: AuthenticationManager
    
    init(certificatePinning: CertificatePinningManager, authManager: AuthenticationManager) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "X-Security-Version": "1.0",
            "X-Device-ID": UIDevice.current.identifierForVendor?.uuidString ?? ""
        ]
        
        self.session = URLSession(configuration: configuration,
                                delegate: certificatePinning,
                                delegateQueue: nil)
        self.authManager = authManager
    }
    
    func secureRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        var signedRequest = request
        
        // Add authentication
        if let token = try? authManager.getAccessToken() {
            signedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add request signing
        let signature = try signRequest(request)
        signedRequest.setValue(signature, forHTTPHeaderField: "X-Request-Signature")
        
        // Make request
        let (data, response) = try await session.data(for: signedRequest)
        
        // Verify response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func signRequest(_ request: URLRequest) throws -> String {
        // Implement request signing
        return ""
    }
}

// MARK: - Exercise 5: App Security

class SecurityManager {
    static let shared = SecurityManager()
    
    func performSecurityChecks() throws {
        try checkJailbreak()
        try checkDebugger()
        try checkSignature()
        try checkTampering()
    }
    
    private func checkJailbreak() throws {
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                throw SecurityError.jailbreakDetected
            }
        }
    }
    
    private func checkDebugger() throws {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        
        let status = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        if status == 0 && (info.kp_proc.p_flag & P_TRACED) != 0 {
            throw SecurityError.debuggerDetected
        }
    }
    
    private func checkSignature() throws {
        // Implement signature validation
    }
    
    private func checkTampering() throws {
        // Implement tampering checks
    }
}

// MARK: - Support Types

enum SecurityError: Error {
    case jailbreakDetected
    case debuggerDetected
    case signatureInvalid
    case tamperingDetected
}

enum NetworkError: Error {
    case invalidResponse
    case requestFailed
    case unauthorized
} 
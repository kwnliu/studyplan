# Code Signing and Provisioning Exercises

## Overview
This set of exercises focuses on understanding and implementing code signing, provisioning profiles, and handling common code signing issues in iOS development.

## Exercise 1: Certificate Management

### Problem
Set up and manage development and distribution certificates for iOS app development.

### Task
1. Create development and distribution certificates
2. Manage certificate expiration
3. Handle certificate revocation
4. Share certificates with team members

### Answer

```bash
# 1. Generate Certificate Signing Request (CSR)
# Using Keychain Access:
# 1. Open Keychain Access
# 2. Choose Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority
# 3. Fill in your email and name
# 4. Choose "Saved to disk" and "Let me specify key pair information"
# 5. Set Key Size: 2048 bits
# 6. Algorithm: RSA
# 7. Save the CSR file

# 2. Create Development Certificate
# In Apple Developer Portal:
# 1. Certificates, Identifiers & Profiles > Certificates
# 2. Click [+] to add new certificate
# 3. Select iOS App Development
# 4. Upload CSR file
# 5. Download and install the certificate

# 3. Create Distribution Certificate
# Similar steps but select "App Store and Ad Hoc" instead of "iOS App Development"

# 4. Export Certificate and Private Key
security export -k ~/Library/Keychains/login.keychain-db \
    -t certs \
    -f pkcs12 \
    -P "your_password" \
    -o ios_development.p12

# 5. Import Certificate on Another Machine
security import ios_development.p12 \
    -k ~/Library/Keychains/login.keychain-db \
    -P "your_password" \
    -T /usr/bin/codesign

# 6. List Installed Certificates
security find-identity -v -p codesigning

# 7. Check Certificate Expiration
security find-certificate -c "Certificate Name" -p | \
    openssl x509 -noout -enddate

# 8. Revoke Certificate (if compromised)
# In Apple Developer Portal:
# 1. Certificates, Identifiers & Profiles > Certificates
# 2. Select the certificate
# 3. Click "Revoke"

# 9. Clean Up Expired Certificates
security delete-certificate -c "Certificate Name"
```

## Exercise 2: Provisioning Profile Management

### Problem
Create and manage provisioning profiles for different deployment scenarios.

### Task
1. Create development provisioning profile
2. Create distribution provisioning profile
3. Handle device management
4. Update and maintain profiles

### Answer

```bash
# 1. Register Test Devices
# Using Terminal to get UDID:
system_profiler SPUSBDataType | grep "Serial Number"

# Or programmatically:
```swift
import UIKit

extension UIDevice {
    static func getUDID() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    static func getDeviceInfo() -> [String: String] {
        return [
            "name": UIDevice.current.name,
            "model": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "udid": getUDID()
        ]
    }
}
```

```bash
# 2. Create App ID
# In Apple Developer Portal:
# 1. Certificates, Identifiers & Profiles > Identifiers
# 2. Click [+] to add new identifier
# 3. Choose "App IDs"
# 4. Configure capabilities

# 3. Create Development Provisioning Profile
# In Apple Developer Portal:
# 1. Certificates, Identifiers & Profiles > Provisioning Profiles
# 2. Click [+] to add new profile
# 3. Select iOS App Development
# 4. Select App ID
# 5. Select development certificates
# 6. Select devices
# 7. Name and generate profile

# 4. Create Distribution Provisioning Profile
# Similar steps but select "App Store" or "Ad Hoc" distribution

# 5. Install Provisioning Profile
open /path/to/profile.mobileprovision

# 6. List Installed Profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# 7. Check Profile Details
security cms -D -i /path/to/profile.mobileprovision

# 8. Automate Profile Management
```swift
class ProvisioningProfileManager {
    static let shared = ProvisioningProfileManager()
    
    func installProfile(at url: URL) throws {
        let profileData = try Data(contentsOf: url)
        
        // Save to Provisioning Profiles directory
        let profilesPath = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("MobileDevice/Provisioning Profiles")
        
        // Generate unique name
        let profileName = UUID().uuidString + ".mobileprovision"
        let destinationURL = profilesPath.appendingPathComponent(profileName)
        
        try profileData.write(to: destinationURL)
    }
    
    func listInstalledProfiles() throws -> [URL] {
        let profilesPath = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("MobileDevice/Provisioning Profiles")
        
        let files = try FileManager.default.contentsOfDirectory(
            at: profilesPath,
            includingPropertiesForKeys: nil
        )
        
        return files.filter { $0.pathExtension == "mobileprovision" }
    }
    
    func extractProfileInfo(from url: URL) throws -> [String: Any] {
        let profileData = try Data(contentsOf: url)
        
        // Use security cms to decode
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        task.arguments = ["cms", "-D", "-i", url.path]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw NSError(domain: "ProfileError", code: -1, userInfo: nil)
        }
        
        return plist
    }
}
```

## Exercise 3: Troubleshooting Code Signing

### Problem
Identify and resolve common code signing issues.

### Task
1. Diagnose signing issues
2. Fix provisioning profile mismatches
3. Handle expired certificates
4. Resolve team membership issues

### Answer

```swift
class CodeSigningValidator {
    enum SigningError: Error {
        case certificateNotFound
        case certificateExpired
        case profileNotFound
        case profileExpired
        case teamMembershipInvalid
        case entitlementsInvalid
    }
    
    static func validateCodeSigning() throws {
        try validateCertificates()
        try validateProfiles()
        try validateEntitlements()
    }
    
    static func validateCertificates() throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        task.arguments = ["find-identity", "-v", "-p", "codesigning"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        guard output.contains("iPhone Developer") || output.contains("Apple Development") else {
            throw SigningError.certificateNotFound
        }
    }
    
    static func validateProfiles() throws {
        let profilesPath = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("MobileDevice/Provisioning Profiles")
        
        let files = try FileManager.default.contentsOfDirectory(
            at: profilesPath,
            includingPropertiesForKeys: nil
        )
        
        guard !files.isEmpty else {
            throw SigningError.profileNotFound
        }
        
        // Check profile expiration
        for file in files {
            if let profile = try? ProvisioningProfileManager.shared.extractProfileInfo(from: file),
               let expirationDate = profile["ExpirationDate"] as? Date,
               expirationDate < Date() {
                throw SigningError.profileExpired
            }
        }
    }
    
    static func validateEntitlements() throws {
        // Read entitlements from project
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = ["-d", "--entitlements", ":-", "path/to/app"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw SigningError.entitlementsInvalid
        }
        
        // Validate specific entitlements
        // Example: Push Notifications
        if let pushEnabled = plist["aps-environment"] as? String,
           pushEnabled == "development" {
            // Validate push notification setup
        }
    }
}

// Usage Example
class CodeSigningDebugger {
    static func diagnoseIssues() {
        do {
            try CodeSigningValidator.validateCodeSigning()
            print("Code signing validation passed")
        } catch CodeSigningValidator.SigningError.certificateNotFound {
            print("Error: No valid signing certificate found")
            print("Solution:")
            print("1. Open Xcode > Preferences > Accounts")
            print("2. Select your team")
            print("3. Click Manage Certificates")
            print("4. Click + to create a new certificate")
        } catch CodeSigningValidator.SigningError.certificateExpired {
            print("Error: Signing certificate has expired")
            print("Solution:")
            print("1. Revoke expired certificate in Developer Portal")
            print("2. Create new certificate")
            print("3. Download and install new certificate")
        } catch CodeSigningValidator.SigningError.profileNotFound {
            print("Error: No valid provisioning profile found")
            print("Solution:")
            print("1. Open Developer Portal")
            print("2. Create new provisioning profile")
            print("3. Download and install profile")
        } catch CodeSigningValidator.SigningError.profileExpired {
            print("Error: Provisioning profile has expired")
            print("Solution:")
            print("1. Open Developer Portal")
            print("2. Regenerate expired profile")
            print("3. Download and install new profile")
        } catch {
            print("Unknown error: \(error)")
        }
    }
    
    static func fixCommonIssues() {
        // 1. Reset signing
        let task1 = Process()
        task1.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        task1.arguments = ["-project", "Project.xcodeproj",
                         "-target", "Target",
                         "clean"]
        try? task1.run()
        
        // 2. Clear derived data
        let derivedDataPath = "~/Library/Developer/Xcode/DerivedData"
        try? FileManager.default.removeItem(atPath: derivedDataPath)
        
        // 3. Reset keychain access
        let task2 = Process()
        task2.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        task2.arguments = ["list-keychains", "-d", "user", "-s", "login.keychain"]
        try? task2.run()
    }
}
```

## Exercise 4: Automated Signing Process

### Problem
Implement automated code signing for CI/CD pipeline.

### Task
1. Set up fastlane match
2. Configure automated certificate management
3. Implement automated profile updates
4. Handle CI/CD integration

### Answer

```ruby
# Fastfile
default_platform(:ios)

platform :ios do
  desc "Sync certificates and profiles"
  lane :sync_signing do
    match(
      type: "development",
      readonly: is_ci,
      force_for_new_devices: true
    )
    
    match(
      type: "appstore",
      readonly: is_ci
    )
  end
  
  desc "Build and sign app"
  lane :build do
    sync_signing
    
    gym(
      scheme: "YourScheme",
      export_method: "app-store",
      include_bitcode: true,
      include_symbols: true
    )
  end
end
```

```yaml
# GitHub Actions workflow
name: iOS Build
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '2.7'
        
    - name: Install fastlane
      run: |
        gem install bundler
        bundle install
        
    - name: Set up code signing
      env:
        MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
        FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD: ${{ secrets.FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD }}
      run: |
        bundle exec fastlane sync_signing
        
    - name: Build app
      run: bundle exec fastlane build
```

## Testing Your Knowledge

1. What is the difference between development and distribution certificates?
2. How do provisioning profiles work internally?
3. What are the common causes of code signing issues?
4. How do you handle certificate expiration in a team environment?
5. What are the best practices for automated code signing?

## Additional Resources
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list)
- [Xcode Code Signing](https://help.apple.com/xcode/mac/current/#/dev3a05256b8)
- [Fastlane Match](https://docs.fastlane.tools/actions/match/) 
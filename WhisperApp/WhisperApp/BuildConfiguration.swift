import Foundation

/// Build configuration utilities for Whisper app
enum BuildConfiguration {
    
    /// Current build configuration
    static var current: Configuration {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
    
    /// Available build configurations
    enum Configuration {
        case debug
        case release
        
        var isDebug: Bool {
            return self == .debug
        }
        
        var isRelease: Bool {
            return self == .release
        }
    }
    
    /// Logging configuration based on build type
    static var loggingEnabled: Bool {
        return current.isDebug
    }
    
    /// Detailed error messages (only in debug)
    static var detailedErrors: Bool {
        return current.isDebug
    }
    
    /// Security validation level
    static var securityValidationLevel: SecurityLevel {
        return current.isDebug ? .strict : .production
    }
    
    enum SecurityLevel {
        case strict      // All validations enabled
        case production  // Only essential validations
    }
    
    /// App version information
    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Build number
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// Full version string
    static var fullVersion: String {
        return "\(version) (\(buildNumber))"
    }
    
    /// Bundle identifier
    static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.mehmetakifacar.Whisper"
    }
    
    /// Validate build configuration security
    static func validateSecurityConfiguration() throws {
        // Ensure no networking capabilities in release builds
        if current.isRelease {
            // This would be called during app initialization
            // to perform runtime security checks
            try validateNoNetworkingCapabilities()
        }
        
        // Validate cryptographic configuration
        try validateCryptographicSetup()
    }
    
    private static func validateNoNetworkingCapabilities() throws {
        // Runtime check for networking capabilities
        // This is a placeholder - actual implementation would check
        // for networking frameworks and capabilities
        
        #if canImport(Network)
        if current.isRelease {
            // In a real implementation, this might throw an error
            // if Network framework is available in release builds
            print("Warning: Network framework available in release build")
        }
        #endif
    }
    
    private static func validateCryptographicSetup() throws {
        // Validate that CryptoKit is available and properly configured
        guard #available(iOS 15.0, *) else {
            throw ConfigurationError.unsupportedPlatform
        }
        
        // Additional cryptographic validation could go here
    }
}

/// Configuration-related errors
enum ConfigurationError: Error, LocalizedError {
    case unsupportedPlatform
    case networkingDetected
    case invalidCryptographicSetup
    
    var errorDescription: String? {
        switch self {
        case .unsupportedPlatform:
            return "Unsupported platform version"
        case .networkingDetected:
            return "Networking capabilities detected in release build"
        case .invalidCryptographicSetup:
            return "Invalid cryptographic configuration"
        }
    }
}

/// Debug utilities (only available in debug builds)
#if DEBUG
enum DebugUtilities {
    
    /// Enable verbose logging
    static var verboseLogging = true
    
    /// Enable timing measurements
    static var timingMeasurements = true
    
    /// Enable memory usage tracking
    static var memoryTracking = true
    
    /// Log debug message
    static func log(_ message: String, category: String = "Debug") {
        if verboseLogging {
            print("[\(category)] \(message)")
        }
    }
    
    /// Measure execution time
    static func measureTime<T>(_ operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        if timingMeasurements {
            log("Operation completed in \(String(format: "%.4f", timeElapsed))s")
        }
        
        return (result, timeElapsed)
    }
    
    /// Track memory usage
    static func logMemoryUsage(_ label: String = "Memory") {
        if memoryTracking {
            let info = mach_task_basic_info()
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
                let memoryUsage = Double(info.resident_size) / 1024.0 / 1024.0
                log("\(label): \(String(format: "%.2f", memoryUsage)) MB", category: "Memory")
            }
        }
    }
}
#endif

/// Production utilities (only available in release builds)
#if !DEBUG
enum ProductionUtilities {
    
    /// Minimal error reporting
    static func reportError(_ error: Error, context: String = "") {
        // In production, only log essential error information
        // without exposing sensitive details
        print("Error in \(context): \(error.localizedDescription)")
    }
    
    /// Performance monitoring (lightweight)
    static func trackPerformance(_ operation: String, duration: TimeInterval) {
        // Lightweight performance tracking for production
        if duration > 1.0 { // Only track slow operations
            print("Performance: \(operation) took \(String(format: "%.2f", duration))s")
        }
    }
}
#endif
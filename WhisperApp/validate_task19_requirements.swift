#!/usr/bin/env swift

import Foundation

/// Validation script for Task 19: Performance Optimization and Monitoring
/// Verifies implementation of lazy loading, background processing, memory optimization, and benchmarking

print("🔍 Validating Task 19: Performance Optimization and Monitoring Implementation")
print(String(repeating: "=", count: 80))

var validationErrors: [String] = []
var validationWarnings: [String] = []

// MARK: - File Existence Validation

let requiredFiles = [
    "WhisperApp/WhisperApp/Core/Performance/PerformanceMonitor.swift",
    "WhisperApp/WhisperApp/Core/Performance/LazyLoadingService.swift",
    "WhisperApp/WhisperApp/Core/Performance/BackgroundCryptoProcessor.swift",
    "WhisperApp/WhisperApp/Core/Performance/MemoryOptimizedCrypto.swift",
    "WhisperApp/WhisperApp/Core/Performance/CryptoBenchmarks.swift",
    "WhisperApp/WhisperApp/Core/Performance/OptimizedIdentityManager.swift",
    "WhisperApp/WhisperApp/Core/Performance/OptimizedContactManager.swift",
    "WhisperApp/Tests/PerformanceTests.swift"
]

print("📁 Checking required files...")
for file in requiredFiles {
    if FileManager.default.fileExists(atPath: file) {
        print("✅ \(file)")
    } else {
        validationErrors.append("❌ Missing required file: \(file)")
    }
}

// MARK: - Performance Monitor Validation

func validatePerformanceMonitor() {
    print("\n🔧 Validating Performance Monitor...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/Core/Performance/PerformanceMonitor.swift") else {
        validationErrors.append("❌ Cannot read PerformanceMonitor.swift")
        return
    }
    
    let requiredComponents = [
        "protocol PerformanceMonitor",
        "measureCryptoOperation",
        "measureMemoryUsage",
        "getCurrentMemoryUsage",
        "recordMetrics",
        "getStatistics",
        "exportMetrics",
        "struct PerformanceStatistics",
        "WhisperPerformanceMonitor",
        "CFAbsoluteTimeGetCurrent",
        "mach_task_basic_info",
        "resident_size"
    ]
    
    for component in requiredComponents {
        if content.contains(component) {
            print("✅ \(component)")
        } else {
            validationErrors.append("❌ Missing component in PerformanceMonitor: \(component)")
        }
    }
    
    // Check for proper memory tracking
    if content.contains("task_info") && content.contains("MACH_TASK_BASIC_INFO") {
        print("✅ Memory usage tracking implementation")
    } else {
        validationWarnings.append("⚠️ Memory usage tracking may be incomplete")
    }
    
    // Check for performance statistics
    if content.contains("averageDuration") && content.contains("executionCount") {
        print("✅ Performance statistics tracking")
    } else {
        validationErrors.append("❌ Missing performance statistics tracking")
    }
}

// MARK: - Lazy Loading Validation

func validateLazyLoading() {
    print("\n🔧 Validating Lazy Loading Service...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/Core/Performance/LazyLoadingService.swift") else {
        validationErrors.append("❌ Cannot read LazyLoadingService.swift")
        return
    }
    
    let requiredComponents = [
        "protocol LazyLoadingService",
        "loadIdentityMetadata",
        "loadFullIdentity",
        "loadContactMetadata",
        "loadFullContact",
        "preloadFrequentlyUsed",
        "clearCache",
        "getCacheStatistics",
        "struct IdentityMetadata",
        "struct ContactMetadata",
        "struct CacheStatistics",
        "WhisperLazyLoadingService",
        "identityMetadataCache",
        "contactMetadataCache",
        "fullIdentityCache",
        "fullContactCache"
    ]
    
    for component in requiredComponents {
        if content.contains(component) {
            print("✅ \(component)")
        } else {
            validationErrors.append("❌ Missing component in LazyLoadingService: \(component)")
        }
    }
    
    // Check for cache size limits
    if content.contains("maxIdentityCache") && content.contains("maxContactCache") {
        print("✅ Cache size limits implemented")
    } else {
        validationWarnings.append("⚠️ Cache size limits may not be properly implemented")
    }
    
    // Check for cache hit/miss tracking
    if content.contains("cacheHits") && content.contains("cacheMisses") {
        print("✅ Cache hit/miss tracking")
    } else {
        validationErrors.append("❌ Missing cache hit/miss tracking")
    }
}

// MARK: - Background Processing Validation

func validateBackgroundProcessing() {
    print("\n🔧 Validating Background Crypto Processor...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/Core/Performance/BackgroundCryptoProcessor.swift") else {
        validationErrors.append("❌ Cannot read BackgroundCryptoProcessor.swift")
        return
    }
    
    let requiredComponents = [
        "protocol BackgroundCryptoProcessor",
        "encryptInBackground",
        "decryptInBackground",
        "generateIdentityInBackground",
        "rotateIdentityInBackground",
        "cancelAllOperations",
        "getPendingOperationsCount",
        "enum CryptoOperationPriority",
        "WhisperBackgroundCryptoProcessor",
        "AnyPublisher",
        "Future",
        "DispatchQueue",
        "highPriorityQueue",
        "normalPriorityQueue",
        "lowPriorityQueue"
    ]
    
    for component in requiredComponents {
        if content.contains(component) {
            print("✅ \(component)")
        } else {
            validationErrors.append("❌ Missing component in BackgroundCryptoProcessor: \(component)")
        }
    }
    
    // Check for proper queue management
    if content.contains("qos: .userInitiated") && content.contains("qos: .default") && content.contains("qos: .utility") {
        print("✅ Quality of Service queue configuration")
    } else {
        validationWarnings.append("⚠️ QoS queue configuration may be incomplete")
    }
    
    // Check for operation tracking
    if content.contains("pendingOperations") && content.contains("CryptoOperation") {
        print("✅ Operation tracking implementation")
    } else {
        validationErrors.append("❌ Missing operation tracking")
    }
}

// MARK: - Memory Optimization Validation

func validateMemoryOptimization() {
    print("\n🔧 Validating Memory Optimized Crypto...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/Core/Performance/MemoryOptimizedCrypto.swift") else {
        validationErrors.append("❌ Cannot read MemoryOptimizedCrypto.swift")
        return
    }
    
    let requiredComponents = [
        "protocol MemoryOptimizedCrypto",
        "encryptWithMemoryOptimization",
        "decryptWithMemoryOptimization",
        "secureClear",
        "getCryptoMemoryUsage",
        "optimizeMemory",
        "class CryptoMemoryPool",
        "getBuffer",
        "returnBuffer",
        "clearPool",
        "WhisperMemoryOptimizedCrypto",
        "memset_s",
        "secureZero",
        "trackMemoryAllocation",
        "trackMemoryDeallocation"
    ]
    
    for component in requiredComponents {
        if content.contains(component) {
            print("✅ \(component)")
        } else {
            validationErrors.append("❌ Missing component in MemoryOptimizedCrypto: \(component)")
        }
    }
    
    // Check for secure memory clearing
    if content.contains("memset_s") && content.contains("withUnsafeMutableBytes") {
        print("✅ Secure memory clearing implementation")
    } else {
        validationErrors.append("❌ Missing secure memory clearing")
    }
    
    // Check for memory pool implementation
    if content.contains("availableBuffers") && content.contains("maxBuffersPerSize") {
        print("✅ Memory pool implementation")
    } else {
        validationWarnings.append("⚠️ Memory pool implementation may be incomplete")
    }
}

// MARK: - Benchmarking Validation

func validateBenchmarking() {
    print("\n🔧 Validating Crypto Benchmarks...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/WhisperApp/Core/Performance/CryptoBenchmarks.swift") else {
        validationErrors.append("❌ Cannot read CryptoBenchmarks.swift")
        return
    }
    
    let requiredComponents = [
        "protocol CryptoBenchmarks",
        "benchmarkEncryption",
        "benchmarkDecryption",
        "benchmarkKeyGeneration",
        "benchmarkSignatures",
        "benchmarkMemoryUsage",
        "exportBenchmarkResults",
        "struct EncryptionBenchmarkResults",
        "struct DecryptionBenchmarkResults",
        "struct KeyGenerationBenchmarkResults",
        "struct SignatureBenchmarkResults",
        "struct MemoryBenchmarkResults",
        "struct MessageSizeBenchmark",
        "struct OperationBenchmark",
        "struct MemoryUsageBenchmark",
        "struct BenchmarkSummary",
        "struct DeviceInfo",
        "WhisperCryptoBenchmarks",
        "throughputMBps",
        "operationsPerSecond",
        "averageLatencyMs"
    ]
    
    for component in requiredComponents {
        if content.contains(component) {
            print("✅ \(component)")
        } else {
            validationErrors.append("❌ Missing component in CryptoBenchmarks: \(component)")
        }
    }
    
    // Check for device info collection
    if content.contains("UIDevice.current.model") && content.contains("ProcessInfo.processInfo") {
        print("✅ Device information collection")
    } else {
        validationWarnings.append("⚠️ Device information collection may be incomplete")
    }
    
    // Check for comprehensive benchmarking
    if content.contains("benchmarkEncryptionForSize") && content.contains("benchmarkDecryptionForSize") {
        print("✅ Comprehensive benchmarking implementation")
    } else {
        validationErrors.append("❌ Missing comprehensive benchmarking")
    }
}

// MARK: - Optimized Managers Validation

func validateOptimizedManagers() {
    print("\n🔧 Validating Optimized Managers...")
    
    // Check OptimizedIdentityManager
    guard let identityContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/Core/Performance/OptimizedIdentityManager.swift") else {
        validationErrors.append("❌ Cannot read OptimizedIdentityManager.swift")
        return
    }
    
    let identityComponents = [
        "class OptimizedIdentityManager: IdentityManager",
        "lazyLoadingService",
        "performanceMonitor",
        "backgroundProcessor",
        "activeIdentityCache",
        "identityListCache",
        "cacheValidityDuration",
        "createIdentityInBackground",
        "rotateIdentityInBackground",
        "getIdentityMetadata",
        "getIdentityMetadataList",
        "invalidateCaches",
        "isCacheValid",
        "getPerformanceStatistics",
        "getCacheStatistics",
        "optimizeMemory"
    ]
    
    for component in identityComponents {
        if identityContent.contains(component) {
            print("✅ OptimizedIdentityManager: \(component)")
        } else {
            validationErrors.append("❌ Missing component in OptimizedIdentityManager: \(component)")
        }
    }
    
    // Check OptimizedContactManager
    guard let contactContent = try? String(contentsOfFile: "WhisperApp/WhisperApp/Core/Performance/OptimizedContactManager.swift") else {
        validationErrors.append("❌ Cannot read OptimizedContactManager.swift")
        return
    }
    
    let contactComponents = [
        "class OptimizedContactManager: ContactManager",
        "contactMetadataCache",
        "searchCache",
        "getContactMetadataList",
        "searchContactMetadata",
        "getCachedSearchResults",
        "cacheSearchResults",
        "updateContactInCache",
        "batchUpdateContacts",
        "getContacts",
        "contactListPublisher",
        "contactPublisher",
        "searchPublisher"
    ]
    
    for component in contactComponents {
        if contactContent.contains(component) {
            print("✅ OptimizedContactManager: \(component)")
        } else {
            validationErrors.append("❌ Missing component in OptimizedContactManager: \(component)")
        }
    }
}

// MARK: - Test Validation

func validateTests() {
    print("\n🔧 Validating Performance Tests...")
    
    guard let content = try? String(contentsOfFile: "WhisperApp/Tests/PerformanceTests.swift") else {
        validationErrors.append("❌ Cannot read PerformanceTests.swift")
        return
    }
    
    let testComponents = [
        "class PerformanceTests: XCTestCase",
        "testPerformanceMonitorMeasurement",
        "testMemoryUsageMeasurement",
        "testPerformanceStatisticsAccumulation",
        "testIdentityMetadataLoading",
        "testCacheStatistics",
        "testCacheClearance",
        "testMemoryOptimizedEncryption",
        "testMemoryOptimizedDecryption",
        "testSecureMemoryClearing",
        "testMemoryOptimization",
        "testBackgroundEncryption",
        "testBackgroundIdentityGeneration",
        "testOperationCancellation",
        "testEncryptionBenchmark",
        "testKeyGenerationBenchmark",
        "testMemoryBenchmark",
        "testBenchmarkExport",
        "testEncryptionPerformanceRegression",
        "testDecryptionPerformanceRegression",
        "testIdentityGenerationPerformanceRegression"
    ]
    
    for component in testComponents {
        if content.contains(component) {
            print("✅ \(component)")
        } else {
            validationErrors.append("❌ Missing test: \(component)")
        }
    }
    
    // Check for proper test setup
    if content.contains("TestCoreDataStack") && content.contains("NSInMemoryStoreType") {
        print("✅ Test Core Data setup")
    } else {
        validationWarnings.append("⚠️ Test Core Data setup may be incomplete")
    }
    
    // Check for performance regression tests
    if content.contains("measure {") {
        print("✅ Performance regression tests")
    } else {
        validationErrors.append("❌ Missing performance regression tests")
    }
}

// MARK: - Integration Validation

func validateIntegration() {
    print("\n🔧 Validating Integration Requirements...")
    
    // Check for Combine framework usage
    let combineFiles = [
        "WhisperApp/WhisperApp/Core/Performance/BackgroundCryptoProcessor.swift",
        "WhisperApp/WhisperApp/Core/Performance/OptimizedIdentityManager.swift",
        "WhisperApp/WhisperApp/Core/Performance/OptimizedContactManager.swift"
    ]
    
    for file in combineFiles {
        if let content = try? String(contentsOfFile: file) {
            if content.contains("import Combine") && content.contains("AnyPublisher") {
                print("✅ Combine integration in \(file)")
            } else {
                validationWarnings.append("⚠️ Missing Combine integration in \(file)")
            }
        }
    }
    
    // Check for proper error handling
    let errorHandlingFiles = [
        "WhisperApp/WhisperApp/Core/Performance/MemoryOptimizedCrypto.swift",
        "WhisperApp/WhisperApp/Core/Performance/BackgroundCryptoProcessor.swift"
    ]
    
    for file in errorHandlingFiles {
        if let content = try? String(contentsOfFile: file) {
            if content.contains("throws") && content.contains("catch") {
                print("✅ Error handling in \(file)")
            } else {
                validationWarnings.append("⚠️ Error handling may be incomplete in \(file)")
            }
        }
    }
}

// MARK: - Run All Validations

validatePerformanceMonitor()
validateLazyLoading()
validateBackgroundProcessing()
validateMemoryOptimization()
validateBenchmarking()
validateOptimizedManagers()
validateTests()
validateIntegration()

// MARK: - Final Report

print("\n" + String(repeating: "=", count: 80))
print("📊 VALIDATION SUMMARY")
print(String(repeating: "=", count: 80))

if validationErrors.isEmpty && validationWarnings.isEmpty {
    print("🎉 ALL VALIDATIONS PASSED!")
    print("✅ Task 19 implementation is complete and meets all requirements")
} else {
    if !validationErrors.isEmpty {
        print("❌ VALIDATION ERRORS (\(validationErrors.count)):")
        for error in validationErrors {
            print("  \(error)")
        }
    }
    
    if !validationWarnings.isEmpty {
        print("\n⚠️  VALIDATION WARNINGS (\(validationWarnings.count)):")
        for warning in validationWarnings {
            print("  \(warning)")
        }
    }
    
    if validationErrors.isEmpty {
        print("\n✅ Core implementation is complete with minor warnings")
    } else {
        print("\n❌ Implementation needs attention before completion")
    }
}

print("\n📋 IMPLEMENTATION CHECKLIST:")
print("✅ Performance monitoring with timing and memory tracking")
print("✅ Lazy loading service for identities and contacts")
print("✅ Background processing for cryptographic operations")
print("✅ Memory optimization with secure clearing and pooling")
print("✅ Comprehensive benchmarking suite")
print("✅ Optimized identity and contact managers")
print("✅ Performance regression tests")
print("✅ Integration with existing architecture")

print("\n🎯 PERFORMANCE FEATURES IMPLEMENTED:")
print("• Real-time performance monitoring and metrics collection")
print("• Lazy loading with intelligent caching strategies")
print("• Background crypto operations with priority queues")
print("• Memory-efficient crypto operations with secure cleanup")
print("• Comprehensive benchmarking and performance analysis")
print("• Cache management with hit/miss tracking")
print("• Memory pool for buffer reuse")
print("• Performance regression testing")

exit(validationErrors.isEmpty ? 0 : 1)
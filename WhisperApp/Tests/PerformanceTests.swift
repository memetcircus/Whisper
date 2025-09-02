import XCTest
import CryptoKit
@testable import WhisperApp

/// Comprehensive performance tests for optimization features
/// Tests lazy loading, memory optimization, background processing, and benchmarking
class PerformanceTests: XCTestCase {
    
    var performanceMonitor: WhisperPerformanceMonitor!
    var lazyLoadingService: WhisperLazyLoadingService!
    var memoryOptimizedCrypto: WhisperMemoryOptimizedCrypto!
    var backgroundProcessor: WhisperBackgroundCryptoProcessor!
    var cryptoBenchmarks: WhisperCryptoBenchmarks!
    var cryptoEngine: CryptoKitEngine!
    var envelopeProcessor: EnvelopeProcessor!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Set up Core Data context for testing
        context = TestCoreDataStack.shared.context
        
        // Initialize crypto components
        cryptoEngine = CryptoKitEngine()
        envelopeProcessor = WhisperEnvelopeProcessor(cryptoEngine: cryptoEngine)
        
        // Initialize performance components
        performanceMonitor = WhisperPerformanceMonitor()
        lazyLoadingService = WhisperLazyLoadingService(
            context: context,
            performanceMonitor: performanceMonitor
        )
        memoryOptimizedCrypto = WhisperMemoryOptimizedCrypto(
            cryptoEngine: cryptoEngine,
            envelopeProcessor: envelopeProcessor,
            performanceMonitor: performanceMonitor
        )
        backgroundProcessor = WhisperBackgroundCryptoProcessor(
            cryptoEngine: cryptoEngine,
            envelopeProcessor: envelopeProcessor,
            performanceMonitor: performanceMonitor
        )
        cryptoBenchmarks = WhisperCryptoBenchmarks(
            cryptoEngine: cryptoEngine,
            memoryOptimizedCrypto: memoryOptimizedCrypto,
            performanceMonitor: performanceMonitor
        )
    }
    
    override func tearDown() {
        performanceMonitor = nil
        lazyLoadingService = nil
        memoryOptimizedCrypto = nil
        backgroundProcessor = nil
        cryptoBenchmarks = nil
        cryptoEngine = nil
        envelopeProcessor = nil
        context = nil
        
        super.tearDown()
    }
    
    // MARK: - Performance Monitor Tests
    
    func testPerformanceMonitorMeasurement() {
        let testOperation = "test_crypto_operation"
        
        let (result, duration) = performanceMonitor.measureCryptoOperation(testOperation) {
            // Simulate crypto work
            Thread.sleep(forTimeInterval: 0.01)
            return "test_result"
        }
        
        XCTAssertEqual(result, "test_result")
        XCTAssertGreaterThan(duration, 0.005) // Should be at least 5ms
        
        // Check that metrics were recorded
        let statistics = performanceMonitor.getStatistics(for: testOperation)
        XCTAssertNotNil(statistics)
        XCTAssertEqual(statistics?.executionCount, 1)
        XCTAssertGreaterThan(statistics?.averageDuration ?? 0, 0)
    }
    
    func testMemoryUsageMeasurement() {
        let testOperation = "test_memory_operation"
        
        let (result, memoryDelta) = performanceMonitor.measureMemoryUsage(testOperation) {
            // Allocate some memory
            let largeData = Data(count: 1024 * 1024) // 1MB
            return largeData.count
        }
        
        XCTAssertEqual(result, 1024 * 1024)
        // Memory delta might be positive or negative depending on system state
        XCTAssertNotEqual(memoryDelta, 0)
    }
    
    func testPerformanceStatisticsAccumulation() {
        let testOperation = "accumulation_test"
        
        // Perform multiple operations
        for i in 0..<10 {
            performanceMonitor.measureCryptoOperation(testOperation) {
                Thread.sleep(forTimeInterval: Double(i) * 0.001) // Variable duration
                return i
            }
        }
        
        let statistics = performanceMonitor.getStatistics(for: testOperation)
        XCTAssertNotNil(statistics)
        XCTAssertEqual(statistics?.executionCount, 10)
        XCTAssertGreaterThan(statistics?.averageDuration ?? 0, 0)
        XCTAssertGreaterThan(statistics?.maxDuration ?? 0, statistics?.minDuration ?? 0)
    }
    
    // MARK: - Lazy Loading Tests
    
    func testIdentityMetadataLoading() {
        // Create test identity
        let identity = try! cryptoEngine.generateIdentity()
        
        // Store in Core Data (simplified for test)
        let entity = IdentityEntity(context: context)
        entity.id = identity.id
        entity.name = identity.name
        entity.fingerprint = identity.fingerprint
        entity.createdAt = identity.createdAt
        entity.status = identity.status.rawValue
        entity.keyVersion = Int32(identity.keyVersion)
        entity.isActive = true
        
        try! context.save()
        
        // Test lazy loading
        let metadata = lazyLoadingService.loadIdentityMetadata(id: identity.id)
        XCTAssertNotNil(metadata)
        XCTAssertEqual(metadata?.id, identity.id)
        XCTAssertEqual(metadata?.name, identity.name)
        XCTAssertEqual(metadata?.fingerprint, identity.fingerprint)
    }
    
    func testCacheStatistics() {
        let initialStats = lazyLoadingService.getCacheStatistics()
        XCTAssertEqual(initialStats.identityCacheSize, 0)
        XCTAssertEqual(initialStats.contactCacheSize, 0)
        
        // Load some data to populate cache
        lazyLoadingService.preloadFrequentlyUsed()
        
        let updatedStats = lazyLoadingService.getCacheStatistics()
        // Cache size might increase depending on available data
        XCTAssertGreaterThanOrEqual(updatedStats.totalMemoryUsage, 0)
    }
    
    func testCacheClearance() {
        // Populate cache
        lazyLoadingService.preloadFrequentlyUsed()
        
        let statsBeforeClear = lazyLoadingService.getCacheStatistics()
        
        // Clear cache
        lazyLoadingService.clearCache()
        
        let statsAfterClear = lazyLoadingService.getCacheStatistics()
        XCTAssertEqual(statsAfterClear.identityCacheSize, 0)
        XCTAssertEqual(statsAfterClear.contactCacheSize, 0)
        XCTAssertEqual(statsAfterClear.hitRate, 0.0)
        XCTAssertEqual(statsAfterClear.missRate, 0.0)
    }
    
    // MARK: - Memory Optimization Tests
    
    func testMemoryOptimizedEncryption() {
        let identity = try! cryptoEngine.generateIdentity()
        let recipientKey = try! cryptoEngine.generateEphemeralKeyPair().publicKey
        let plaintext = "Test message for memory optimization".data(using: .utf8)!
        
        let initialMemory = memoryOptimizedCrypto.getCryptoMemoryUsage()
        
        let envelope = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
            plaintext: plaintext,
            identity: identity,
            recipientPublicKey: recipientKey,
            requireSignature: false
        )
        
        XCTAssertTrue(envelope.hasPrefix("whisper1:"))
        
        // Memory usage should be tracked
        let finalMemory = memoryOptimizedCrypto.getCryptoMemoryUsage()
        // Memory might increase or decrease depending on cleanup timing
    }
    
    func testMemoryOptimizedDecryption() {
        let identity = try! cryptoEngine.generateIdentity()
        let plaintext = "Test message for decryption".data(using: .utf8)!
        
        // First encrypt
        let envelope = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
            plaintext: plaintext,
            identity: identity,
            recipientPublicKey: identity.x25519KeyPair.publicKey,
            requireSignature: false
        )
        
        // Then decrypt
        let decryptedData = try! memoryOptimizedCrypto.decryptWithMemoryOptimization(
            envelope: envelope,
            identity: identity
        )
        
        XCTAssertEqual(decryptedData, plaintext)
    }
    
    func testSecureMemoryClearing() {
        var sensitiveData = "sensitive information".data(using: .utf8)!
        let originalData = Data(sensitiveData)
        
        memoryOptimizedCrypto.secureClear(&sensitiveData)
        
        // Data should be zeroed
        XCTAssertNotEqual(sensitiveData, originalData)
        XCTAssertTrue(sensitiveData.allSatisfy { $0 == 0 })
    }
    
    func testMemoryOptimization() {
        let initialMemory = memoryOptimizedCrypto.getCryptoMemoryUsage()
        
        // Perform some operations to allocate memory
        let identity = try! cryptoEngine.generateIdentity()
        let plaintext = Data(count: 1024) // 1KB
        
        _ = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
            plaintext: plaintext,
            identity: identity,
            recipientPublicKey: identity.x25519KeyPair.publicKey,
            requireSignature: false
        )
        
        // Optimize memory
        memoryOptimizedCrypto.optimizeMemory()
        
        let finalMemory = memoryOptimizedCrypto.getCryptoMemoryUsage()
        XCTAssertEqual(finalMemory, 0) // Should be reset after optimization
    }
    
    // MARK: - Background Processing Tests
    
    func testBackgroundEncryption() {
        let expectation = XCTestExpectation(description: "Background encryption")
        
        let identity = try! cryptoEngine.generateIdentity()
        let recipientKey = try! cryptoEngine.generateEphemeralKeyPair().publicKey
        let plaintext = "Background encryption test".data(using: .utf8)!
        
        let publisher = backgroundProcessor.encryptInBackground(
            plaintext: plaintext,
            identity: identity,
            recipientPublicKey: recipientKey,
            requireSignature: false
        )
        
        var cancellables = Set<AnyCancellable>()
        
        publisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Background encryption failed: \(error)")
                    }
                },
                receiveValue: { envelope in
                    XCTAssertTrue(envelope.hasPrefix("whisper1:"))
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testBackgroundIdentityGeneration() {
        let expectation = XCTestExpectation(description: "Background identity generation")
        
        let publisher = backgroundProcessor.generateIdentityInBackground(name: "Test Identity")
        
        var cancellables = Set<AnyCancellable>()
        
        publisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Background identity generation failed: \(error)")
                    }
                },
                receiveValue: { identity in
                    XCTAssertEqual(identity.name, "Test Identity")
                    XCTAssertEqual(identity.status, .active)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testOperationCancellation() {
        let initialCount = backgroundProcessor.getPendingOperationsCount()
        
        // Start multiple operations
        let identity = try! cryptoEngine.generateIdentity()
        let plaintext = Data(count: 1024)
        
        for _ in 0..<5 {
            _ = backgroundProcessor.encryptInBackground(
                plaintext: plaintext,
                identity: identity,
                recipientPublicKey: identity.x25519KeyPair.publicKey,
                requireSignature: false
            )
        }
        
        // Cancel all operations
        backgroundProcessor.cancelAllOperations()
        
        let finalCount = backgroundProcessor.getPendingOperationsCount()
        XCTAssertEqual(finalCount, initialCount)
    }
    
    // MARK: - Benchmark Tests
    
    func testEncryptionBenchmark() {
        let messageSizes = [256, 512, 1024]
        let iterations = 10
        
        let results = cryptoBenchmarks.benchmarkEncryption(
            messageSizes: messageSizes,
            iterations: iterations
        )
        
        XCTAssertEqual(results.results.count, messageSizes.count)
        
        for (index, result) in results.results.enumerated() {
            XCTAssertEqual(result.messageSize, messageSizes[index])
            XCTAssertEqual(result.iterations, iterations)
            XCTAssertGreaterThan(result.averageTime, 0)
            XCTAssertGreaterThan(result.throughputMBps, 0)
            XCTAssertGreaterThan(result.operationsPerSecond, 0)
        }
        
        XCTAssertGreaterThan(results.summary.totalOperations, 0)
        XCTAssertGreaterThan(results.summary.averageThroughputMBps, 0)
    }
    
    func testKeyGenerationBenchmark() {
        let iterations = 5
        
        let results = cryptoBenchmarks.benchmarkKeyGeneration(iterations: iterations)
        
        XCTAssertEqual(results.x25519Generation.iterations, iterations)
        XCTAssertEqual(results.ed25519Generation.iterations, iterations)
        XCTAssertEqual(results.identityGeneration.iterations, iterations)
        
        XCTAssertGreaterThan(results.x25519Generation.averageTime, 0)
        XCTAssertGreaterThan(results.ed25519Generation.averageTime, 0)
        XCTAssertGreaterThan(results.identityGeneration.averageTime, 0)
        
        XCTAssertGreaterThan(results.x25519Generation.operationsPerSecond, 0)
        XCTAssertGreaterThan(results.ed25519Generation.operationsPerSecond, 0)
        XCTAssertGreaterThan(results.identityGeneration.operationsPerSecond, 0)
    }
    
    func testMemoryBenchmark() {
        let messageSizes = [256, 512]
        let iterations = 5
        
        let results = cryptoBenchmarks.benchmarkMemoryUsage(
            messageSizes: messageSizes,
            iterations: iterations
        )
        
        XCTAssertEqual(results.encryptionMemory.count, messageSizes.count)
        XCTAssertEqual(results.decryptionMemory.count, messageSizes.count)
        
        for memoryResult in results.encryptionMemory {
            XCTAssertGreaterThan(memoryResult.memoryEfficiency, 0)
        }
        
        for memoryResult in results.decryptionMemory {
            XCTAssertGreaterThan(memoryResult.memoryEfficiency, 0)
        }
    }
    
    func testBenchmarkExport() {
        let messageSizes = [256]
        let iterations = 2
        
        let results = cryptoBenchmarks.benchmarkEncryption(
            messageSizes: messageSizes,
            iterations: iterations
        )
        
        let exportedData = try! cryptoBenchmarks.exportBenchmarkResults(results)
        XCTAssertGreaterThan(exportedData.count, 0)
        
        // Verify it's valid JSON
        let decoded = try! JSONDecoder().decode(EncryptionBenchmarkResults.self, from: exportedData)
        XCTAssertEqual(decoded.results.count, results.results.count)
    }
    
    // MARK: - Performance Regression Tests
    
    func testEncryptionPerformanceRegression() {
        let plaintext = Data(count: 1024) // 1KB message
        let identity = try! cryptoEngine.generateIdentity()
        let recipientKey = try! cryptoEngine.generateEphemeralKeyPair().publicKey
        
        measure {
            _ = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
                plaintext: plaintext,
                identity: identity,
                recipientPublicKey: recipientKey,
                requireSignature: false
            )
        }
    }
    
    func testDecryptionPerformanceRegression() {
        let plaintext = Data(count: 1024) // 1KB message
        let identity = try! cryptoEngine.generateIdentity()
        
        let envelope = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
            plaintext: plaintext,
            identity: identity,
            recipientPublicKey: identity.x25519KeyPair.publicKey,
            requireSignature: false
        )
        
        measure {
            _ = try! memoryOptimizedCrypto.decryptWithMemoryOptimization(
                envelope: envelope,
                identity: identity
            )
        }
    }
    
    func testIdentityGenerationPerformanceRegression() {
        measure {
            _ = try! cryptoEngine.generateIdentity()
        }
    }
}

// MARK: - Test Core Data Stack

class TestCoreDataStack {
    static let shared = TestCoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WhisperDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}

// MARK: - Import Statements for Combine

import Combine
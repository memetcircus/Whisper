import Foundation
import CryptoKit

/// Performance benchmarking service for cryptographic operations
/// Provides detailed performance analysis and optimization insights
protocol CryptoBenchmarks {
    /// Runs comprehensive encryption benchmarks
    /// - Parameters:
    ///   - messageSizes: Array of message sizes to test (in bytes)
    ///   - iterations: Number of iterations per test
    /// - Returns: Benchmark results
    func benchmarkEncryption(messageSizes: [Int], iterations: Int) -> EncryptionBenchmarkResults
    
    /// Runs comprehensive decryption benchmarks
    /// - Parameters:
    ///   - messageSizes: Array of message sizes to test (in bytes)
    ///   - iterations: Number of iterations per test
    /// - Returns: Benchmark results
    func benchmarkDecryption(messageSizes: [Int], iterations: Int) -> DecryptionBenchmarkResults
    
    /// Benchmarks key generation performance
    /// - Parameter iterations: Number of key generations to test
    /// - Returns: Key generation benchmark results
    func benchmarkKeyGeneration(iterations: Int) -> KeyGenerationBenchmarkResults
    
    /// Benchmarks signature operations
    /// - Parameters:
    ///   - messageSizes: Array of message sizes to test
    ///   - iterations: Number of iterations per test
    /// - Returns: Signature benchmark results
    func benchmarkSignatures(messageSizes: [Int], iterations: Int) -> SignatureBenchmarkResults
    
    /// Runs memory usage benchmarks
    /// - Parameters:
    ///   - messageSizes: Array of message sizes to test
    ///   - iterations: Number of iterations per test
    /// - Returns: Memory usage benchmark results
    func benchmarkMemoryUsage(messageSizes: [Int], iterations: Int) -> MemoryBenchmarkResults
    
    /// Exports benchmark results as JSON
    /// - Parameter results: Benchmark results to export
    /// - Returns: JSON data
    func exportBenchmarkResults<T: Codable>(_ results: T) throws -> Data
}

// MARK: - Benchmark Result Types

struct EncryptionBenchmarkResults: Codable {
    let testDate: Date
    let deviceInfo: DeviceInfo
    let results: [MessageSizeBenchmark]
    let summary: BenchmarkSummary
}

struct DecryptionBenchmarkResults: Codable {
    let testDate: Date
    let deviceInfo: DeviceInfo
    let results: [MessageSizeBenchmark]
    let summary: BenchmarkSummary
}

struct KeyGenerationBenchmarkResults: Codable {
    let testDate: Date
    let deviceInfo: DeviceInfo
    let x25519Generation: OperationBenchmark
    let ed25519Generation: OperationBenchmark
    let identityGeneration: OperationBenchmark
}

struct SignatureBenchmarkResults: Codable {
    let testDate: Date
    let deviceInfo: DeviceInfo
    let signingResults: [MessageSizeBenchmark]
    let verificationResults: [MessageSizeBenchmark]
    let summary: BenchmarkSummary
}

struct MemoryBenchmarkResults: Codable {
    let testDate: Date
    let deviceInfo: DeviceInfo
    let encryptionMemory: [MemoryUsageBenchmark]
    let decryptionMemory: [MemoryUsageBenchmark]
    let peakMemoryUsage: Int64
    let averageMemoryUsage: Int64
}

struct MessageSizeBenchmark: Codable {
    let messageSize: Int
    let iterations: Int
    let totalTime: TimeInterval
    let averageTime: TimeInterval
    let minTime: TimeInterval
    let maxTime: TimeInterval
    let throughputMBps: Double
    let operationsPerSecond: Double
}

struct OperationBenchmark: Codable {
    let iterations: Int
    let totalTime: TimeInterval
    let averageTime: TimeInterval
    let minTime: TimeInterval
    let maxTime: TimeInterval
    let operationsPerSecond: Double
}

struct MemoryUsageBenchmark: Codable {
    let messageSize: Int
    let peakMemoryUsage: Int64
    let averageMemoryUsage: Int64
    let memoryEfficiency: Double // bytes per message byte
}

struct BenchmarkSummary: Codable {
    let totalOperations: Int
    let totalTime: TimeInterval
    let averageThroughputMBps: Double
    let peakThroughputMBps: Double
    let averageLatencyMs: Double
    let minLatencyMs: Double
    let maxLatencyMs: Double
}

struct DeviceInfo: Codable {
    let model: String
    let systemVersion: String
    let processorCount: Int
    let memorySize: Int64
}

/// Concrete implementation of CryptoBenchmarks
class WhisperCryptoBenchmarks: CryptoBenchmarks {
    
    private let cryptoEngine: CryptoEngine
    private let memoryOptimizedCrypto: MemoryOptimizedCrypto
    private let performanceMonitor: PerformanceMonitor
    
    init(cryptoEngine: CryptoEngine, memoryOptimizedCrypto: MemoryOptimizedCrypto, performanceMonitor: PerformanceMonitor) {
        self.cryptoEngine = cryptoEngine
        self.memoryOptimizedCrypto = memoryOptimizedCrypto
        self.performanceMonitor = performanceMonitor
    }
    
    // MARK: - Encryption Benchmarks
    
    func benchmarkEncryption(messageSizes: [Int], iterations: Int) -> EncryptionBenchmarkResults {
        let deviceInfo = collectDeviceInfo()
        var results: [MessageSizeBenchmark] = []
        
        for messageSize in messageSizes {
            let benchmark = benchmarkEncryptionForSize(messageSize, iterations: iterations)
            results.append(benchmark)
        }
        
        let summary = calculateSummary(from: results)
        
        return EncryptionBenchmarkResults(
            testDate: Date(),
            deviceInfo: deviceInfo,
            results: results,
            summary: summary
        )
    }
    
    private func benchmarkEncryptionForSize(_ messageSize: Int, iterations: Int) -> MessageSizeBenchmark {
        // Generate test data
        let testMessage = generateTestData(size: messageSize)
        let testIdentity = try! cryptoEngine.generateIdentity()
        let recipientKey = try! cryptoEngine.generateEphemeralKeyPair().publicKey
        
        var times: [TimeInterval] = []
        times.reserveCapacity(iterations)
        
        // Warm up
        for _ in 0..<min(10, iterations) {
            _ = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
                plaintext: testMessage,
                identity: testIdentity,
                recipientPublicKey: recipientKey,
                requireSignature: false
            )
        }
        
        // Actual benchmark
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            _ = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
                plaintext: testMessage,
                identity: testIdentity,
                recipientPublicKey: recipientKey,
                requireSignature: false
            )
            
            let endTime = CFAbsoluteTimeGetCurrent()
            times.append(endTime - startTime)
        }
        
        return calculateMessageSizeBenchmark(
            messageSize: messageSize,
            iterations: iterations,
            times: times
        )
    }
    
    // MARK: - Decryption Benchmarks
    
    func benchmarkDecryption(messageSizes: [Int], iterations: Int) -> DecryptionBenchmarkResults {
        let deviceInfo = collectDeviceInfo()
        var results: [MessageSizeBenchmark] = []
        
        for messageSize in messageSizes {
            let benchmark = benchmarkDecryptionForSize(messageSize, iterations: iterations)
            results.append(benchmark)
        }
        
        let summary = calculateSummary(from: results)
        
        return DecryptionBenchmarkResults(
            testDate: Date(),
            deviceInfo: deviceInfo,
            results: results,
            summary: summary
        )
    }
    
    private func benchmarkDecryptionForSize(_ messageSize: Int, iterations: Int) -> MessageSizeBenchmark {
        // Generate test data and encrypt it
        let testMessage = generateTestData(size: messageSize)
        let testIdentity = try! cryptoEngine.generateIdentity()
        
        let envelope = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
            plaintext: testMessage,
            identity: testIdentity,
            recipientPublicKey: testIdentity.x25519KeyPair.publicKey,
            requireSignature: false
        )
        
        var times: [TimeInterval] = []
        times.reserveCapacity(iterations)
        
        // Warm up
        for _ in 0..<min(10, iterations) {
            _ = try! memoryOptimizedCrypto.decryptWithMemoryOptimization(
                envelope: envelope,
                identity: testIdentity
            )
        }
        
        // Actual benchmark
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            _ = try! memoryOptimizedCrypto.decryptWithMemoryOptimization(
                envelope: envelope,
                identity: testIdentity
            )
            
            let endTime = CFAbsoluteTimeGetCurrent()
            times.append(endTime - startTime)
        }
        
        return calculateMessageSizeBenchmark(
            messageSize: messageSize,
            iterations: iterations,
            times: times
        )
    }
    
    // MARK: - Key Generation Benchmarks
    
    func benchmarkKeyGeneration(iterations: Int) -> KeyGenerationBenchmarkResults {
        let deviceInfo = collectDeviceInfo()
        
        // Benchmark X25519 key generation
        let x25519Benchmark = benchmarkX25519KeyGeneration(iterations: iterations)
        
        // Benchmark Ed25519 key generation
        let ed25519Benchmark = benchmarkEd25519KeyGeneration(iterations: iterations)
        
        // Benchmark full identity generation
        let identityBenchmark = benchmarkIdentityGeneration(iterations: iterations)
        
        return KeyGenerationBenchmarkResults(
            testDate: Date(),
            deviceInfo: deviceInfo,
            x25519Generation: x25519Benchmark,
            ed25519Generation: ed25519Benchmark,
            identityGeneration: identityBenchmark
        )
    }
    
    private func benchmarkX25519KeyGeneration(iterations: Int) -> OperationBenchmark {
        var times: [TimeInterval] = []
        times.reserveCapacity(iterations)
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try! cryptoEngine.generateEphemeralKeyPair()
            let endTime = CFAbsoluteTimeGetCurrent()
            times.append(endTime - startTime)
        }
        
        return calculateOperationBenchmark(iterations: iterations, times: times)
    }
    
    private func benchmarkEd25519KeyGeneration(iterations: Int) -> OperationBenchmark {
        var times: [TimeInterval] = []
        times.reserveCapacity(iterations)
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = Curve25519.Signing.PrivateKey()
            let endTime = CFAbsoluteTimeGetCurrent()
            times.append(endTime - startTime)
        }
        
        return calculateOperationBenchmark(iterations: iterations, times: times)
    }
    
    private func benchmarkIdentityGeneration(iterations: Int) -> OperationBenchmark {
        var times: [TimeInterval] = []
        times.reserveCapacity(iterations)
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try! cryptoEngine.generateIdentity()
            let endTime = CFAbsoluteTimeGetCurrent()
            times.append(endTime - startTime)
        }
        
        return calculateOperationBenchmark(iterations: iterations, times: times)
    }
    
    // MARK: - Signature Benchmarks
    
    func benchmarkSignatures(messageSizes: [Int], iterations: Int) -> SignatureBenchmarkResults {
        let deviceInfo = collectDeviceInfo()
        var signingResults: [MessageSizeBenchmark] = []
        var verificationResults: [MessageSizeBenchmark] = []
        
        for messageSize in messageSizes {
            let signingBenchmark = benchmarkSigningForSize(messageSize, iterations: iterations)
            let verificationBenchmark = benchmarkVerificationForSize(messageSize, iterations: iterations)
            
            signingResults.append(signingBenchmark)
            verificationResults.append(verificationBenchmark)
        }
        
        let combinedResults = signingResults + verificationResults
        let summary = calculateSummary(from: combinedResults)
        
        return SignatureBenchmarkResults(
            testDate: Date(),
            deviceInfo: deviceInfo,
            signingResults: signingResults,
            verificationResults: verificationResults,
            summary: summary
        )
    }
    
    private func benchmarkSigningForSize(_ messageSize: Int, iterations: Int) -> MessageSizeBenchmark {
        let testMessage = generateTestData(size: messageSize)
        let signingKey = Curve25519.Signing.PrivateKey()
        
        var times: [TimeInterval] = []
        times.reserveCapacity(iterations)
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try! cryptoEngine.sign(data: testMessage, privateKey: signingKey)
            let endTime = CFAbsoluteTimeGetCurrent()
            times.append(endTime - startTime)
        }
        
        return calculateMessageSizeBenchmark(
            messageSize: messageSize,
            iterations: iterations,
            times: times
        )
    }
    
    private func benchmarkVerificationForSize(_ messageSize: Int, iterations: Int) -> MessageSizeBenchmark {
        let testMessage = generateTestData(size: messageSize)
        let signingKey = Curve25519.Signing.PrivateKey()
        let publicKey = signingKey.publicKey.rawRepresentation
        let signature = try! cryptoEngine.sign(data: testMessage, privateKey: signingKey)
        
        var times: [TimeInterval] = []
        times.reserveCapacity(iterations)
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try! cryptoEngine.verify(signature: signature, data: testMessage, publicKey: publicKey)
            let endTime = CFAbsoluteTimeGetCurrent()
            times.append(endTime - startTime)
        }
        
        return calculateMessageSizeBenchmark(
            messageSize: messageSize,
            iterations: iterations,
            times: times
        )
    }
    
    // MARK: - Memory Usage Benchmarks
    
    func benchmarkMemoryUsage(messageSizes: [Int], iterations: Int) -> MemoryBenchmarkResults {
        let deviceInfo = collectDeviceInfo()
        var encryptionMemory: [MemoryUsageBenchmark] = []
        var decryptionMemory: [MemoryUsageBenchmark] = []
        var peakMemory: Int64 = 0
        var totalMemory: Int64 = 0
        var measurements = 0
        
        for messageSize in messageSizes {
            let encBenchmark = benchmarkEncryptionMemory(messageSize: messageSize, iterations: iterations)
            let decBenchmark = benchmarkDecryptionMemory(messageSize: messageSize, iterations: iterations)
            
            encryptionMemory.append(encBenchmark)
            decryptionMemory.append(decBenchmark)
            
            peakMemory = max(peakMemory, encBenchmark.peakMemoryUsage, decBenchmark.peakMemoryUsage)
            totalMemory += encBenchmark.averageMemoryUsage + decBenchmark.averageMemoryUsage
            measurements += 2
        }
        
        return MemoryBenchmarkResults(
            testDate: Date(),
            deviceInfo: deviceInfo,
            encryptionMemory: encryptionMemory,
            decryptionMemory: decryptionMemory,
            peakMemoryUsage: peakMemory,
            averageMemoryUsage: measurements > 0 ? totalMemory / Int64(measurements) : 0
        )
    }
    
    private func benchmarkEncryptionMemory(messageSize: Int, iterations: Int) -> MemoryUsageBenchmark {
        let testMessage = generateTestData(size: messageSize)
        let testIdentity = try! cryptoEngine.generateIdentity()
        let recipientKey = try! cryptoEngine.generateEphemeralKeyPair().publicKey
        
        var memoryUsages: [Int64] = []
        var peakMemory: Int64 = 0
        
        for _ in 0..<iterations {
            let startMemory = performanceMonitor.getCurrentMemoryUsage()
            
            _ = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
                plaintext: testMessage,
                identity: testIdentity,
                recipientPublicKey: recipientKey,
                requireSignature: false
            )
            
            let endMemory = performanceMonitor.getCurrentMemoryUsage()
            let memoryDelta = endMemory - startMemory
            
            memoryUsages.append(memoryDelta)
            peakMemory = max(peakMemory, endMemory)
        }
        
        let averageMemory = memoryUsages.reduce(0, +) / Int64(memoryUsages.count)
        let efficiency = Double(averageMemory) / Double(messageSize)
        
        return MemoryUsageBenchmark(
            messageSize: messageSize,
            peakMemoryUsage: peakMemory,
            averageMemoryUsage: averageMemory,
            memoryEfficiency: efficiency
        )
    }
    
    private func benchmarkDecryptionMemory(messageSize: Int, iterations: Int) -> MemoryUsageBenchmark {
        let testMessage = generateTestData(size: messageSize)
        let testIdentity = try! cryptoEngine.generateIdentity()
        
        let envelope = try! memoryOptimizedCrypto.encryptWithMemoryOptimization(
            plaintext: testMessage,
            identity: testIdentity,
            recipientPublicKey: testIdentity.x25519KeyPair.publicKey,
            requireSignature: false
        )
        
        var memoryUsages: [Int64] = []
        var peakMemory: Int64 = 0
        
        for _ in 0..<iterations {
            let startMemory = performanceMonitor.getCurrentMemoryUsage()
            
            _ = try! memoryOptimizedCrypto.decryptWithMemoryOptimization(
                envelope: envelope,
                identity: testIdentity
            )
            
            let endMemory = performanceMonitor.getCurrentMemoryUsage()
            let memoryDelta = endMemory - startMemory
            
            memoryUsages.append(memoryDelta)
            peakMemory = max(peakMemory, endMemory)
        }
        
        let averageMemory = memoryUsages.reduce(0, +) / Int64(memoryUsages.count)
        let efficiency = Double(averageMemory) / Double(messageSize)
        
        return MemoryUsageBenchmark(
            messageSize: messageSize,
            peakMemoryUsage: peakMemory,
            averageMemoryUsage: averageMemory,
            memoryEfficiency: efficiency
        )
    }
    
    // MARK: - Export Results
    
    func exportBenchmarkResults<T: Codable>(_ results: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(results)
    }
    
    // MARK: - Helper Methods
    
    private func generateTestData(size: Int) -> Data {
        return Data((0..<size).map { _ in UInt8.random(in: 0...255) })
    }
    
    private func collectDeviceInfo() -> DeviceInfo {
        return DeviceInfo(
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            processorCount: ProcessInfo.processInfo.processorCount,
            memorySize: ProcessInfo.processInfo.physicalMemory
        )
    }
    
    private func calculateMessageSizeBenchmark(
        messageSize: Int,
        iterations: Int,
        times: [TimeInterval]
    ) -> MessageSizeBenchmark {
        
        let totalTime = times.reduce(0, +)
        let averageTime = totalTime / Double(iterations)
        let minTime = times.min() ?? 0
        let maxTime = times.max() ?? 0
        
        let throughputMBps = (Double(messageSize) * Double(iterations)) / (totalTime * 1024 * 1024)
        let operationsPerSecond = Double(iterations) / totalTime
        
        return MessageSizeBenchmark(
            messageSize: messageSize,
            iterations: iterations,
            totalTime: totalTime,
            averageTime: averageTime,
            minTime: minTime,
            maxTime: maxTime,
            throughputMBps: throughputMBps,
            operationsPerSecond: operationsPerSecond
        )
    }
    
    private func calculateOperationBenchmark(iterations: Int, times: [TimeInterval]) -> OperationBenchmark {
        let totalTime = times.reduce(0, +)
        let averageTime = totalTime / Double(iterations)
        let minTime = times.min() ?? 0
        let maxTime = times.max() ?? 0
        let operationsPerSecond = Double(iterations) / totalTime
        
        return OperationBenchmark(
            iterations: iterations,
            totalTime: totalTime,
            averageTime: averageTime,
            minTime: minTime,
            maxTime: maxTime,
            operationsPerSecond: operationsPerSecond
        )
    }
    
    private func calculateSummary(from results: [MessageSizeBenchmark]) -> BenchmarkSummary {
        let totalOperations = results.reduce(0) { $0 + $1.iterations }
        let totalTime = results.reduce(0) { $0 + $1.totalTime }
        let throughputs = results.map { $0.throughputMBps }
        let latencies = results.map { $0.averageTime * 1000 } // Convert to ms
        
        return BenchmarkSummary(
            totalOperations: totalOperations,
            totalTime: totalTime,
            averageThroughputMBps: throughputs.reduce(0, +) / Double(throughputs.count),
            peakThroughputMBps: throughputs.max() ?? 0,
            averageLatencyMs: latencies.reduce(0, +) / Double(latencies.count),
            minLatencyMs: latencies.min() ?? 0,
            maxLatencyMs: latencies.max() ?? 0
        )
    }
}

// MARK: - UIDevice Extension for Model Info

#if canImport(UIKit)
import UIKit
#else
// For non-iOS platforms, provide fallback
extension UIDevice {
    static let current = UIDevice()
    let model = "Unknown"
    let systemVersion = "Unknown"
}

class UIDevice {
    let model: String
    let systemVersion: String
    
    init() {
        self.model = "macOS" // Fallback for development
        self.systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
    }
}
#endif
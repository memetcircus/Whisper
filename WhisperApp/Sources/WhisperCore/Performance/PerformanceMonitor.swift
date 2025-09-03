import Foundation
import os.log

/// Performance monitoring service for tracking crypto operations and memory usage
/// Provides benchmarking and optimization insights for the Whisper app
protocol PerformanceMonitor {
    /// Measures execution time of a cryptographic operation
    /// - Parameters:
    ///   - operation: Name of the operation being measured
    ///   - block: The operation to measure
    /// - Returns: Result of the operation and execution time
    func measureCryptoOperation<T>(_ operation: String, block: () throws -> T) rethrows -> (result: T, duration: TimeInterval)
    
    /// Records memory usage before and after an operation
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - block: The operation to monitor
    /// - Returns: Result and memory usage statistics
    func measureMemoryUsage<T>(_ operation: String, block: () throws -> T) rethrows -> (result: T, memoryDelta: Int64)
    
    /// Gets current memory usage statistics
    /// - Returns: Memory usage in bytes
    func getCurrentMemoryUsage() -> Int64
    
    /// Records performance metrics for analysis
    /// - Parameters:
    ///   - operation: Operation name
    ///   - duration: Execution time in seconds
    ///   - memoryUsage: Memory usage in bytes
    func recordMetrics(operation: String, duration: TimeInterval, memoryUsage: Int64?)
    
    /// Gets performance statistics for an operation
    /// - Parameter operation: Operation name
    /// - Returns: Performance statistics or nil if no data
    func getStatistics(for operation: String) -> PerformanceStatistics?
    
    /// Exports all performance data for analysis
    /// - Returns: JSON data containing all metrics
    func exportMetrics() throws -> Data
}

/// Performance statistics for a specific operation
struct PerformanceStatistics {
    let operationName: String
    let executionCount: Int
    let averageDuration: TimeInterval
    let minDuration: TimeInterval
    let maxDuration: TimeInterval
    let averageMemoryUsage: Int64?
    let maxMemoryUsage: Int64?
    let lastExecuted: Date
}

/// Concrete implementation of PerformanceMonitor
class WhisperPerformanceMonitor: PerformanceMonitor {
    
    private let logger = Logger(subsystem: "com.whisper.performance", category: "monitoring")
    private let queue = DispatchQueue(label: "performance-monitor", qos: .utility)
    private var metrics: [String: [PerformanceMetric]] = [:]
    
    // MARK: - Performance Measurement
    
    func measureCryptoOperation<T>(_ operation: String, block: () throws -> T) rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        recordMetrics(operation: operation, duration: duration, memoryUsage: nil)
        
        #if DEBUG
        logger.debug("Crypto operation '\(operation)' completed in \(duration * 1000, privacy: .public)ms")
        #endif
        
        return (result, duration)
    }
    
    func measureMemoryUsage<T>(_ operation: String, block: () throws -> T) rethrows -> (result: T, memoryDelta: Int64) {
        let startMemory = getCurrentMemoryUsage()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = try block()
        
        let endMemory = getCurrentMemoryUsage()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let memoryDelta = endMemory - startMemory
        
        recordMetrics(operation: operation, duration: duration, memoryUsage: endMemory)
        
        #if DEBUG
        logger.debug("Operation '\(operation)' memory delta: \(memoryDelta, privacy: .public) bytes")
        #endif
        
        return (result, memoryDelta)
    }
    
    func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        return Int64(info.resident_size)
    }
    
    // MARK: - Metrics Recording and Analysis
    
    func recordMetrics(operation: String, duration: TimeInterval, memoryUsage: Int64?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let metric = PerformanceMetric(
                operation: operation,
                duration: duration,
                memoryUsage: memoryUsage,
                timestamp: Date()
            )
            
            if self.metrics[operation] == nil {
                self.metrics[operation] = []
            }
            
            self.metrics[operation]?.append(metric)
            
            // Keep only last 1000 measurements per operation to prevent memory bloat
            if let count = self.metrics[operation]?.count, count > 1000 {
                self.metrics[operation]?.removeFirst(count - 1000)
            }
        }
    }
    
    func getStatistics(for operation: String) -> PerformanceStatistics? {
        return queue.sync {
            guard let operationMetrics = metrics[operation], !operationMetrics.isEmpty else {
                return nil
            }
            
            let durations = operationMetrics.map { $0.duration }
            let memoryUsages = operationMetrics.compactMap { $0.memoryUsage }
            
            return PerformanceStatistics(
                operationName: operation,
                executionCount: operationMetrics.count,
                averageDuration: durations.reduce(0, +) / Double(durations.count),
                minDuration: durations.min() ?? 0,
                maxDuration: durations.max() ?? 0,
                averageMemoryUsage: memoryUsages.isEmpty ? nil : memoryUsages.reduce(0, +) / Int64(memoryUsages.count),
                maxMemoryUsage: memoryUsages.max(),
                lastExecuted: operationMetrics.last?.timestamp ?? Date()
            )
        }
    }
    
    func exportMetrics() throws -> Data {
        return try queue.sync {
            let allStatistics = metrics.keys.compactMap { getStatistics(for: $0) }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(allStatistics)
        }
    }
}

// MARK: - Supporting Types

private struct PerformanceMetric {
    let operation: String
    let duration: TimeInterval
    let memoryUsage: Int64?
    let timestamp: Date
}

// MARK: - Performance Statistics Extensions

extension PerformanceStatistics: Codable {}

extension PerformanceStatistics {
    /// Human-readable performance summary
    var summary: String {
        let avgMs = String(format: "%.2f", averageDuration * 1000)
        let minMs = String(format: "%.2f", minDuration * 1000)
        let maxMs = String(format: "%.2f", maxDuration * 1000)
        
        var result = "\(operationName): \(executionCount) executions, avg: \(avgMs)ms, range: \(minMs)-\(maxMs)ms"
        
        if let avgMem = averageMemoryUsage {
            let avgMemMB = String(format: "%.2f", Double(avgMem) / 1024 / 1024)
            result += ", avg memory: \(avgMemMB)MB"
        }
        
        return result
    }
}
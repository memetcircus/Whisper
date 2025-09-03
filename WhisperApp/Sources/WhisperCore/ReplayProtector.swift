import Foundation

/// Protocol for replay protection functionality
protocol ReplayProtector {
    /// Atomically checks if a message is unique and commits it to the cache if valid
    /// - Parameters:
    ///   - msgId: The unique message identifier (16 bytes)
    ///   - timestamp: Unix timestamp in seconds
    /// - Returns: true if message is valid and committed, false if replay detected or expired
    func checkAndCommit(msgId: Data, timestamp: Int64) async -> Bool
    
    /// Checks if a timestamp is within the freshness window (±48 hours)
    /// - Parameter timestamp: Unix timestamp in seconds
    /// - Returns: true if within window, false if expired
    func isWithinFreshnessWindow(_ timestamp: Int64) -> Bool
    
    /// Performs cleanup of expired entries
    func cleanup() async
    
    /// Gets the current cache size for monitoring
    var cacheSize: Int { get async }
}

/// Errors that can occur during replay protection operations
enum ReplayProtectionError: Error {
    case messageExpired
    case replayDetected
    case cacheOverflow
    case persistenceError
}
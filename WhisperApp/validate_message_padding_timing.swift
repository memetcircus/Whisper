#!/usr/bin/env swift

import Foundation

// Copy the MessagePadding implementation for testing
public struct MessagePadding {
    
    /// Padding bucket sizes for length hiding
    public enum PaddingBucket: Int, CaseIterable {
        case small = 256
        case medium = 512
        case large = 1024
        
        /// Select appropriate bucket for message length
        public static func selectBucket(for messageLength: Int) -> PaddingBucket {
            if messageLength + 2 <= PaddingBucket.small.rawValue {
                return .small
            } else if messageLength + 2 <= PaddingBucket.medium.rawValue {
                return .medium
            } else {
                return .large
            }
        }
    }
    
    /// Pad message using bucket-based padding
    public static func pad(_ message: Data, to bucket: PaddingBucket? = nil) throws -> Data {
        let targetBucket = bucket ?? PaddingBucket.selectBucket(for: message.count)
        
        // Check if message fits in target bucket (accounting for 2-byte length prefix)
        guard message.count + 2 <= targetBucket.rawValue else {
            throw MessagePaddingError.messageTooLarge
        }
        
        // Create length prefix (2-byte big-endian)
        let messageLength = UInt16(message.count)
        var lengthBytes = Data(capacity: 2)
        lengthBytes.append(UInt8((messageLength >> 8) & 0xFF))
        lengthBytes.append(UInt8(messageLength & 0xFF))
        
        // Build padded message: len | msg | pad
        var paddedData = Data(capacity: targetBucket.rawValue)
        paddedData.append(lengthBytes)
        paddedData.append(message)
        
        // Add zero padding to reach target bucket size
        let paddingNeeded = targetBucket.rawValue - paddedData.count
        if paddingNeeded > 0 {
            paddedData.append(Data(repeating: 0x00, count: paddingNeeded))
        }
        
        return paddedData
    }
    
    /// Unpad message with constant-time validation
    public static func unpad(_ paddedData: Data) throws -> Data {
        // Minimum size check (2 bytes for length)
        guard paddedData.count >= 2 else {
            throw MessagePaddingError.invalidPadding
        }
        
        // Extract length (2-byte big-endian)
        let lengthByte1 = paddedData[0]
        let lengthByte2 = paddedData[1]
        let messageLength = Int((UInt16(lengthByte1) << 8) | UInt16(lengthByte2))
        
        // Validate length bounds
        guard messageLength >= 0 && messageLength + 2 <= paddedData.count else {
            throw MessagePaddingError.invalidPadding
        }
        
        // Extract message
        let messageEndIndex = 2 + messageLength
        let message = paddedData.subdata(in: 2..<messageEndIndex)
        
        // Validate padding using constant-time comparison
        let paddingStartIndex = messageEndIndex
        let paddingData = paddedData.subdata(in: paddingStartIndex..<paddedData.count)
        
        // Constant-time padding validation
        guard isValidPadding(paddingData) else {
            throw MessagePaddingError.invalidPadding
        }
        
        return message
    }
    
    /// Constant-time padding validation to prevent timing attacks
    private static func isValidPadding(_ padding: Data) -> Bool {
        var result: UInt8 = 0
        
        // XOR all padding bytes - result will be 0 only if all bytes are 0x00
        for byte in padding {
            result |= byte
        }
        
        // Constant-time comparison: result == 0
        return result == 0
    }
}

/// Errors related to message padding operations
public enum MessagePaddingError: Error, Equatable {
    case messageTooLarge
    case invalidPadding
}

// Comprehensive timing analysis
func comprehensiveTimingAnalysis() {
    print("=== Comprehensive Timing Analysis ===")
    
    let message = "Test message for comprehensive timing analysis".data(using: .utf8)!
    
    do {
        let validPaddedData = try MessagePadding.pad(message)
        
        // Create multiple invalid patterns
        var invalidSamples: [Data] = []
        
        // Pattern 1: Single byte corruption at different positions
        for i in 1...20 {
            var corrupted = validPaddedData
            let corruptIndex = corrupted.count - i
            if corruptIndex >= 2 + message.count {
                corrupted[corruptIndex] = 0x01
                invalidSamples.append(corrupted)
            }
        }
        
        // Pattern 2: Multiple byte corruption
        for i in 1...5 {
            var corrupted = validPaddedData
            let startIndex = corrupted.count - (i * 10)
            for j in 0..<i {
                let corruptIndex = startIndex + j
                if corruptIndex >= 2 + message.count && corruptIndex < corrupted.count {
                    corrupted[corruptIndex] = UInt8(j + 1)
                }
            }
            invalidSamples.append(corrupted)
        }
        
        // Pattern 3: Different corruption values
        for value: UInt8 in [0x01, 0xFF, 0x80, 0x7F, 0xAA, 0x55] {
            var corrupted = validPaddedData
            let corruptIndex = corrupted.count - 5
            if corruptIndex >= 2 + message.count {
                corrupted[corruptIndex] = value
                invalidSamples.append(corrupted)
            }
        }
        
        print("Created \(invalidSamples.count) invalid padding samples")
        
        // Warm up
        for _ in 0..<1000 {
            _ = try? MessagePadding.unpad(validPaddedData)
            if let sample = invalidSamples.first {
                _ = try? MessagePadding.unpad(sample)
            }
        }
        
        // Measure valid padding operations
        let validIterations = 10000
        var validTimes: [CFAbsoluteTime] = []
        
        for _ in 0..<validIterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try? MessagePadding.unpad(validPaddedData)
            let endTime = CFAbsoluteTimeGetCurrent()
            validTimes.append(endTime - startTime)
        }
        
        // Measure invalid padding operations
        let invalidIterations = 10000
        var invalidTimes: [CFAbsoluteTime] = []
        
        for _ in 0..<invalidIterations {
            let sample = invalidSamples.randomElement()!
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try? MessagePadding.unpad(sample)
            let endTime = CFAbsoluteTimeGetCurrent()
            invalidTimes.append(endTime - startTime)
        }
        
        // Statistical analysis
        let validAvg = validTimes.reduce(0, +) / Double(validTimes.count)
        let invalidAvg = invalidTimes.reduce(0, +) / Double(invalidTimes.count)
        
        let validSorted = validTimes.sorted()
        let invalidSorted = invalidTimes.sorted()
        
        let validMedian = validSorted[validSorted.count / 2]
        let invalidMedian = invalidSorted[invalidSorted.count / 2]
        
        let validMin = validSorted.first!
        let validMax = validSorted.last!
        let invalidMin = invalidSorted.first!
        let invalidMax = invalidSorted.last!
        
        // Calculate standard deviations
        let validVariance = validTimes.map { pow($0 - validAvg, 2) }.reduce(0, +) / Double(validTimes.count)
        let validStdDev = sqrt(validVariance)
        
        let invalidVariance = invalidTimes.map { pow($0 - invalidAvg, 2) }.reduce(0, +) / Double(invalidTimes.count)
        let invalidStdDev = sqrt(invalidVariance)
        
        print("\n--- Valid Padding Statistics ---")
        print("Average: \(validAvg * 1000000) μs")
        print("Median:  \(validMedian * 1000000) μs")
        print("Min:     \(validMin * 1000000) μs")
        print("Max:     \(validMax * 1000000) μs")
        print("StdDev:  \(validStdDev * 1000000) μs")
        
        print("\n--- Invalid Padding Statistics ---")
        print("Average: \(invalidAvg * 1000000) μs")
        print("Median:  \(invalidMedian * 1000000) μs")
        print("Min:     \(invalidMin * 1000000) μs")
        print("Max:     \(invalidMax * 1000000) μs")
        print("StdDev:  \(invalidStdDev * 1000000) μs")
        
        print("\n--- Timing Analysis ---")
        let avgDifference = abs(validAvg - invalidAvg)
        let medianDifference = abs(validMedian - invalidMedian)
        
        print("Average difference: \(avgDifference * 1000000) μs")
        print("Median difference:  \(medianDifference * 1000000) μs")
        
        // Statistical significance test (simplified)
        let combinedStdDev = sqrt((validVariance + invalidVariance) / 2)
        let tStatistic = abs(validAvg - invalidAvg) / (combinedStdDev * sqrt(2.0 / Double(min(validTimes.count, invalidTimes.count))))
        
        print("T-statistic: \(tStatistic)")
        
        // Evaluation criteria
        let maxAcceptableDifference = 0.000001 // 1 microsecond
        let maxAcceptableTStatistic = 2.0 // Rough threshold for statistical significance
        
        var passed = true
        
        if avgDifference > maxAcceptableDifference {
            print("⚠ Average timing difference exceeds threshold")
            passed = false
        } else {
            print("✓ Average timing difference within acceptable bounds")
        }
        
        if medianDifference > maxAcceptableDifference {
            print("⚠ Median timing difference exceeds threshold")
            passed = false
        } else {
            print("✓ Median timing difference within acceptable bounds")
        }
        
        if tStatistic > maxAcceptableTStatistic {
            print("⚠ T-statistic suggests statistically significant timing difference")
            passed = false
        } else {
            print("✓ T-statistic within acceptable bounds")
        }
        
        if passed {
            print("\n✓ TIMING ANALYSIS PASSED - Implementation appears to be constant-time")
        } else {
            print("\n⚠ TIMING ANALYSIS CONCERNS - Review implementation for timing leaks")
        }
        
    } catch {
        print("✗ Error during timing analysis: \(error)")
    }
}

// Run comprehensive timing analysis
comprehensiveTimingAnalysis()
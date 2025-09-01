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
    
    public var localizedDescription: String {
        switch self {
        case .messageTooLarge:
            return "Message too large for padding bucket"
        case .invalidPadding:
            return "Invalid padding format"
        }
    }
}

// Test functions
func testBasicPadding() {
    print("Testing basic padding...")
    
    let message = "Hello, World!".data(using: .utf8)!
    
    do {
        let paddedData = try MessagePadding.pad(message)
        print("✓ Padded data size: \(paddedData.count) bytes")
        
        let unpaddedMessage = try MessagePadding.unpad(paddedData)
        
        if unpaddedMessage == message {
            print("✓ Round-trip successful")
        } else {
            print("✗ Round-trip failed")
        }
    } catch {
        print("✗ Error: \(error)")
    }
}

func testBucketSelection() {
    print("\nTesting bucket selection...")
    
    let testCases = [
        (0, MessagePadding.PaddingBucket.small),
        (100, MessagePadding.PaddingBucket.small),
        (254, MessagePadding.PaddingBucket.small),
        (255, MessagePadding.PaddingBucket.medium),
        (400, MessagePadding.PaddingBucket.medium),
        (510, MessagePadding.PaddingBucket.medium),
        (511, MessagePadding.PaddingBucket.large),
        (800, MessagePadding.PaddingBucket.large)
    ]
    
    for (size, expected) in testCases {
        let actual = MessagePadding.PaddingBucket.selectBucket(for: size)
        if actual == expected {
            print("✓ Size \(size) -> \(actual)")
        } else {
            print("✗ Size \(size) -> \(actual), expected \(expected)")
        }
    }
}

func testErrorHandling() {
    print("\nTesting error handling...")
    
    // Test message too large
    let largeMessage = Data(repeating: 0x41, count: 1023) // 1023 + 2 = 1025 > 1024
    
    do {
        _ = try MessagePadding.pad(largeMessage)
        print("✗ Should have thrown messageTooLarge error")
    } catch MessagePaddingError.messageTooLarge {
        print("✓ Correctly threw messageTooLarge error")
    } catch {
        print("✗ Unexpected error: \(error)")
    }
    
    // Test invalid padding
    let invalidData = Data([0x00]) // Only 1 byte
    
    do {
        _ = try MessagePadding.unpad(invalidData)
        print("✗ Should have thrown invalidPadding error")
    } catch MessagePaddingError.invalidPadding {
        print("✓ Correctly threw invalidPadding error")
    } catch {
        print("✗ Unexpected error: \(error)")
    }
}

func testPaddingFormat() {
    print("\nTesting padding format...")
    
    let message = "Test message for format validation".data(using: .utf8)!
    
    do {
        let paddedData = try MessagePadding.pad(message)
        
        // Check length prefix (first 2 bytes, big-endian)
        let lengthByte1 = paddedData[0]
        let lengthByte2 = paddedData[1]
        let extractedLength = Int((UInt16(lengthByte1) << 8) | UInt16(lengthByte2))
        
        if extractedLength == message.count {
            print("✓ Length prefix correct: \(extractedLength)")
        } else {
            print("✗ Length prefix incorrect: \(extractedLength), expected \(message.count)")
        }
        
        // Check message content
        let extractedMessage = paddedData.subdata(in: 2..<(2 + message.count))
        if extractedMessage == message {
            print("✓ Message content preserved")
        } else {
            print("✗ Message content corrupted")
        }
        
        // Check padding (all zeros)
        let paddingStart = 2 + message.count
        let padding = paddedData.subdata(in: paddingStart..<paddedData.count)
        var allZeros = true
        for byte in padding {
            if byte != 0x00 {
                allZeros = false
                break
            }
        }
        
        if allZeros {
            print("✓ Padding is all zeros")
        } else {
            print("✗ Padding contains non-zero bytes")
        }
        
    } catch {
        print("✗ Error: \(error)")
    }
}

func testConstantTimePadding() {
    print("\nTesting constant-time padding validation...")
    
    let message = "Timing test message".data(using: .utf8)!
    
    do {
        let validPaddedData = try MessagePadding.pad(message)
        
        // Create invalid padded data with non-zero padding
        var invalidPaddedData = validPaddedData
        invalidPaddedData[invalidPaddedData.count - 10] = 0x01 // Corrupt padding
        
        // Test multiple times to get more stable timing
        let iterations = 1000
        
        // Measure timing for valid padding
        let validStartTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try? MessagePadding.unpad(validPaddedData)
        }
        let validEndTime = CFAbsoluteTimeGetCurrent()
        let validDuration = (validEndTime - validStartTime) / Double(iterations)
        
        // Measure timing for invalid padding
        let invalidStartTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try? MessagePadding.unpad(invalidPaddedData)
        }
        let invalidEndTime = CFAbsoluteTimeGetCurrent()
        let invalidDuration = (invalidEndTime - invalidStartTime) / Double(iterations)
        
        let timingDifference = abs(validDuration - invalidDuration)
        
        print("Valid padding avg time: \(validDuration * 1000000) μs")
        print("Invalid padding avg time: \(invalidDuration * 1000000) μs")
        print("Timing difference: \(timingDifference * 1000000) μs")
        
        if timingDifference < 0.000001 { // 1 microsecond threshold
            print("✓ Timing difference within acceptable bounds")
        } else {
            print("⚠ Timing difference may indicate side-channel leak")
        }
        
    } catch {
        print("✗ Error: \(error)")
    }
}

// Run all tests
print("=== MessagePadding Implementation Tests ===")
testBasicPadding()
testBucketSelection()
testErrorHandling()
testPaddingFormat()
testConstantTimePadding()
print("\n=== Tests Complete ===")
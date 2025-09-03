import XCTest
@testable import WhisperApp

class MessagePaddingTests: XCTestCase {
    
    // MARK: - Basic Padding Tests
    
    func testPaddingSmallMessage() throws {
        let message = "Hello, World!".data(using: .utf8)!
        let paddedData = try MessagePadding.pad(message)
        
        // Should use small bucket (256 bytes)
        XCTAssertEqual(paddedData.count, 256)
        
        // Verify round-trip
        let unpaddedMessage = try MessagePadding.unpad(paddedData)
        XCTAssertEqual(unpaddedMessage, message)
    }
    
    func testPaddingMediumMessage() throws {
        let message = Data(repeating: 0x41, count: 300) // 300 bytes of 'A'
        let paddedData = try MessagePadding.pad(message)
        
        // Should use medium bucket (512 bytes)
        XCTAssertEqual(paddedData.count, 512)
        
        // Verify round-trip
        let unpaddedMessage = try MessagePadding.unpad(paddedData)
        XCTAssertEqual(unpaddedMessage, message)
    }
    
    func testPaddingLargeMessage() throws {
        let message = Data(repeating: 0x42, count: 600) // 600 bytes of 'B'
        let paddedData = try MessagePadding.pad(message)
        
        // Should use large bucket (1024 bytes)
        XCTAssertEqual(paddedData.count, 1024)
        
        // Verify round-trip
        let unpaddedMessage = try MessagePadding.unpad(paddedData)
        XCTAssertEqual(unpaddedMessage, message)
    }
    
    func testEmptyMessage() throws {
        let message = Data()
        let paddedData = try MessagePadding.pad(message)
        
        // Should use small bucket (256 bytes)
        XCTAssertEqual(paddedData.count, 256)
        
        // Verify round-trip
        let unpaddedMessage = try MessagePadding.unpad(paddedData)
        XCTAssertEqual(unpaddedMessage, message)
    }
    
    // MARK: - Bucket Selection Tests
    
    func testBucketSelection() {
        XCTAssertEqual(MessagePadding.PaddingBucket.selectBucket(for: 0), .small)
        XCTAssertEqual(MessagePadding.PaddingBucket.selectBucket(for: 100), .small)
        XCTAssertEqual(MessagePadding.PaddingBucket.selectBucket(for: 254), .small) // 254 + 2 = 256
        XCTAssertEqual(MessagePadding.PaddingBucket.selectBucket(for: 255), .medium) // 255 + 2 = 257 > 256
        XCTAssertEqual(MessagePadding.PaddingBucket.selectBucket(for: 400), .medium)
        XCTAssertEqual(MessagePadding.PaddingBucket.selectBucket(for: 510), .medium) // 510 + 2 = 512
        XCTAssertEqual(MessagePadding.PaddingBucket.selectBucket(for: 511), .large) // 511 + 2 = 513 > 512
        XCTAssertEqual(MessagePadding.PaddingBucket.selectBucket(for: 800), .large)
    }
    
    func testExplicitBucketSelection() throws {
        let message = "Small message".data(using: .utf8)!
        
        // Force small bucket
        let smallPadded = try MessagePadding.pad(message, to: .small)
        XCTAssertEqual(smallPadded.count, 256)
        
        // Force medium bucket
        let mediumPadded = try MessagePadding.pad(message, to: .medium)
        XCTAssertEqual(mediumPadded.count, 512)
        
        // Force large bucket
        let largePadded = try MessagePadding.pad(message, to: .large)
        XCTAssertEqual(largePadded.count, 1024)
        
        // All should unpad to same message
        XCTAssertEqual(try MessagePadding.unpad(smallPadded), message)
        XCTAssertEqual(try MessagePadding.unpad(mediumPadded), message)
        XCTAssertEqual(try MessagePadding.unpad(largePadded), message)
    }
    
    // MARK: - Error Handling Tests
    
    func testMessageTooLarge() {
        let message = Data(repeating: 0x43, count: 1023) // 1023 + 2 = 1025 > 1024
        
        XCTAssertThrowsError(try MessagePadding.pad(message)) { error in
            XCTAssertEqual(error as? MessagePaddingError, .messageTooLarge)
        }
        
        // Also test explicit bucket that's too small
        let mediumMessage = Data(repeating: 0x44, count: 511) // 511 + 2 = 513 > 512
        XCTAssertThrowsError(try MessagePadding.pad(mediumMessage, to: .medium)) { error in
            XCTAssertEqual(error as? MessagePaddingError, .messageTooLarge)
        }
    }
    
    func testInvalidPaddingTooShort() {
        let invalidData = Data([0x00]) // Only 1 byte, need at least 2
        
        XCTAssertThrowsError(try MessagePadding.unpad(invalidData)) { error in
            XCTAssertEqual(error as? MessagePaddingError, .invalidPadding)
        }
    }
    
    func testInvalidPaddingLengthTooLarge() {
        var invalidData = Data()
        invalidData.append(0xFF) // Length = 65535 (way too large)
        invalidData.append(0xFF)
        invalidData.append(contentsOf: Data(repeating: 0x00, count: 254))
        
        XCTAssertThrowsError(try MessagePadding.unpad(invalidData)) { error in
            XCTAssertEqual(error as? MessagePaddingError, .invalidPadding)
        }
    }
    
    func testInvalidPaddingNonZeroPadding() {
        // Create valid structure but with non-zero padding
        let message = "test".data(using: .utf8)!
        var paddedData = try! MessagePadding.pad(message)
        
        // Corrupt the padding by setting a non-zero byte
        paddedData[paddedData.count - 1] = 0x01
        
        XCTAssertThrowsError(try MessagePadding.unpad(paddedData)) { error in
            XCTAssertEqual(error as? MessagePaddingError, .invalidPadding)
        }
    }
    
    // MARK: - Format Validation Tests
    
    func testPaddingFormat() throws {
        let message = "Test message for format validation".data(using: .utf8)!
        let paddedData = try MessagePadding.pad(message)
        
        // Check length prefix (first 2 bytes, big-endian)
        let lengthByte1 = paddedData[0]
        let lengthByte2 = paddedData[1]
        let extractedLength = Int((UInt16(lengthByte1) << 8) | UInt16(lengthByte2))
        
        XCTAssertEqual(extractedLength, message.count)
        
        // Check message content
        let extractedMessage = paddedData.subdata(in: 2..<(2 + message.count))
        XCTAssertEqual(extractedMessage, message)
        
        // Check padding (all zeros)
        let paddingStart = 2 + message.count
        let padding = paddedData.subdata(in: paddingStart..<paddedData.count)
        for byte in padding {
            XCTAssertEqual(byte, 0x00)
        }
    }
    
    func testBigEndianLengthEncoding() throws {
        // Test various message lengths to ensure proper big-endian encoding
        let testLengths = [0, 1, 255, 256, 257, 65535]
        
        for length in testLengths {
            guard length <= 1022 else { continue } // Skip lengths that won't fit in large bucket
            
            let message = Data(repeating: 0x55, count: length)
            let paddedData = try MessagePadding.pad(message)
            
            // Extract length from padded data
            let lengthByte1 = paddedData[0]
            let lengthByte2 = paddedData[1]
            let extractedLength = Int((UInt16(lengthByte1) << 8) | UInt16(lengthByte2))
            
            XCTAssertEqual(extractedLength, length, "Length encoding failed for length \(length)")
            
            // Verify round-trip
            let unpaddedMessage = try MessagePadding.unpad(paddedData)
            XCTAssertEqual(unpaddedMessage, message)
        }
    }
    
    // MARK: - Constant-Time Validation Tests
    
    func testConstantTimePaddingValidation() throws {
        let message = "Timing test message".data(using: .utf8)!
        let validPaddedData = try MessagePadding.pad(message)
        
        // Create invalid padded data with non-zero padding
        var invalidPaddedData = validPaddedData
        invalidPaddedData[invalidPaddedData.count - 10] = 0x01 // Corrupt padding
        
        // Measure timing for valid padding
        let validStartTime = CFAbsoluteTimeGetCurrent()
        _ = try? MessagePadding.unpad(validPaddedData)
        let validEndTime = CFAbsoluteTimeGetCurrent()
        let validDuration = validEndTime - validStartTime
        
        // Measure timing for invalid padding
        let invalidStartTime = CFAbsoluteTimeGetCurrent()
        _ = try? MessagePadding.unpad(invalidPaddedData)
        let invalidEndTime = CFAbsoluteTimeGetCurrent()
        let invalidDuration = invalidEndTime - invalidStartTime
        
        // The timing difference should be minimal (within reasonable bounds)
        // This is a basic timing test - in practice, more sophisticated timing analysis would be needed
        let timingDifference = abs(validDuration - invalidDuration)
        XCTAssertLessThan(timingDifference, 0.001, "Significant timing difference detected: \(timingDifference)s")
    }
    
    func testConstantTimePaddingValidationMultipleSamples() throws {
        let message = "Constant time test".data(using: .utf8)!
        let validPaddedData = try MessagePadding.pad(message)
        
        // Create multiple invalid padded data samples
        var invalidSamples: [Data] = []
        for i in 1...10 {
            var invalidData = validPaddedData
            invalidData[invalidData.count - i] = UInt8(i) // Different corruption patterns
            invalidSamples.append(invalidData)
        }
        
        // Measure timing for multiple valid operations
        var validTimes: [CFAbsoluteTime] = []
        for _ in 0..<100 {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try? MessagePadding.unpad(validPaddedData)
            let endTime = CFAbsoluteTimeGetCurrent()
            validTimes.append(endTime - startTime)
        }
        
        // Measure timing for multiple invalid operations
        var invalidTimes: [CFAbsoluteTime] = []
        for _ in 0..<100 {
            let sample = invalidSamples.randomElement()!
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try? MessagePadding.unpad(sample)
            let endTime = CFAbsoluteTimeGetCurrent()
            invalidTimes.append(endTime - startTime)
        }
        
        // Calculate averages
        let avgValidTime = validTimes.reduce(0, +) / Double(validTimes.count)
        let avgInvalidTime = invalidTimes.reduce(0, +) / Double(invalidTimes.count)
        
        let timingDifference = abs(avgValidTime - avgInvalidTime)
        XCTAssertLessThan(timingDifference, 0.0001, "Average timing difference too large: \(timingDifference)s")
    }
    
    // MARK: - Edge Case Tests
    
    func testMaximumValidMessageSizes() throws {
        // Test maximum message size for each bucket
        let maxSmall = Data(repeating: 0x61, count: 254) // 254 + 2 = 256
        let maxMedium = Data(repeating: 0x62, count: 510) // 510 + 2 = 512
        let maxLarge = Data(repeating: 0x63, count: 1022) // 1022 + 2 = 1024
        
        // All should succeed
        let paddedSmall = try MessagePadding.pad(maxSmall)
        let paddedMedium = try MessagePadding.pad(maxMedium)
        let paddedLarge = try MessagePadding.pad(maxLarge)
        
        XCTAssertEqual(paddedSmall.count, 256)
        XCTAssertEqual(paddedMedium.count, 512)
        XCTAssertEqual(paddedLarge.count, 1024)
        
        // Verify round-trips
        XCTAssertEqual(try MessagePadding.unpad(paddedSmall), maxSmall)
        XCTAssertEqual(try MessagePadding.unpad(paddedMedium), maxMedium)
        XCTAssertEqual(try MessagePadding.unpad(paddedLarge), maxLarge)
    }
    
    func testRandomMessageSizes() throws {
        // Test various random message sizes
        for _ in 0..<50 {
            let randomSize = Int.random(in: 0...1000)
            guard randomSize <= 1022 else { continue } // Skip if too large
            
            let message = Data((0..<randomSize).map { _ in UInt8.random(in: 0...255) })
            
            do {
                let paddedData = try MessagePadding.pad(message)
                let unpaddedMessage = try MessagePadding.unpad(paddedData)
                XCTAssertEqual(unpaddedMessage, message, "Round-trip failed for size \(randomSize)")
            } catch {
                XCTFail("Padding failed for valid size \(randomSize): \(error)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testPaddingPerformance() {
        let message = Data(repeating: 0x70, count: 500)
        
        measure {
            for _ in 0..<1000 {
                _ = try! MessagePadding.pad(message)
            }
        }
    }
    
    func testUnpaddingPerformance() {
        let message = Data(repeating: 0x71, count: 500)
        let paddedData = try! MessagePadding.pad(message)
        
        measure {
            for _ in 0..<1000 {
                _ = try! MessagePadding.unpad(paddedData)
            }
        }
    }
}
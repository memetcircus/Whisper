import Foundation

/// Utility for message padding and length hiding using bucket-based padding
/// Implements padding format: len(2-byte big-endian) | msg | pad(0x00)
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
    /// - Parameters:
    ///   - message: Original message data
    ///   - bucket: Target padding bucket (optional, auto-selected if nil)
    /// - Returns: Padded message data
    /// - Throws: MessagePaddingError if message is too large
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
    /// - Parameter paddedData: Padded message data
    /// - Returns: Original message data
    /// - Throws: MessagePaddingError for invalid padding
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
    /// - Parameter padding: Padding bytes to validate
    /// - Returns: true if all padding bytes are 0x00
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
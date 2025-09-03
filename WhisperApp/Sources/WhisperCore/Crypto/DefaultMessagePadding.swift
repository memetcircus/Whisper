import Foundation

/// Default implementation of MessagePadding protocol
/// Provides bucket-based padding (256/512/1024 bytes) with constant-time validation
class DefaultMessagePadding: MessagePadding {
    
    /// Padding buckets for message length hiding
    enum PaddingBucket: Int {
        case small = 256
        case medium = 512
        case large = 1024
        
        static func selectBucket(for messageLength: Int) -> PaddingBucket {
            if messageLength <= 254 { return .small }    // 256 - 2 bytes for length
            if messageLength <= 510 { return .medium }   // 512 - 2 bytes for length
            return .large                                // 1024 - 2 bytes for length
        }
    }
    
    func pad(_ data: Data) -> Data {
        let bucket = PaddingBucket.selectBucket(for: data.count)
        return pad(data, to: bucket)
    }
    
    func unpad(_ paddedData: Data) throws -> Data {
        guard paddedData.count >= 2 else {
            throw WhisperError.invalidPadding
        }
        
        // Extract length (2-byte big-endian)
        let lengthBytes = paddedData.prefix(2)
        let messageLength = Int(UInt16(bigEndian: lengthBytes.withUnsafeBytes { $0.load(as: UInt16.self) }))
        
        guard messageLength + 2 <= paddedData.count else {
            throw WhisperError.invalidPadding
        }
        
        // Extract message
        let message = paddedData.subdata(in: 2..<(2 + messageLength))
        
        // Extract and validate padding using constant-time comparison
        let padding = paddedData.suffix(from: 2 + messageLength)
        
        // Constant-time padding validation to prevent timing attacks
        var paddingValid = true
        for byte in padding {
            paddingValid = paddingValid && (byte == 0x00)
        }
        
        guard paddingValid else {
            throw WhisperError.invalidPadding
        }
        
        return message
    }
    
    // MARK: - Private Helper Methods
    
    private func pad(_ message: Data, to bucket: PaddingBucket) -> Data {
        let targetSize = bucket.rawValue
        
        // Format: len(2-byte big-endian) | msg | pad(0x00)
        let length = UInt16(message.count).bigEndian
        var padded = Data()
        
        // Add length prefix
        padded.append(Data(bytes: &length, count: 2))
        
        // Add message
        padded.append(message)
        
        // Add zero padding to reach target size
        let paddingNeeded = targetSize - padded.count
        if paddingNeeded > 0 {
            padded.append(Data(repeating: 0x00, count: paddingNeeded))
        }
        
        return padded
    }
}
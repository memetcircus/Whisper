import Foundation

// MARK: - Base32 Crockford Encoding

extension Data {
    func base32CrockfordEncoded() -> String {
        let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        let alphabetArray = Array(alphabet)
        
        var result = ""
        var buffer: UInt64 = 0
        var bitsInBuffer = 0
        
        for byte in self {
            buffer = (buffer << 8) | UInt64(byte)
            bitsInBuffer += 8
            
            while bitsInBuffer >= 5 {
                let index = Int((buffer >> (bitsInBuffer - 5)) & 0x1F)
                result.append(alphabetArray[index])
                bitsInBuffer -= 5
            }
        }
        
        // Handle remaining bits
        if bitsInBuffer > 0 {
            let index = Int((buffer << (5 - bitsInBuffer)) & 0x1F)
            result.append(alphabetArray[index])
        }
        
        return result
    }
    
    init?(base32CrockfordEncoded string: String) {
        let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        let charToValue: [Character: UInt8] = {
            var dict: [Character: UInt8] = [:]
            for (index, char) in alphabet.enumerated() {
                dict[char] = UInt8(index)
            }
            // Add lowercase support
            for (index, char) in alphabet.lowercased().enumerated() {
                dict[char] = UInt8(index)
            }
            // Add common substitutions
            dict["O"] = 0  // O -> 0
            dict["o"] = 0  // o -> 0
            dict["I"] = 1  // I -> 1
            dict["i"] = 1  // i -> 1
            dict["L"] = 1  // L -> 1
            dict["l"] = 1  // l -> 1
            return dict
        }()
        
        var buffer: UInt64 = 0
        var bitsInBuffer = 0
        var result = Data()
        
        for char in string {
            guard let value = charToValue[char] else {
                return nil // Invalid character
            }
            
            buffer = (buffer << 5) | UInt64(value)
            bitsInBuffer += 5
            
            while bitsInBuffer >= 8 {
                let byte = UInt8((buffer >> (bitsInBuffer - 8)) & 0xFF)
                result.append(byte)
                bitsInBuffer -= 8
            }
        }
        
        self = result
    }
}
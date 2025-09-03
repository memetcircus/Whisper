import Foundation
import CoreImage
import UIKit
import AVFoundation

/// Service for generating and scanning QR codes for Whisper app
/// Handles public key bundles and encrypted message QR codes with size validation
class QRCodeService: ObservableObject {
    
    // MARK: - Constants
    
    /// Maximum recommended QR code size for reliable scanning (900 bytes)
    /// This corresponds to QR version 15 with error correction level M
    static let maxRecommendedSize = 900
    
    /// QR code error correction level M (15% error correction)
    private let errorCorrectionLevel = "M"
    
    // MARK: - QR Code Generation
    
    /// Generates QR code for a public key bundle
    /// - Parameter bundle: Public key bundle to encode
    /// - Returns: QR code generation result with image and size warning if needed
    /// - Throws: QRCodeError if generation fails
    func generateQRCode(for bundle: PublicKeyBundle) throws -> QRCodeResult {
        let bundleData = try JSONEncoder().encode(bundle)
        let bundleString = bundleData.base64EncodedString()
        
        // Add whisper-bundle: prefix for identification
        let qrContent = "whisper-bundle:\(bundleString)"
        
        return try generateQRCodeImage(from: qrContent, type: .publicKeyBundle)
    }
    
    /// Generates QR code for an encrypted message envelope
    /// - Parameter envelope: Encrypted message envelope string
    /// - Returns: QR code generation result with image and size warning if needed
    /// - Throws: QRCodeError if generation fails
    func generateQRCode(for envelope: String) throws -> QRCodeResult {
        // Validate envelope format
        guard envelope.hasPrefix("whisper1:") else {
            throw QRCodeError.invalidEnvelopeFormat
        }
        
        return try generateQRCodeImage(from: envelope, type: .encryptedMessage)
    }
    
    /// Generates QR code for contact sharing (public key bundle from contact)
    /// - Parameter contact: Contact to share
    /// - Returns: QR code generation result with image and size warning if needed
    /// - Throws: QRCodeError if generation fails
    func generateQRCode(for contact: Contact) throws -> QRCodeResult {
        let bundle = PublicKeyBundle(from: contact)
        return try generateQRCode(for: bundle)
    }
    
    // MARK: - QR Code Scanning
    
    /// Parses scanned QR code content and determines type
    /// - Parameter content: Raw QR code content string
    /// - Returns: Parsed QR code content with type identification
    /// - Throws: QRCodeError if content is invalid or unsupported
    func parseQRCode(_ content: String) throws -> QRCodeContent {
        if content.hasPrefix("whisper-bundle:") {
            return try parsePublicKeyBundle(content)
        } else if content.hasPrefix("whisper1:") {
            return try parseEncryptedMessage(content)
        } else {
            throw QRCodeError.unsupportedFormat
        }
    }
    
    // MARK: - Private Implementation
    
    private func generateQRCodeImage(from content: String, type: QRCodeType) throws -> QRCodeResult {
        // Check content size and warn if too large
        let contentData = content.data(using: .utf8) ?? Data()
        let sizeWarning = contentData.count > Self.maxRecommendedSize ? 
            QRCodeSizeWarning(
                actualSize: contentData.count,
                recommendedSize: Self.maxRecommendedSize,
                message: "QR code may be difficult to scan reliably. Consider sharing as text instead."
            ) : nil
        
        // Generate QR code using Core Image
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRCodeError.generationFailed("QR code filter not available")
        }
        
        filter.setValue(contentData, forKey: "inputMessage")
        filter.setValue(errorCorrectionLevel, forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else {
            throw QRCodeError.generationFailed("Failed to generate QR code image")
        }
        
        // Scale up the image for better quality
        let scaleX = 200.0 / ciImage.extent.width
        let scaleY = 200.0 / ciImage.extent.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            throw QRCodeError.generationFailed("Failed to create CGImage")
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        return QRCodeResult(
            image: uiImage,
            content: content,
            type: type,
            sizeWarning: sizeWarning
        )
    }
    
    private func parsePublicKeyBundle(_ content: String) throws -> QRCodeContent {
        // Remove prefix and decode
        let bundleString = String(content.dropFirst("whisper-bundle:".count))
        
        guard let bundleData = Data(base64Encoded: bundleString) else {
            throw QRCodeError.invalidBundleData
        }
        
        do {
            let bundle = try JSONDecoder().decode(PublicKeyBundle.self, from: bundleData)
            return .publicKeyBundle(bundle)
        } catch {
            throw QRCodeError.invalidBundleFormat(error)
        }
    }
    
    private func parseEncryptedMessage(_ content: String) throws -> QRCodeContent {
        // Validate envelope format (basic validation)
        let components = content.components(separatedBy: ".")
        guard components.count >= 8 && components.count <= 9 else {
            throw QRCodeError.invalidEnvelopeFormat
        }
        
        return .encryptedMessage(content)
    }
}

// MARK: - Supporting Types

/// Result of QR code generation
struct QRCodeResult {
    let image: UIImage
    let content: String
    let type: QRCodeType
    let sizeWarning: QRCodeSizeWarning?
}

/// Warning about QR code size exceeding recommended limits
struct QRCodeSizeWarning {
    let actualSize: Int
    let recommendedSize: Int
    let message: String
}

/// Type of QR code content
enum QRCodeType {
    case publicKeyBundle
    case encryptedMessage
    
    var displayName: String {
        switch self {
        case .publicKeyBundle:
            return "Public Key Bundle"
        case .encryptedMessage:
            return "Encrypted Message"
        }
    }
}

/// Parsed QR code content
enum QRCodeContent {
    case publicKeyBundle(PublicKeyBundle)
    case encryptedMessage(String)
    
    var type: QRCodeType {
        switch self {
        case .publicKeyBundle:
            return .publicKeyBundle
        case .encryptedMessage:
            return .encryptedMessage
        }
    }
}

/// QR code related errors
enum QRCodeError: Error, LocalizedError {
    case generationFailed(String)
    case invalidEnvelopeFormat
    case invalidBundleData
    case invalidBundleFormat(Error)
    case unsupportedFormat
    case scanningNotAvailable
    case cameraPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .generationFailed(let reason):
            return "QR code generation failed: \(reason)"
        case .invalidEnvelopeFormat:
            return "Invalid envelope format"
        case .invalidBundleData:
            return "Invalid bundle data"
        case .invalidBundleFormat(let error):
            return "Invalid bundle format: \(error.localizedDescription)"
        case .unsupportedFormat:
            return "Unsupported QR code format"
        case .scanningNotAvailable:
            return "QR code scanning not available"
        case .cameraPermissionDenied:
            return "Camera permission denied"
        }
    }
}

// MARK: - Camera Permission Helper

extension QRCodeService {
    
    /// Checks camera permission status for QR scanning
    /// - Returns: Current camera authorization status
    func checkCameraPermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// Requests camera permission for QR scanning
    /// - Parameter completion: Completion handler with permission result
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}
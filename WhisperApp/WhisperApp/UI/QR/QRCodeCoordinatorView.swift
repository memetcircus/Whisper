import SwiftUI

/// Coordinator view that manages QR code scanning and processing flow
struct QRCodeCoordinatorView: View {
    
    @StateObject private var qrService = QRCodeService()
    @State private var showingScanner = false
    @State private var showingContactPreview = false
    @State private var showingDecryptView = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var scannedContent: QRCodeContent?
    
    let onContactAdded: (PublicKeyBundle) -> Void
    let onMessageDecrypted: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            // This view acts as a coordinator and doesn't have its own UI
            // It manages the presentation of other views
        }
        .onAppear {
            checkCameraPermissionAndScan()
        }
        .sheet(isPresented: $showingScanner) {
            QRScannerView(
                isPresented: $showingScanner,
                onCodeScanned: handleScannedCode,
                onError: handleScanError
            )
        }
        .sheet(isPresented: $showingContactPreview) {
            if case .publicKeyBundle(let bundle) = scannedContent {
                ContactPreviewView(
                    bundle: bundle,
                    onAdd: handleContactAdd,
                    onCancel: handleContactPreviewCancel
                )
            }
        }
        .sheet(isPresented: $showingDecryptView) {
            if case .encryptedMessage(let envelope) = scannedContent {
                DecryptFromQRView(
                    envelope: envelope,
                    onDecrypted: handleMessageDecrypted,
                    onCancel: handleDecryptCancel
                )
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("Retry") {
                checkCameraPermissionAndScan()
            }
            Button("Cancel") {
                onDismiss()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Camera Permission and Scanning
    
    private func checkCameraPermissionAndScan() {
        let permission = qrService.checkCameraPermission()
        
        switch permission {
        case .authorized:
            showingScanner = true
        case .notDetermined:
            qrService.requestCameraPermission { granted in
                if granted {
                    showingScanner = true
                } else {
                    showCameraPermissionError()
                }
            }
        case .denied, .restricted:
            showCameraPermissionError()
        @unknown default:
            showCameraPermissionError()
        }
    }
    
    private func showCameraPermissionError() {
        errorMessage = "Camera access is required to scan QR codes. Please enable camera access in Settings."
        showingError = true
    }
    
    // MARK: - QR Code Handling
    
    private func handleScannedCode(_ code: String) {
        do {
            let content = try qrService.parseQRCode(code)
            scannedContent = content
            
            switch content {
            case .publicKeyBundle:
                showingContactPreview = true
            case .encryptedMessage:
                showingDecryptView = true
            }
        } catch {
            handleScanError(error as? QRCodeError ?? .unsupportedFormat)
        }
    }
    
    private func handleScanError(_ error: QRCodeError) {
        errorMessage = error.localizedDescription
        showingError = true
    }
    
    // MARK: - Contact Preview Handling
    
    private func handleContactAdd(_ bundle: PublicKeyBundle) {
        showingContactPreview = false
        onContactAdded(bundle)
    }
    
    private func handleContactPreviewCancel() {
        showingContactPreview = false
        onDismiss()
    }
    
    // MARK: - Decrypt Handling
    
    private func handleMessageDecrypted(_ message: String) {
        showingDecryptView = false
        onMessageDecrypted(message)
    }
    
    private func handleDecryptCancel() {
        showingDecryptView = false
        onDismiss()
    }
}

// MARK: - Decrypt from QR View

private struct DecryptFromQRView: View {
    let envelope: String
    let onDecrypted: (String) -> Void
    let onCancel: () -> Void
    
    @State private var isDecrypting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Encrypted Message")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("This QR code contains an encrypted message")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Envelope Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Envelope Content")
                        .font(.headline)
                    
                    ScrollView {
                        Text(envelope)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 120)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: decryptMessage) {
                        HStack {
                            if isDecrypting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "lock.open")
                            }
                            Text(isDecrypting ? "Decrypting..." : "Decrypt Message")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isDecrypting)
                    
                    Button(action: onCancel) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Cancel")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isDecrypting)
                }
            }
            .padding()
            .navigationTitle("Decrypt Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isDecrypting)
                }
            }
        }
        .alert("Decryption Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func decryptMessage() {
        isDecrypting = true
        
        // Simulate decryption process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // In a real implementation, this would call the WhisperService
            // For now, we'll simulate success
            onDecrypted("Decrypted message content would appear here")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct QRCodeCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeCoordinatorView(
            onContactAdded: { _ in },
            onMessageDecrypted: { _ in },
            onDismiss: { }
        )
    }
}
#endif
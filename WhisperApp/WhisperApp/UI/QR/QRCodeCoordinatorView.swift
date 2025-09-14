import AVFoundation
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
    @State private var successfulScan = false

    let onContactAdded: (PublicKeyBundle) -> Void
    let onMessageDecrypted: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            // This view acts as a coordinator and doesn't have its own UI
            // It manages the presentation of other views
            if showingScanner || showingContactPreview || showingDecryptView {
                // Hide loading when showing other views
                EmptyView()
            } else {
                Text("Loading...")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            checkCameraPermissionAndScan()
        }
        .sheet(
            isPresented: $showingScanner,
            onDismiss: {
                print("🔍 QR_COORDINATOR: Scanner sheet dismissed")
                print("🔍 QR_COORDINATOR: showingContactPreview = \(showingContactPreview)")
                print("🔍 QR_COORDINATOR: showingDecryptView = \(showingDecryptView)")
                print("🔍 QR_COORDINATOR: successfulScan = \(successfulScan)")

                // Only dismiss the coordinator if:
                // 1. No other views are showing AND
                // 2. There was no successful scan (user cancelled or error occurred)
                if !showingContactPreview && !showingDecryptView && !successfulScan {
                    print(
                        "🔍 QR_COORDINATOR: Calling onDismiss() - user cancelled or error occurred")
                    onDismiss()
                } else {
                    print(
                        "🔍 QR_COORDINATOR: NOT calling onDismiss() - successful scan or other views showing"
                    )
                }
            }
        ) {
            QRScannerView(
                isPresented: $showingScanner,
                onCodeScanned: handleScannedCode,
                onError: handleScanError
            )
        }
        .sheet(isPresented: $showingContactPreview) {
            if case .publicKeyBundle(let bundle) = scannedContent {
                ContactPreviewView(
                    bundle: ContactBundle(
                        displayName: bundle.name,
                        x25519PublicKey: bundle.x25519PublicKey,
                        ed25519PublicKey: bundle.ed25519PublicKey,
                        fingerprint: bundle.fingerprint,
                        keyVersion: bundle.keyVersion,
                        createdAt: bundle.createdAt
                    ),
                    onAdd: { contactBundle in
                        // Convert ContactBundle back to PublicKeyBundle for the callback
                        let publicKeyBundle = PublicKeyBundle(
                            id: bundle.id,
                            name: contactBundle.displayName,
                            x25519PublicKey: contactBundle.x25519PublicKey,
                            ed25519PublicKey: contactBundle.ed25519PublicKey,
                            fingerprint: contactBundle.fingerprint,
                            keyVersion: contactBundle.keyVersion,
                            createdAt: contactBundle.createdAt
                        )
                        handleContactAdd(publicKeyBundle)
                    },
                    onCancel: handleContactPreviewCancel
                )
            }
        }
        // DecryptFromQRView sheet removed - decrypt workflow now handled by parent DecryptView
        .alert("Error", isPresented: $showingError) {
            Button("Retry") {
                showingError = false
                checkCameraPermissionAndScan()
            }
            Button("Cancel") {
                showingError = false
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
            successfulScan = false  // Reset flag when starting new scan
            showingScanner = true
        case .notDetermined:
            qrService.requestCameraPermission { granted in
                if granted {
                    successfulScan = false  // Reset flag when starting new scan
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
        errorMessage =
            "Camera access is required to scan QR codes. Please enable camera access in Settings."
        showingError = true
    }

    // MARK: - QR Code Handling

    private func handleScannedCode(_ code: String) {
        print("🔍 QR_COORDINATOR: handleScannedCode called")
        showingScanner = false  // Close scanner first
        print("🔍 QR_COORDINATOR: Set showingScanner = false")

        do {
            let content = try qrService.parseQRCode(code)
            scannedContent = content

            switch content {
            case .publicKeyBundle:
                print("🔍 QR_COORDINATOR: Found public key bundle, showing contact preview")
                successfulScan = true
                showingContactPreview = true
            case .encryptedMessage(let envelope):
                print("🔍 QR_COORDINATOR: Found encrypted message, calling onMessageDecrypted")
                successfulScan = true
                // For decrypt workflow, call the callback directly instead of showing DecryptFromQRView
                onMessageDecrypted(envelope)
                print("🔍 QR_COORDINATOR: onMessageDecrypted called, NOT auto-dismissing")
            // Don't auto-dismiss - let the decrypt view handle the result
            }
        } catch {
            handleScanError(error as? QRCodeError ?? .unsupportedFormat)
        }
    }

    private func handleScanError(_ error: QRCodeError) {
        showingScanner = false
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
    // Decrypt handling now done directly in handleScannedCode for decrypt workflow
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
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isDecrypting)
                }
            }
        }
        .alert("Decryption Error", isPresented: $showingError) {
            Button("OK") {}
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
                onDismiss: {}
            )
        }
    }
#endif

import AVFoundation
import PhotosUI
import SwiftUI
import Vision

// MARK: - Add Contact View

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddContactViewModel()

    let onContactAdded: (Contact) -> Void

    var body: some View {
        NavigationView {
            // QR Code only - secure contact addition
            AddContactQRScannerView(
                viewModel: viewModel,
                onContactAdded: onContactAdded,
                onDismiss: { dismiss() }
            )
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Contact QR Scanner View

struct AddContactQRScannerView: View {
    @ObservedObject var viewModel: AddContactViewModel
    let onContactAdded: (Contact) -> Void
    let onDismiss: () -> Void
    @State private var showingQRCoordinator = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("Add Contact Securely")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                Text("Scan a QR code or import from photos to add a contact.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(
                    "🔒 QR codes ensure cryptographic key integrity and prevent manual entry errors."
                )
                .font(.caption)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Action buttons
            HStack(spacing: 16) {
                Button(action: { showingQRCoordinator = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.title2)
                        Text("Scan Camera")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.title2)
                        Text("From Photos")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            // Security notice
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(.green)
                    Text("Secure Contact Exchange")
                        .font(.headline)
                        .foregroundColor(.green)
                }

                Text(
                    "QR codes contain cryptographically signed contact information that prevents tampering and ensures authenticity."
                )
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingQRCoordinator) {
            DirectContactAddQRView(
                onContactAdded: { contact in
                    onContactAdded(contact)
                    showingQRCoordinator = false
                    onDismiss()  // Close the entire AddContactView
                },
                onDismiss: {
                    showingQRCoordinator = false
                }
            )
        }
        .onChange(of: selectedPhoto) { newPhoto in
            if let newPhoto = newPhoto {
                processSelectedPhoto(newPhoto)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Photo Processing

    private func processSelectedPhoto(_ photoItem: PhotosPickerItem) {
        Task {
            do {
                guard let imageData = try await photoItem.loadTransferable(type: Data.self),
                    let uiImage = UIImage(data: imageData)
                else {
                    await MainActor.run {
                        showError("Failed to load selected image")
                    }
                    return
                }

                let qrCodes = try await detectQRCodes(in: uiImage)

                await MainActor.run {
                    if let qrCode = qrCodes.first {
                        processQRCodeString(qrCode)
                    } else {
                        showError("No QR code found in the selected image")
                    }
                }
            } catch {
                await MainActor.run {
                    showError("Failed to process image: \(error.localizedDescription)")
                }
            }
        }
    }

    private func detectQRCodes(in image: UIImage) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: QRDetectionError.invalidImage)
                return
            }

            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let qrCodes =
                    request.results?
                    .compactMap { $0 as? VNBarcodeObservation }
                    .filter { $0.symbology == .qr }
                    .compactMap { $0.payloadStringValue } ?? []

                continuation.resume(returning: qrCodes)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func processQRCodeString(_ qrString: String) {
        do {
            let qrService = QRCodeService()
            let content = try qrService.parseQRCode(qrString)

            switch content {
            case .publicKeyBundle(let bundle):
                // Create contact directly from the bundle
                let contact = Contact(from: bundle)
                onContactAdded(contact)
                onDismiss()
            case .encryptedMessage:
                showError("This QR code contains an encrypted message, not a contact.")
            }
        } catch {
            showError("Invalid QR code: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - QR Detection Error

enum QRDetectionError: Error, LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        }
    }
}

// MARK: - Add Contact Preview View

struct AddContactPreviewView: View {
    @ObservedObject var viewModel: AddContactViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Preview")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    ContactAvatarView(contact: previewContact)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.displayName)
                            .font(.headline)

                        Text("ID: \(viewModel.shortFingerprint)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    TrustBadgeView(trustLevel: .unverified)
                }

                // Fingerprint
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fingerprint:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(viewModel.fingerprintDisplay)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                // SAS words
                if !viewModel.sasWords.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SAS Words:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(viewModel.sasWords.joined(separator: " • "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }

    private var previewContact: Contact {
        // Create a temporary contact for preview
        do {
            return try Contact(
                displayName: viewModel.displayName.isEmpty ? "New Contact" : viewModel.displayName,
                x25519PublicKey: viewModel.x25519PublicKey ?? Data(repeating: 0, count: 32),
                ed25519PublicKey: viewModel.ed25519PublicKey,
                note: viewModel.note.isEmpty ? nil : viewModel.note
            )
        } catch {
            // Fallback contact
            return try! Contact(
                displayName: "Preview Error",
                x25519PublicKey: Data(repeating: 0, count: 32)
            )
        }
    }
}

// MARK: - QR Code Scanner View

struct QRCodeScannerView: View {
    let onCodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            QRScannerRepresentable(onCodeScanned: onCodeScanned)
        }
        .navigationTitle("Scan QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - QR Scanner UIKit Wrapper

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> AddContactQRScannerViewController {
        let scanner = AddContactQRScannerViewController()
        scanner.onCodeScanned = onCodeScanned
        return scanner
    }

    func updateUIViewController(
        _ uiViewController: AddContactQRScannerViewController, context: Context
    ) {
        // No updates needed
    }
}

class AddContactQRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                return
            }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onCodeScanned?(stringValue)
        }
    }
}

// MARK: - Direct Contact Add QR View

struct DirectContactAddQRView: View {
    let onContactAdded: (Contact) -> Void
    let onDismiss: () -> Void

    @StateObject private var qrService = QRCodeService()
    @State private var showingScanner = false
    @State private var showingContactPreview = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var scannedBundle: PublicKeyBundle?

    var body: some View {
        VStack {
            if showingScanner || showingContactPreview {
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
                if !showingContactPreview {
                    onDismiss()
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
            if let bundle = scannedBundle {
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
                        // Directly create and add the contact using the original bundle to preserve fingerprint
                        let contact = Contact(from: bundle)
                        showingContactPreview = false
                        onContactAdded(contact)
                    },
                    onCancel: {
                        showingContactPreview = false
                        onDismiss()
                    }
                )
            }
        }
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
        errorMessage =
            "Camera access is required to scan QR codes. Please enable camera access in Settings."
        showingError = true
    }

    private func handleScannedCode(_ code: String) {
        showingScanner = false

        do {
            let content = try qrService.parseQRCode(code)

            switch content {
            case .publicKeyBundle(let bundle):
                scannedBundle = bundle
                showingContactPreview = true
            case .encryptedMessage:
                errorMessage = "This QR code contains an encrypted message, not a contact."
                showingError = true
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
}

// MARK: - Preview

struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddContactView { _ in }
    }
}

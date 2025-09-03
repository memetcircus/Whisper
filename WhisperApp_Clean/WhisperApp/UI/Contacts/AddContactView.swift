import SwiftUI
import AVFoundation

// MARK: - Add Contact View

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddContactViewModel()
    
    let onContactAdded: (Contact) -> Void
    
    @State private var selectedTab = 0
    @State private var showingQRScanner = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Add Method", selection: $selectedTab) {
                    Text("Manual Entry").tag(0)
                    Text("QR Code").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    ManualEntryView(viewModel: viewModel)
                        .tag(0)
                    
                    QRScannerView(viewModel: viewModel)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addContact()
                    }
                    .disabled(!viewModel.canAddContact)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: viewModel.errorMessage) { errorMessage in
                if let error = errorMessage {
                    alertMessage = error
                    showingAlert = true
                    viewModel.errorMessage = nil
                }
            }
        }
    }
    
    private func addContact() {
        do {
            let contact = try viewModel.createContact()
            onContactAdded(contact)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

// MARK: - Manual Entry View

struct ManualEntryView: View {
    @ObservedObject var viewModel: AddContactViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Display name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.headline)
                    
                    TextField("Enter contact name", text: $viewModel.displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Public key input
                VStack(alignment: .leading, spacing: 8) {
                    Text("X25519 Public Key")
                        .font(.headline)
                    
                    TextField("Enter or paste public key", text: $viewModel.x25519PublicKeyString, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .font(.system(.caption, design: .monospaced))
                    
                    Text("Base64 or hex encoded X25519 public key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Optional signing key
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ed25519 Signing Key (Optional)")
                        .font(.headline)
                    
                    TextField("Enter or paste signing key", text: $viewModel.ed25519PublicKeyString, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .font(.system(.caption, design: .monospaced))
                    
                    Text("Base64 or hex encoded Ed25519 public key for signature verification")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Note
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note (Optional)")
                        .font(.headline)
                    
                    TextField("Add a note about this contact", text: $viewModel.note, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
                
                // Preview section
                if viewModel.canPreviewContact {
                    ContactPreviewView(viewModel: viewModel)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
}

// MARK: - QR Scanner View

struct QRScannerView: View {
    @ObservedObject var viewModel: AddContactViewModel
    @State private var showingQRCoordinator = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Scan QR Code")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Scan a QR code containing a contact's public key bundle to add them automatically.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Open Camera") {
                showingQRCoordinator = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Divider()
                .padding(.horizontal)
            
            // Manual QR data entry
            VStack(alignment: .leading, spacing: 8) {
                Text("Or paste QR data manually:")
                    .font(.headline)
                
                TextField("Paste QR code data here", text: $viewModel.qrCodeData, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...8)
                    .font(.system(.caption, design: .monospaced))
                
                if !viewModel.qrCodeData.isEmpty {
                    Button("Parse QR Data") {
                        viewModel.parseQRData()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            
            // Preview section
            if viewModel.canPreviewContact {
                ContactPreviewView(viewModel: viewModel)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingQRCoordinator) {
            QRCodeCoordinatorView(
                onContactAdded: { bundle in
                    viewModel.loadFromBundle(bundle)
                    showingQRCoordinator = false
                },
                onMessageDecrypted: { _ in
                    // Not applicable for contact adding
                    showingQRCoordinator = false
                },
                onDismiss: {
                    showingQRCoordinator = false
                }
            )
        }
    }
}

// MARK: - Contact Preview View

struct ContactPreviewView: View {
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
}

// MARK: - QR Scanner UIKit Wrapper

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let scanner = QRScannerViewController()
        scanner.onCodeScanned = onCodeScanned
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        // No updates needed
    }
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
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
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onCodeScanned?(stringValue)
        }
    }
}

// MARK: - Preview

struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddContactView { _ in }
    }
}
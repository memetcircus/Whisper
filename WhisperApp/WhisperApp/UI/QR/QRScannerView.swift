import SwiftUI
import AVFoundation

/// QR code scanner view with camera preview and scanning functionality
struct QRScannerView: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    let onCodeScanned: (String) -> Void
    let onError: (QRCodeError) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        let parent: QRScannerView
        
        init(_ parent: QRScannerView) {
            self.parent = parent
        }
        
        func qrScannerDidScanCode(_ code: String) {
            parent.onCodeScanned(code)
            parent.isPresented = false
        }
        
        func qrScannerDidEncounterError(_ error: QRCodeError) {
            parent.onError(error)
        }
        
        func qrScannerDidCancel() {
            parent.isPresented = false
        }
    }
}

// MARK: - QR Scanner Delegate Protocol

protocol QRScannerDelegate: AnyObject {
    func qrScannerDidScanCode(_ code: String)
    func qrScannerDidEncounterError(_ error: QRCodeError)
    func qrScannerDidCancel()
}

// MARK: - QR Scanner View Controller

class QRScannerViewController: UIViewController {
    
    weak var delegate: QRScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var scanningEnabled = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Add navigation bar
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)
        
        let navItem = UINavigationItem(title: "Scan QR Code")
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navItem.leftBarButtonItem = cancelButton
        navBar.setItems([navItem], animated: false)
        
        // Add scanning overlay
        let overlayView = ScanningOverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            overlayView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCamera() {
        // Check camera permission
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.delegate?.qrScannerDidEncounterError(.cameraPermissionDenied)
                    }
                }
            }
        case .denied, .restricted:
            delegate?.qrScannerDidEncounterError(.cameraPermissionDenied)
        @unknown default:
            delegate?.qrScannerDidEncounterError(.scanningNotAvailable)
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        // Add video input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.qrScannerDidEncounterError(.scanningNotAvailable)
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.qrScannerDidEncounterError(.scanningNotAvailable)
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.qrScannerDidEncounterError(.scanningNotAvailable)
            return
        }
        
        // Add metadata output
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.qrScannerDidEncounterError(.scanningNotAvailable)
            return
        }
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        
        if let previewLayer = previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
        }
    }
    
    private func startScanning() {
        guard let captureSession = captureSession, !captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
        
        scanningEnabled = true
    }
    
    private func stopScanning() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .background).async {
            captureSession.stopRunning()
        }
        
        scanningEnabled = false
    }
    
    @objc private func cancelTapped() {
        delegate?.qrScannerDidCancel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, 
                       didOutput metadataObjects: [AVMetadataObject], 
                       from connection: AVCaptureConnection) {
        
        guard scanningEnabled else { return }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Disable scanning temporarily to prevent multiple scans
            scanningEnabled = false
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Notify delegate
            delegate?.qrScannerDidScanCode(stringValue)
        }
    }
}

// MARK: - Scanning Overlay View

private class ScanningOverlayView: UIView {
    
    private let scanningFrame = CGRect(x: 0, y: 0, width: 250, height: 250)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Add instruction label
        let instructionLabel = UILabel()
        instructionLabel.text = "Position QR code within the frame"
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw semi-transparent overlay
        context.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
        context.fill(rect)
        
        // Calculate scanning frame position (centered)
        let frameRect = CGRect(
            x: (rect.width - scanningFrame.width) / 2,
            y: (rect.height - scanningFrame.height) / 2,
            width: scanningFrame.width,
            height: scanningFrame.height
        )
        
        // Clear the scanning area
        context.setBlendMode(.clear)
        context.fill(frameRect)
        
        // Draw scanning frame border
        context.setBlendMode(.normal)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        context.stroke(frameRect)
        
        // Draw corner indicators
        let cornerLength: CGFloat = 20
        let cornerWidth: CGFloat = 3
        
        // Top-left corner
        context.setLineWidth(cornerWidth)
        context.move(to: CGPoint(x: frameRect.minX, y: frameRect.minY + cornerLength))
        context.addLine(to: CGPoint(x: frameRect.minX, y: frameRect.minY))
        context.addLine(to: CGPoint(x: frameRect.minX + cornerLength, y: frameRect.minY))
        context.strokePath()
        
        // Top-right corner
        context.move(to: CGPoint(x: frameRect.maxX - cornerLength, y: frameRect.minY))
        context.addLine(to: CGPoint(x: frameRect.maxX, y: frameRect.minY))
        context.addLine(to: CGPoint(x: frameRect.maxX, y: frameRect.minY + cornerLength))
        context.strokePath()
        
        // Bottom-left corner
        context.move(to: CGPoint(x: frameRect.minX, y: frameRect.maxY - cornerLength))
        context.addLine(to: CGPoint(x: frameRect.minX, y: frameRect.maxY))
        context.addLine(to: CGPoint(x: frameRect.minX + cornerLength, y: frameRect.maxY))
        context.strokePath()
        
        // Bottom-right corner
        context.move(to: CGPoint(x: frameRect.maxX - cornerLength, y: frameRect.maxY))
        context.addLine(to: CGPoint(x: frameRect.maxX, y: frameRect.maxY))
        context.addLine(to: CGPoint(x: frameRect.maxX, y: frameRect.maxY - cornerLength))
        context.strokePath()
    }
}
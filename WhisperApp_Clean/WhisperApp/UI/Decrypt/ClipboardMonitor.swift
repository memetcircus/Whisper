import Foundation
import SwiftUI
import Combine

/// Service for monitoring clipboard content and detecting whisper messages
/// Provides automatic detection and banner display functionality
class ClipboardMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var hasWhisperMessage: Bool = false
    @Published var detectedMessage: String = ""
    
    // MARK: - Private Properties
    
    private let whisperService: WhisperService
    private var timer: Timer?
    private var lastClipboardChangeCount: Int = 0
    
    // MARK: - Initialization
    
    init(whisperService: WhisperService = ServiceContainer.shared.whisperService) {
        self.whisperService = whisperService
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring clipboard for changes
    func startMonitoring() {
        // Check initial state
        checkClipboard()
        
        // Set up timer to check clipboard periodically
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    /// Stops monitoring clipboard
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Manually checks clipboard content
    func checkClipboard() {
        let currentChangeCount = UIPasteboard.general.changeCount
        
        // Only check if clipboard content has changed
        guard currentChangeCount != lastClipboardChangeCount else {
            return
        }
        
        lastClipboardChangeCount = currentChangeCount
        
        guard let clipboardString = UIPasteboard.general.string else {
            hasWhisperMessage = false
            detectedMessage = ""
            return
        }
        
        // Check if clipboard contains a whisper message
        if whisperService.detect(clipboardString) {
            hasWhisperMessage = true
            detectedMessage = clipboardString
        } else {
            hasWhisperMessage = false
            detectedMessage = ""
        }
    }
    
    /// Clears the detected message (called after successful decryption)
    func clearDetectedMessage() {
        hasWhisperMessage = false
        detectedMessage = ""
    }
}

// MARK: - Clipboard Banner View

/// Floating banner that appears when whisper message is detected in clipboard
struct ClipboardBanner: View {
    let message: String
    let onDecrypt: () -> Void
    let onDismiss: () -> Void
    
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "envelope.badge")
                    .foregroundColor(.white)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Encrypted Message Detected")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Tap to decrypt")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button("Decrypt") {
                    onDecrypt()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.white)
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
}

// MARK: - Clipboard Banner Modifier

/// View modifier to add clipboard detection banner to any view
struct ClipboardBannerModifier: ViewModifier {
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    @State private var showingDecryptView = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if clipboardMonitor.hasWhisperMessage {
                ClipboardBanner(
                    message: clipboardMonitor.detectedMessage,
                    onDecrypt: {
                        showingDecryptView = true
                    },
                    onDismiss: {
                        clipboardMonitor.clearDetectedMessage()
                    }
                )
                .zIndex(1000) // Ensure banner appears on top
            }
        }
        .sheet(isPresented: $showingDecryptView) {
            DecryptView()
                .onDisappear {
                    // Clear detected message after decrypt view is dismissed
                    clipboardMonitor.clearDetectedMessage()
                }
        }
        .onAppear {
            clipboardMonitor.startMonitoring()
        }
        .onDisappear {
            clipboardMonitor.stopMonitoring()
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds clipboard detection banner to the view
    func clipboardBanner() -> some View {
        modifier(ClipboardBannerModifier())
    }
}
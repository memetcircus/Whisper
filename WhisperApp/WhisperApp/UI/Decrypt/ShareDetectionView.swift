import SwiftUI
import UniformTypeIdentifiers

/// View for handling shared content detection and processing
/// Integrates with iOS share sheet to detect whisper messages from other apps
struct ShareDetectionView: View {
    let sharedText: String
    @State private var showingDecryptView = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Shared Content Detected")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("The shared content appears to be an encrypted Whisper message.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Message Preview")
                        .font(.headline)

                    ScrollView {
                        Text(sharedText.prefix(200) + (sharedText.count > 200 ? "..." : ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 100)
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Button("Decrypt Message") {
                        showingDecryptView = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding()
            .navigationTitle("Shared Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDecryptView) {
            DecryptViewWithPrefilledText(prefilledText: sharedText)
        }
    }
}

/// Decrypt view with prefilled text from share extension
struct DecryptViewWithPrefilledText: View {
    let prefilledText: String
    @StateObject private var viewModel = DecryptViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DecryptView()
            .onAppear {
                viewModel.inputText = prefilledText
                viewModel.validateInput()
            }
    }
}

// MARK: - Share Extension Handler

/// Handles incoming shared content and detects whisper messages
class ShareExtensionHandler: ObservableObject {
    @Published var hasSharedWhisperMessage = false
    @Published var sharedText = ""

    private let whisperService: WhisperService

    init(whisperService: WhisperService = ServiceContainer.shared.whisperService) {
        self.whisperService = whisperService
    }

    /// Processes shared content from other apps
    func handleSharedContent(_ items: [Any]) {
        for item in items {
            if let string = item as? String {
                if whisperService.detect(string) {
                    sharedText = string
                    hasSharedWhisperMessage = true
                    return
                }
            }
        }

        hasSharedWhisperMessage = false
        sharedText = ""
    }

    /// Clears shared content after processing
    func clearSharedContent() {
        hasSharedWhisperMessage = false
        sharedText = ""
    }
}

// MARK: - App Delegate Integration

/// Extension to handle URL schemes and shared content
extension WhisperApp {
    /// Handles incoming URLs (for whisper:// scheme)
    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "whisper" else { return }

        // Extract message from URL
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let messageItem = components.queryItems?.first(where: { $0.name == "message" }),
            let message = messageItem.value
        {

            // Check if it's a valid whisper message
            let whisperService = ServiceContainer.shared.whisperService
            if whisperService.detect(message) {
                // Show decrypt view with the message
                NotificationCenter.default.post(
                    name: .whisperMessageReceived,
                    object: nil,
                    userInfo: ["message": message]
                )
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let whisperMessageReceived = Notification.Name("whisperMessageReceived")
}

// MARK: - Preview

struct ShareDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        ShareDetectionView(sharedText: "whisper1:v1.c20p.example.message.content.here")
    }
}

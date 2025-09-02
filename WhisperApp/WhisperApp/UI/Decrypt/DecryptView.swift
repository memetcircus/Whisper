import SwiftUI
import UniformTypeIdentifiers

/// Main view for decrypting whisper messages
/// Provides clipboard detection, decryption flow, and result display
struct DecryptView: View {
    @StateObject private var viewModel = DecryptViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Detection Banner Section
                if viewModel.showDetectionBanner {
                    detectionBannerSection
                }
                
                // Manual Input Section
                manualInputSection
                
                // Decryption Result Section
                if let result = viewModel.decryptionResult {
                    decryptionResultSection(result)
                }
                
                // Action Buttons
                actionButtonsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Decrypt Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .decryptErrorAlert(error: $viewModel.currentError) {
                // Retry action for retryable errors
                Task {
                    await viewModel.retryLastOperation()
                }
            }
            .alert("Success", isPresented: $viewModel.showingSuccess) {
                Button("OK") { }
            } message: {
                Text(viewModel.successMessage)
            }
            .onAppear {
                viewModel.checkClipboard()
            }
        }
    }
    
    // MARK: - View Components
    
    private var detectionBannerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "envelope.badge")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Encrypted Message Detected")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Found whisper1: message in clipboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Decrypt") {
                    Task {
                        await viewModel.decryptFromClipboard()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var manualInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Encrypted Message")
                .font(.headline)
            
            TextEditor(text: $viewModel.inputText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .onChange(of: viewModel.inputText) { _ in
                    viewModel.validateInput()
                }
            
            if !viewModel.inputText.isEmpty && !viewModel.isValidWhisperMessage {
                Text("Invalid whisper message format")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func decryptionResultSection(_ result: DecryptionResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Decrypted Message")
                .font(.headline)
            
            // Sender Attribution
            senderAttributionView(result.attribution)
            
            // Message Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView {
                    Text(String(data: result.plaintext, encoding: .utf8) ?? "Unable to decode message")
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 200)
            }
            
            // Metadata
            metadataView(result)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func senderAttributionView(_ attribution: AttributionResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sender")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Image(systemName: attributionIcon(attribution))
                    .foregroundColor(attributionColor(attribution))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(attribution.displayString)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    // Trust badge for signed messages
                    HStack {
                        if case .signed(_, let trust) = attribution {
                            Text(trust)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(trust == "Verified" ? Color.green : Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Text(attributionDescription(attribution))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(attributionBackgroundColor(attribution))
            .cornerRadius(8)
        }
    }
    
    private func metadataView(_ result: DecryptionResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message Details")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 4) {
                HStack {
                    Text("Received:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(DateFormatter.messageTimestamp.string(from: result.timestamp))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Security:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("End-to-End Encrypted")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if !viewModel.inputText.isEmpty && viewModel.isValidWhisperMessage {
                Button("Decrypt Message") {
                    Task {
                        await viewModel.decryptManualInput()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isDecrypting)
            }
            
            if viewModel.decryptionResult != nil {
                HStack(spacing: 12) {
                    Button("Copy Message") {
                        viewModel.copyDecryptedMessage()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Clear") {
                        viewModel.clearResult()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func attributionIcon(_ attribution: AttributionResult) -> String {
        switch attribution {
        case .signed(_, let trust):
            return trust == "Verified" ? "checkmark.seal.fill" : "checkmark.seal"
        case .signedUnknown:
            return "questionmark.circle"
        case .unsigned:
            return "person.circle"
        case .invalidSignature:
            return "exclamationmark.triangle"
        }
    }
    
    private func attributionColor(_ attribution: AttributionResult) -> Color {
        switch attribution {
        case .signed(_, let trust):
            return trust == "Verified" ? .green : .orange
        case .signedUnknown:
            return .blue
        case .unsigned:
            return .gray
        case .invalidSignature:
            return .red
        }
    }
    
    private func attributionBackgroundColor(_ attribution: AttributionResult) -> Color {
        switch attribution {
        case .signed(_, let trust):
            return trust == "Verified" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1)
        case .signedUnknown:
            return Color.blue.opacity(0.1)
        case .unsigned:
            return Color.gray.opacity(0.1)
        case .invalidSignature:
            return Color.red.opacity(0.1)
        }
    }
    
    private func attributionDescription(_ attribution: AttributionResult) -> String {
        switch attribution {
        case .signed(_, let trust):
            return trust == "Verified" ? "Identity verified and message signed" : "Message signed but identity not verified"
        case .signedUnknown:
            return "Message signed by unknown sender"
        case .unsigned:
            return "Message not signed"
        case .invalidSignature:
            return "Invalid or corrupted signature"
        }
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let messageTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview

struct DecryptView_Previews: PreviewProvider {
    static var previews: some View {
        DecryptView()
    }
}
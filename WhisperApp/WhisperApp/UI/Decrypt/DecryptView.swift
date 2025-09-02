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
            .navigationTitle(LocalizationHelper.Decrypt.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationHelper.cancel) {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel decrypt")
                    .accessibilityHint("Double tap to cancel message decryption")
                }
            }
            .decryptErrorAlert(error: $viewModel.currentError) {
                // Retry action for retryable errors
                Task {
                    await viewModel.retryLastOperation()
                }
            }
            .alert(LocalizationHelper.Decrypt.successTitle, isPresented: $viewModel.showingSuccess) {
                Button(LocalizationHelper.ok) { }
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
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationHelper.Decrypt.bannerTitle)
                        .font(.scaledHeadline)
                        .foregroundColor(.primary)
                    
                    Text(LocalizationHelper.Decrypt.bannerMessage)
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(LocalizationHelper.Decrypt.bannerDecrypt) {
                    Task {
                        await viewModel.decryptFromClipboard()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityLabel("Decrypt clipboard message")
                .accessibilityHint("Double tap to decrypt the message found in clipboard")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Encrypted message detected in clipboard")
    }
    
    private var manualInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationHelper.Decrypt.inputTitle)
                .font(.scaledHeadline)
            
            TextEditor(text: $viewModel.inputText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.accessibleSecondaryBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .onChange(of: viewModel.inputText) { _ in
                    viewModel.validateInput()
                }
                .accessibilityLabel(LocalizationHelper.Accessibility.encryptedInput)
                .accessibilityHint("Enter the encrypted message you want to decrypt")
                .dynamicTypeSupport(.body)
            
            if !viewModel.inputText.isEmpty && !viewModel.isValidWhisperMessage {
                Text(LocalizationHelper.Decrypt.invalidFormat)
                    .font(.scaledCaption)
                    .foregroundColor(.accessibleError)
            }
        }
    }
    
    private func decryptionResultSection(_ result: DecryptionResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationHelper.Decrypt.decryptedMessage)
                .font(.scaledHeadline)
            
            // Sender Attribution
            senderAttributionView(result.attribution)
            
            // Message Content
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationHelper.Decrypt.content)
                    .font(.scaledSubheadline)
                    .fontWeight(.medium)
                
                ScrollView {
                    Text(String(data: result.plaintext, encoding: .utf8) ?? "Unable to decode message")
                        .font(.scaledBody)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.accessibleSecondaryBackground)
                        .cornerRadius(8)
                }
                .frame(maxHeight: 200)
                .accessibilityLabel("Decrypted message content")
                .accessibilityValue(String(data: result.plaintext, encoding: .utf8) ?? "Unable to decode message")
            }
            
            // Metadata
            metadataView(result)
        }
        .padding()
        .background(Color.accessibleBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
    
    private func senderAttributionView(_ attribution: AttributionResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationHelper.Decrypt.sender)
                .font(.scaledSubheadline)
                .fontWeight(.medium)
            
            HStack {
                Image(systemName: attributionIcon(attribution))
                    .foregroundColor(attributionColor(attribution))
                    .font(.title3)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(attribution.displayString)
                        .font(.scaledBody)
                        .fontWeight(.medium)
                    
                    // Trust badge for signed messages
                    HStack {
                        if case .signed(_, let trust) = attribution {
                            Text(trust)
                                .font(.scaledCaption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(trust == "Verified" ? Color.accessibleSuccess : Color.accessibleWarning)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .accessibilityLabel("\(trust) contact")
                        }
                        
                        Text(attributionDescription(attribution))
                            .font(.scaledCaption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(attributionBackgroundColor(attribution))
            .cornerRadius(8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Message sender: \(attribution.displayString)")
    }
    
    private func metadataView(_ result: DecryptionResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationHelper.Decrypt.messageDetails)
                .font(.scaledSubheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 4) {
                HStack {
                    Text(LocalizationHelper.Decrypt.received)
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(DateFormatter.messageTimestamp.string(from: result.timestamp))
                        .font(.scaledCaption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text(LocalizationHelper.Decrypt.security)
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(LocalizationHelper.Decrypt.endToEndEncrypted)
                        .font(.scaledCaption)
                        .fontWeight(.medium)
                        .foregroundColor(.accessibleSuccess)
                }
            }
            .padding()
            .background(Color.accessibleSecondaryBackground)
            .cornerRadius(8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Message metadata")
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if !viewModel.inputText.isEmpty && viewModel.isValidWhisperMessage {
                Button(LocalizationHelper.Decrypt.decryptMessage) {
                    Task {
                        await viewModel.decryptManualInput()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isDecrypting)
                .frame(minHeight: AccessibilityConstants.minimumTouchTarget)
                .accessibilityLabel(LocalizationHelper.Accessibility.decryptButton)
                .accessibilityHint(LocalizationHelper.Accessibility.hintDecryptButton)
                .dynamicTypeSupport(.body)
            }
            
            if viewModel.decryptionResult != nil {
                HStack(spacing: 12) {
                    Button(LocalizationHelper.Decrypt.copyMessage) {
                        viewModel.copyDecryptedMessage()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(minHeight: AccessibilityConstants.minimumTouchTarget)
                    .accessibilityLabel("Copy decrypted message")
                    .accessibilityHint("Double tap to copy the decrypted message to clipboard")
                    
                    Button(LocalizationHelper.Decrypt.clear) {
                        viewModel.clearResult()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(minHeight: AccessibilityConstants.minimumTouchTarget)
                    .accessibilityLabel("Clear results")
                    .accessibilityHint("Double tap to clear the decryption results")
                }
                .dynamicTypeSupport(.body)
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
import SwiftUI
import UniformTypeIdentifiers

/// Main view for decrypting whisper messages
/// Provides manual input, QR scanning, decryption flow, and result display
/// Note: Clipboard monitoring has been removed for better testing experience
struct DecryptView: View {
    @StateObject private var viewModel = DecryptViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFieldFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with app context
                    headerSection

                    // Show input section only when no decrypted result exists
                    if viewModel.decryptionResult == nil {
                        inputMethodsSection
                        manualInputSection
                        actionButtonSection
                    }

                    // Decryption Result Section
                    if let result = viewModel.decryptionResult {
                        decryptionResultSection(result)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Decrypt Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .accessibilityLabel("Cancel decrypt")
                    .accessibilityHint("Double tap to cancel message decryption")
                }

                // Keyboard toolbar
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    if isInputFieldFocused {
                        Button("Done") {
                            isInputFieldFocused = false
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                }
            }
            .alert(
                "Error",
                isPresented: Binding<Bool>(
                    get: { viewModel.currentError != nil },
                    set: { if !$0 { viewModel.currentError = nil } }
                )
            ) {
                Button("OK") {
                    viewModel.currentError = nil
                }
                // Only show Retry button for specific recoverable errors
                if let error = viewModel.currentError {
                    switch error {
                    case .qrCameraPermissionDenied, .qrScanningNotAvailable:
                        Button("Retry") {
                            viewModel.retryQRScan()
                        }
                    case .invalidEnvelope, .qrUnsupportedFormat, .qrInvalidContent:
                        Button("Retry") {
                            Task {
                                await viewModel.retryLastOperation()
                            }
                        }
                    default:
                        // For cryptographic failures and other non-recoverable errors,
                        // don't show a Retry button since retrying won't help
                        EmptyView()
                    }
                }
            } message: {
                if let error = viewModel.currentError {
                    Text(error.localizedDescription)
                }
            }
            .alert("Success", isPresented: $viewModel.showingSuccess) {
                Button("OK") {}
            } message: {
                Text(viewModel.successMessage)
            }
            .sheet(isPresented: $viewModel.showingQRScanner) {
                QRCodeCoordinatorView(
                    onContactAdded: { _ in
                        // Not used in decrypt workflow - contacts should be rejected
                        viewModel.dismissQRScanner()
                    },
                    onMessageDecrypted: { envelope in
                        viewModel.handleQRScanResult(envelope)
                    },
                    onDismiss: {
                        viewModel.dismissQRScanner()
                    }
                )
            }

        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Message Decryption")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Decrypt messages sent to you securely")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var inputMethodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)

                Text("Input Methods")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            HStack(spacing: 12) {
                // QR Scan Button
                Button(action: { viewModel.presentQRScanner() }) {
                    HStack(spacing: 8) {
                        if viewModel.showingQRScanner {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else if viewModel.isQRScanComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                        } else {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 16))
                        }

                        Text(viewModel.qrScanButtonText)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(viewModel.qrScanButtonColor)
                    .cornerRadius(12)
                    .shadow(color: viewModel.qrScanButtonColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(viewModel.showingQRScanner)
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(viewModel.qrScanAccessibilityLabel)
                .accessibilityHint(viewModel.qrScanAccessibilityHint)

                // Manual Input Indicator - Clickable
                Button(action: {
                    isInputFieldFocused = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 16))
                            .foregroundColor(isInputFieldFocused ? .blue : .secondary)

                        Text("Manual")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isInputFieldFocused ? .blue : .secondary)
                    }
                    .frame(width: 60)
                    .padding(.vertical, 8)
                    .background(isInputFieldFocused ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Manual input")
                .accessibilityHint("Tap to focus the text input field for manual entry")
            }

            // Status messages
            if viewModel.showingQRScanner {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)

                    Text("Position QR code within camera frame")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } else if viewModel.isQRScanComplete {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)

                    Text("QR code scanned successfully!")
                        .font(.system(size: 14))
                        .foregroundColor(.green)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var manualInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)

                Text("Encrypted Message")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                // Validation indicator
                if !viewModel.inputText.isEmpty {
                    HStack(spacing: 4) {
                        Image(
                            systemName: viewModel.isValidWhisperMessage
                                ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.isValidWhisperMessage ? .green : .orange)

                        Text(viewModel.isValidWhisperMessage ? "Valid" : "Invalid")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.isValidWhisperMessage ? .green : .orange)
                    }
                }
            }

            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .frame(minHeight: 200)

                // Placeholder text - positioned behind TextEditor
                if viewModel.inputText.isEmpty {
                    Text("Paste the encrypted message here")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }

                // Text editor with transparent background
                TextEditor(text: $viewModel.inputText)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(minHeight: 200)
                    .background(Color.clear)
                    .focused($isInputFieldFocused)
                    .task(id: viewModel.inputText) {
                      viewModel.validateInput()
                    }
                    .disabled(viewModel.decryptionResult != nil)
                    .accessibilityLabel("Encrypted message input")
                    .accessibilityHint("Paste the encrypted message you want to decrypt here")
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isInputFieldFocused
                            ? Color.blue
                            : viewModel.isValidWhisperMessage
                                ? Color.green : Color(.systemGray5),
                        lineWidth: isInputFieldFocused ? 2 : 1
                    )
            )
            .cornerRadius(16)
            .shadow(
                color: isInputFieldFocused
                    ? Color.blue.opacity(0.2) : Color.black.opacity(0.05),
                radius: isInputFieldFocused ? 4 : 2,
                x: 0,
                y: isInputFieldFocused ? 2 : 1
            )
            .animation(.easeInOut(duration: 0.2), value: isInputFieldFocused)

            // Validation message
            if !viewModel.inputText.isEmpty && !viewModel.isValidWhisperMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)

                    Text("Invalid message format. Please check the encrypted message.")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var actionButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await viewModel.decryptManualInput()
                }
            }) {
                HStack(spacing: 12) {
                    if viewModel.isDecrypting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 18, weight: .medium))
                    }

                    Text(viewModel.isDecrypting ? "Decrypting..." : "Decrypt Message")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: canDecrypt
                            ? [Color.green, Color.green.opacity(0.8)]
                            : [Color.gray, Color.gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(
                    color: canDecrypt ? Color.green.opacity(0.3) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!canDecrypt)
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Decrypt message")
            .accessibilityHint("Tap to decrypt the message")
        }
    }

    private var canDecrypt: Bool {
        !viewModel.isDecrypting && !viewModel.showingQRScanner && !viewModel.inputText.isEmpty
            && viewModel.isValidWhisperMessage
    }

    private func decryptionResultSection(_ result: DecryptionResult) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Success header
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Message Decrypted")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Successfully decrypted and verified")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // New message button
                Button(action: { viewModel.clearResult() }) {
                    Text("New")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)

            // Message content
            messageContentView(result)
        }
    }

    private func messageContentView(_ result: DecryptionResult) -> some View {
        let messageText =
            String(data: result.plaintext, encoding: .utf8) ?? "Unable to decode message"

        return VStack(alignment: .leading, spacing: 16) {
            // Attribution section
            attributionCard(result.attribution)

            // Message content
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)

                    Text("Decrypted Message")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    // Copy button
                    Button(action: { viewModel.copyDecryptedMessage() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                            Text("Copy")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Copy message")
                    .accessibilityHint("Tap to copy the decrypted message to clipboard")
                }

                ScrollView {
                    Text(messageText)
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(16)
                }
                .frame(minHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }

            // Metadata section
            metadataCard(result.attribution, timestamp: result.timestamp)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Message from \(getSenderName(from: result.attribution)) received \(DateFormatter.messageTimestamp.string(from: result.timestamp))"
        )
        .accessibilityValue(messageText)
    }

    private func attributionCard(_ attribution: AttributionResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: attributionIcon(attribution))
                .font(.system(size: 20))
                .foregroundColor(attributionColor(attribution))

            VStack(alignment: .leading, spacing: 2) {
                Text("Sender Verification")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(getAttributionText(attribution))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(attributionBackgroundColor(attribution))
        .cornerRadius(12)
    }

    private func metadataCard(_ attribution: AttributionResult, timestamp: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Text("Message Details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("From:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(getSenderName(from: attribution))
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    Spacer()
                }

                HStack {
                    Text("Received:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(
                        DateFormatter.localizedString(
                            from: timestamp, dateStyle: .short, timeStyle: .short)
                    )
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func getAttributionText(_ attribution: AttributionResult) -> String {
        switch attribution {
        case .signed(let sender, let trustStatus):
            return "Signed by: \(sender) (\(trustStatus))"
        case .unsigned(let sender):
            return "From: \(sender)"
        case .signedUnknown:
            return "Signed by: Unknown sender"
        case .invalidSignature:
            return "Invalid signature"
        }
    }

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

    private func getSenderName(from attribution: AttributionResult) -> String {
        switch attribution {
        case .signed(let name, _):
            return name
        case .signedUnknown:
            return "Unknown"
        case .unsigned(let name):
            return name
        case .invalidSignature:
            return "Unknown"
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

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
}

// MARK: - Previews

struct DecryptView_Previews: PreviewProvider {
    static var previews: some View {
        DecryptView()
    }
}
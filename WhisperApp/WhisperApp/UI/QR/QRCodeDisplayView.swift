import SwiftUI

/// View for displaying generated QR codes with sharing and size warning functionality
struct QRCodeDisplayView: View {

    let qrResult: QRCodeResult
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var showingCopiedMessage = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // QR Code Image
                    qrCodeSection

                    // Size Warning (if applicable)
                    if let sizeWarning = qrResult.sizeWarning {
                        sizeWarningSection(sizeWarning)
                    }

                    // SAS Words (for public key bundles)
                    if qrResult.type == .publicKeyBundle {
                        sasWordsSection
                    }

                    // Fingerprint (for public key bundles)
                    if qrResult.type == .publicKeyBundle {
                        fingerprintSection
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    // MARK: - View Components

    private var qrCodeSection: some View {
        VStack(spacing: 12) {
            // QR Code Image with save feedback
            ZStack {
                Image(uiImage: qrResult.image)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280, maxHeight: 280)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .onLongPressGesture {
                        copyQRImage()
                    }

                // Copied message overlay
                if showingCopiedMessage {
                    VStack {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("Copied!")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .transition(.scale.combined(with: .opacity))
                }
            }

            Text(
                showingCopiedMessage ? "QR code image copied to clipboard" : "Tap and hold to copy"
            )
            .font(.caption)
            .foregroundColor(showingCopiedMessage ? .blue : .secondary)
            .animation(.easeInOut(duration: 0.3), value: showingCopiedMessage)
        }
    }

    private func sizeWarningSection(_ warning: QRCodeSizeWarning) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Size Warning")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
            }

            Text(warning.message)
                .font(.body)
                .foregroundColor(.primary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(warning.actualSize) bytes")
                        .font(.body)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Recommended")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("≤ \(warning.recommendedSize) bytes")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var sasWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "textformat.abc")
                    .foregroundColor(.green)
                Text("SAS Words")
                    .font(.headline)
                Spacer()
            }

            Text("Share these words with the person scanning your QR code for verification:")
                .font(.caption)
                .foregroundColor(.secondary)

            if let sasWords = extractSASWords() {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 8
                ) {
                    ForEach(Array(sasWords.enumerated()), id: \.offset) { index, word in
                        HStack {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .leading)
                            Text(word)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("Unable to generate SAS words")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    private var fingerprintSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "fingerprint")
                    .foregroundColor(.purple)
                Text("Fingerprint")
                    .font(.headline)
                Spacer()
            }

            Text("Share this fingerprint for verification:")
                .font(.caption)
                .foregroundColor(.secondary)

            if let fingerprint = extractFingerprint() {
                VStack(alignment: .leading, spacing: 12) {
                    // Short Fingerprint
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Short ID")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            Text(generateShortFingerprint(fingerprint))
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.bold)
                                .textSelection(.enabled)

                            Spacer()

                            Button(action: { copyShortFingerprint(fingerprint) }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Full Fingerprint
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Full Fingerprint")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            Text(formatFingerprint(fingerprint))
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(nil)

                            Spacer()

                            Button(action: { copyFullFingerprint(fingerprint) }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("Unable to extract fingerprint")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Share Items

    private var shareItems: [Any] {
        // Primary item: QR code image for easy sharing/saving
        return [qrResult.image, qrResult.content]
    }

    // MARK: - Actions

    private func extractSASWords() -> [String]? {
        // Extract SAS words from the public key bundle
        guard qrResult.type == .publicKeyBundle else { return nil }

        do {
            // Parse the QR content to get the public key bundle
            let qrService = QRCodeService()
            let content = try qrService.parseQRCode(qrResult.content)

            if case .publicKeyBundle(let bundle) = content {
                // Generate SAS words from the fingerprint
                return Contact.generateSASWords(from: bundle.fingerprint)
            }
        } catch {
            print("Failed to extract SAS words: \(error)")
        }

        return nil
    }

    private func extractFingerprint() -> Data? {
        // Extract fingerprint from the public key bundle
        guard qrResult.type == .publicKeyBundle else { return nil }

        do {
            // Parse the QR content to get the public key bundle
            let qrService = QRCodeService()
            let content = try qrService.parseQRCode(qrResult.content)

            if case .publicKeyBundle(let bundle) = content {
                return bundle.fingerprint
            }
        } catch {
            print("Failed to extract fingerprint: \(error)")
        }

        return nil
    }

    private func generateShortFingerprint(_ fingerprint: Data) -> String {
        return Contact.generateShortFingerprint(from: fingerprint)
    }

    private func formatFingerprint(_ fingerprint: Data) -> String {
        let hex = fingerprint.map { String(format: "%02x", $0) }
        var result = ""

        // Group into blocks of 4 bytes (8 hex chars) with spaces
        for i in stride(from: 0, to: hex.count, by: 4) {
            let endIndex = min(i + 4, hex.count)
            let block = hex[i..<endIndex].joined(separator: " ")
            result += block

            if endIndex < hex.count {
                result += "  "  // Double space between blocks
            }
        }

        return result
    }

    private func copyShortFingerprint(_ fingerprint: Data) {
        let shortFingerprint = generateShortFingerprint(fingerprint)
        UIPasteboard.general.string = shortFingerprint

        // Show feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func copyFullFingerprint(_ fingerprint: Data) {
        let fullFingerprint = formatFingerprint(fingerprint)
        UIPasteboard.general.string = fullFingerprint

        // Show feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func copyQRImage() {
        // Copy the QR code image to clipboard
        UIPasteboard.general.image = qrResult.image

        // Show success feedback
        showCopiedFeedback()
    }

    private func showCopiedFeedback() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Visual feedback
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingCopiedMessage = true
        }

        // Hide the message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showingCopiedMessage = false
            }
        }
    }

}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#if DEBUG
    struct QRCodeDisplayView_Previews: PreviewProvider {
        static var previews: some View {
            // Create a sample QR result for preview
            let sampleImage = UIImage(systemName: "qrcode") ?? UIImage()
            let sampleResult = QRCodeResult(
                image: sampleImage,
                content: "whisper1:v1.c20p.sample.content.for.preview",
                type: .encryptedMessage,
                sizeWarning: QRCodeSizeWarning(
                    actualSize: 1200,
                    recommendedSize: 900,
                    message:
                        "QR code may be difficult to scan reliably. Consider sharing as text instead."
                )
            )

            QRCodeDisplayView(
                qrResult: sampleResult,
                title: "Encrypted Message"
            )
        }
    }
#endif

import SwiftUI

/// View for displaying generated QR codes with sharing and size warning functionality
struct QRCodeDisplayView: View {
    
    let qrResult: QRCodeResult
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
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
                    
                    // Content Type Info
                    contentInfoSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
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
            // QR Code Image
            Image(uiImage: qrResult.image)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 280, maxHeight: 280)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Text("Tap and hold to save image")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onLongPressGesture {
            saveImageToPhotos()
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
    
    private var contentInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: qrResult.type == .publicKeyBundle ? "person.badge.key" : "envelope.badge.shield.half.filled")
                    .foregroundColor(.blue)
                Text("Content Type")
                    .font(.headline)
                Spacer()
            }
            
            Text(qrResult.type.displayName)
                .font(.body)
                .foregroundColor(.primary)
            
            if qrResult.type == .publicKeyBundle {
                Text("This QR code contains a public key bundle that can be used to add a new contact.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("This QR code contains an encrypted message that can be decrypted by the recipient.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Share Button
            Button(action: { showingShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share QR Code")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // Copy Content Button
            Button(action: copyContent) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Content")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            
            // Save Image Button
            Button(action: saveImageToPhotos) {
                HStack {
                    Image(systemName: "photo")
                    Text("Save to Photos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Share Items
    
    private var shareItems: [Any] {
        var items: [Any] = [qrResult.image]
        
        // Add content text for sharing
        items.append(qrResult.content)
        
        return items
    }
    
    // MARK: - Actions
    
    private func copyContent() {
        UIPasteboard.general.string = qrResult.content
        
        // Show feedback (in a real app, you might want to show a toast)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func saveImageToPhotos() {
        UIImageWriteToSavedPhotosAlbum(qrResult.image, nil, nil, nil)
        
        // Show feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
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
                message: "QR code may be difficult to scan reliably. Consider sharing as text instead."
            )
        )
        
        QRCodeDisplayView(
            qrResult: sampleResult,
            title: "Encrypted Message"
        )
    }
}
#endif
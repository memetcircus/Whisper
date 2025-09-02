import SwiftUI

/// View for previewing a contact from a scanned QR code before adding
struct ContactPreviewView: View {
    
    let bundle: PublicKeyBundle
    let onAdd: (PublicKeyBundle) -> Void
    let onCancel: () -> Void
    
    @State private var isAdding = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Contact Information
                    contactInfoSection
                    
                    // Security Information
                    securityInfoSection
                    
                    // Key Information
                    keyInfoSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isAdding)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Contact Icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("New Contact")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Review the contact information before adding")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Contact Information", systemImage: "person.text.rectangle")
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    label: "Display Name",
                    value: bundle.name,
                    icon: "person"
                )
                
                InfoRow(
                    label: "Key Version",
                    value: "\(bundle.keyVersion)",
                    icon: "key"
                )
                
                InfoRow(
                    label: "Created",
                    value: formatDate(bundle.createdAt),
                    icon: "calendar"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var securityInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Security Information", systemImage: "shield.checkered")
            
            VStack(alignment: .leading, spacing: 12) {
                // Fingerprint
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "fingerprint")
                            .foregroundColor(.blue)
                        Text("Fingerprint")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text(formatFingerprint(bundle.fingerprint))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                
                // Short Fingerprint
                InfoRow(
                    label: "Short ID",
                    value: generateShortFingerprint(bundle.fingerprint),
                    icon: "number"
                )
                
                // SAS Words
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "textformat.abc")
                            .foregroundColor(.blue)
                        Text("SAS Words")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text(generateSASWords(bundle.fingerprint).joined(separator: " • "))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var keyInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Cryptographic Keys", systemImage: "key.horizontal")
            
            VStack(alignment: .leading, spacing: 12) {
                // X25519 Key
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.green)
                        Text("X25519 Public Key")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Encryption")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    Text(bundle.x25519PublicKey.base64EncodedString())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
                
                // Ed25519 Key (if present)
                if let ed25519Key = bundle.ed25519PublicKey {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "signature")
                                .foregroundColor(.purple)
                            Text("Ed25519 Public Key")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("Signing")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .cornerRadius(4)
                        }
                        
                        Text(ed25519Key.base64EncodedString())
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                } else {
                    HStack {
                        Image(systemName: "signature")
                            .foregroundColor(.gray)
                        Text("No signing key available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Add Contact Button
            Button(action: addContact) {
                HStack {
                    if isAdding {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.plus")
                    }
                    Text(isAdding ? "Adding Contact..." : "Add Contact")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isAdding)
            
            // Cancel Button
            Button(action: onCancel) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Cancel")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .disabled(isAdding)
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func addContact() {
        isAdding = true
        
        // Simulate async operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                // Validate the bundle before adding
                try validateBundle(bundle)
                onAdd(bundle)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                isAdding = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateBundle(_ bundle: PublicKeyBundle) throws {
        // Validate key sizes
        guard bundle.x25519PublicKey.count == 32 else {
            throw ContactPreviewError.invalidKeySize("X25519 key must be 32 bytes")
        }
        
        if let ed25519Key = bundle.ed25519PublicKey {
            guard ed25519Key.count == 32 else {
                throw ContactPreviewError.invalidKeySize("Ed25519 key must be 32 bytes")
            }
        }
        
        // Validate name
        guard !bundle.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ContactPreviewError.invalidName("Contact name cannot be empty")
        }
        
        // Validate fingerprint
        guard bundle.fingerprint.count == 32 else {
            throw ContactPreviewError.invalidFingerprint("Fingerprint must be 32 bytes")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFingerprint(_ fingerprint: Data) -> String {
        return fingerprint.map { String(format: "%02X", $0) }
            .joined(separator: " ")
            .chunked(into: 8)
            .joined(separator: "\n")
    }
    
    private func generateShortFingerprint(_ fingerprint: Data) -> String {
        // This should match the implementation in Contact.swift
        let base32 = fingerprint.base32CrockfordEncoded()
        return String(base32.prefix(12))
    }
    
    private func generateSASWords(_ fingerprint: Data) -> [String] {
        // This should match the implementation in Contact.swift
        let sasWordList = ["alpha", "bravo", "charlie", "delta", "echo", "foxtrot"] // Simplified for preview
        var words: [String] = []
        
        let bytes = Array(fingerprint.prefix(6))
        for byte in bytes {
            let index = Int(byte) % sasWordList.count
            words.append(sasWordList[index])
        }
        
        return words
    }
}

// MARK: - Supporting Views

private struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

// MARK: - Error Types

enum ContactPreviewError: Error, LocalizedError {
    case invalidKeySize(String)
    case invalidName(String)
    case invalidFingerprint(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidKeySize(let message),
             .invalidName(let message),
             .invalidFingerprint(let message):
            return message
        }
    }
}

// MARK: - String Extension

private extension String {
    func chunked(into size: Int) -> [String] {
        return stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: min(size, count - $0))
            return String(self[start..<end])
        }
    }
}

// MARK: - Data Extension (Placeholder)

private extension Data {
    func base32CrockfordEncoded() -> String {
        // Placeholder implementation - in real app this would be properly implemented
        return base64EncodedString().replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Preview

#if DEBUG
struct ContactPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBundle = PublicKeyBundle(
            id: UUID(),
            name: "Alice Smith",
            x25519PublicKey: Data(repeating: 0x01, count: 32),
            ed25519PublicKey: Data(repeating: 0x02, count: 32),
            fingerprint: Data(repeating: 0x03, count: 32),
            keyVersion: 1,
            createdAt: Date()
        )
        
        ContactPreviewView(
            bundle: sampleBundle,
            onAdd: { _ in },
            onCancel: { }
        )
    }
}
#endif
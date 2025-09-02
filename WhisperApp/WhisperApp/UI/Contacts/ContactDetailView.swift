import SwiftUI

// MARK: - Contact Detail View

struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ContactDetailViewModel
    
    let onContactUpdated: (Contact) -> Void
    
    @State private var showingVerificationSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingBlockAlert = false
    
    init(contact: Contact, onContactUpdated: @escaping (Contact) -> Void) {
        self._viewModel = StateObject(wrappedValue: ContactDetailViewModel(contact: contact))
        self.onContactUpdated = onContactUpdated
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    ContactHeaderView(contact: viewModel.contact)
                    
                    // Trust status section
                    TrustStatusSection(
                        contact: viewModel.contact,
                        onVerify: { showingVerificationSheet = true }
                    )
                    
                    // Fingerprint section
                    FingerprintSection(contact: viewModel.contact)
                    
                    // SAS words section
                    SASWordsSection(contact: viewModel.contact)
                    
                    // Key information section
                    KeyInformationSection(contact: viewModel.contact)
                    
                    // Note section
                    if let note = viewModel.contact.note, !note.isEmpty {
                        NoteSection(note: note)
                    }
                    
                    // Key history section
                    if !viewModel.contact.keyHistory.isEmpty {
                        KeyHistorySection(keyHistory: viewModel.contact.keyHistory)
                    }
                    
                    // Actions section
                    ActionsSection(
                        contact: viewModel.contact,
                        onEdit: { showingEditSheet = true },
                        onBlock: { showingBlockAlert = true },
                        onDelete: { showingDeleteAlert = true }
                    )
                }
                .padding()
            }
            .navigationTitle(viewModel.contact.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Contact") {
                            showingEditSheet = true
                        }
                        
                        Button("Share QR Code") {
                            viewModel.showQRCode()
                        }
                        
                        Button("Export Public Key") {
                            exportPublicKey()
                        }
                        
                        Divider()
                        
                        Button(viewModel.contact.isBlocked ? "Unblock" : "Block") {
                            showingBlockAlert = true
                        }
                        
                        Button("Delete", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingVerificationSheet) {
                ContactVerificationView(contact: viewModel.contact) { verified in
                    viewModel.updateTrustLevel(verified ? .verified : .unverified)
                    onContactUpdated(viewModel.contact)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditContactView(contact: viewModel.contact) { updatedContact in
                    viewModel.updateContact(updatedContact)
                    onContactUpdated(viewModel.contact)
                }
            }
            .alert("Block Contact", isPresented: $showingBlockAlert) {
                Button("Cancel", role: .cancel) { }
                Button(viewModel.contact.isBlocked ? "Unblock" : "Block") {
                    viewModel.toggleBlockStatus()
                    onContactUpdated(viewModel.contact)
                }
            } message: {
                Text(viewModel.contact.isBlocked ? 
                     "Are you sure you want to unblock this contact?" :
                     "Are you sure you want to block this contact? You won't be able to send or receive messages from them.")
            }
            .alert("Delete Contact", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // TODO: Implement delete functionality
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this contact? This action cannot be undone.")
            }
            .sheet(isPresented: $viewModel.showingQRCode) {
                if let qrResult = viewModel.qrCodeResult {
                    QRCodeDisplayView(
                        qrResult: qrResult,
                        title: "Contact QR Code"
                    )
                }
            }
        }
    }
    
    private func exportPublicKey() {
        // TODO: Implement public key export
        print("Exporting public key for \(viewModel.contact.displayName)")
    }
}

// MARK: - Contact Header View

struct ContactHeaderView: View {
    let contact: Contact
    
    var body: some View {
        VStack(spacing: 16) {
            ContactAvatarView(contact: contact)
                .scaleEffect(1.5)
            
            VStack(spacing: 4) {
                Text(contact.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("ID: \(contact.shortFingerprint)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let lastSeen = contact.lastSeenAt {
                    Text("Last seen: \(lastSeen, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Trust Status Section

struct TrustStatusSection: View {
    let contact: Contact
    let onVerify: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trust Status")
                .font(.headline)
            
            HStack {
                TrustBadgeView(trustLevel: contact.trustLevel)
                
                Spacer()
                
                if contact.trustLevel != .verified {
                    Button("Verify Contact") {
                        onVerify()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            Text(trustStatusDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var trustStatusDescription: String {
        switch contact.trustLevel {
        case .verified:
            return "This contact has been verified. Messages from this contact are trusted."
        case .unverified:
            return "This contact has not been verified. Verify the fingerprint or SAS words to establish trust."
        case .revoked:
            return "This contact's trust has been revoked. Exercise caution when communicating."
        }
    }
}

// MARK: - Fingerprint Section

struct FingerprintSection: View {
    let contact: Contact
    @State private var showingFullFingerprint = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fingerprint")
                    .font(.headline)
                
                Spacer()
                
                Button(showingFullFingerprint ? "Hide" : "Show Full") {
                    showingFullFingerprint.toggle()
                }
                .font(.caption)
            }
            
            if showingFullFingerprint {
                Text(fullFingerprintDisplay)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            } else {
                Text("Short ID: \(contact.shortFingerprint)")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var fullFingerprintDisplay: String {
        return contact.fingerprint.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}

// MARK: - SAS Words Section

struct SASWordsSection: View {
    let contact: Contact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SAS Words")
                .font(.headline)
            
            Text("Use these words to verify the contact in person:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(Array(contact.sasWords.enumerated()), id: \.offset) { index, word in
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
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Key Information Section

struct KeyInformationSection: View {
    let contact: Contact
    @State private var showingKeys = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cryptographic Keys")
                    .font(.headline)
                
                Spacer()
                
                Button(showingKeys ? "Hide" : "Show") {
                    showingKeys.toggle()
                }
                .font(.caption)
            }
            
            if showingKeys {
                VStack(alignment: .leading, spacing: 8) {
                    Text("X25519 Public Key:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(contact.x25519PublicKey.base64EncodedString())
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                    
                    if let ed25519Key = contact.ed25519PublicKey {
                        Text("Ed25519 Signing Key:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        Text(ed25519Key.base64EncodedString())
                            .font(.system(.caption2, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            
            HStack {
                Text("Key Version: \(contact.keyVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Created: \(contact.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Note Section

struct NoteSection: View {
    let note: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note")
                .font(.headline)
            
            Text(note)
                .font(.body)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Key History Section

struct KeyHistorySection: View {
    let keyHistory: [KeyHistoryEntry]
    @State private var showingHistory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Key History")
                    .font(.headline)
                
                Spacer()
                
                Button(showingHistory ? "Hide" : "Show") {
                    showingHistory.toggle()
                }
                .font(.caption)
            }
            
            if showingHistory {
                ForEach(keyHistory.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Version \(entry.keyVersion)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(entry.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(entry.fingerprint.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " ") + "...")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Actions Section

struct ActionsSection: View {
    let contact: Contact
    let onEdit: () -> Void
    let onBlock: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button("Edit Contact") {
                onEdit()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 12) {
                Button(contact.isBlocked ? "Unblock" : "Block") {
                    onBlock()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Preview

struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ContactDetailView(contact: sampleContact) { _ in }
    }
    
    static var sampleContact: Contact {
        let publicKey = Data(repeating: 0x01, count: 32)
        return try! Contact(
            displayName: "Alice Smith",
            x25519PublicKey: publicKey,
            ed25519PublicKey: Data(repeating: 0x02, count: 32),
            note: "Work colleague from the security team"
        ).withUpdatedTrustLevel(.verified)
    }
}
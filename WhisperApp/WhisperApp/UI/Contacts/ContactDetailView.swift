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
                VStack(spacing: 20) {
                    // Enhanced Header section with better visual hierarchy
                    ContactHeaderView(contact: viewModel.contact)
                    
                    // Trust status section with improved design
                    TrustStatusSection(
                        contact: viewModel.contact,
                        onVerify: { showingVerificationSheet = true }
                    )
                    
                    // Fingerprint section with better UX
                    FingerprintSection(contact: viewModel.contact)
                    
                    // SAS words section with improved layout
                    SASWordsSection(contact: viewModel.contact)
                    
                    // Key information section with better organization
                    KeyInformationSection(contact: viewModel.contact)
                    
                    // Note section with improved styling
                    if let note = viewModel.contact.note, !note.isEmpty {
                        NoteSection(note: note)
                    }
                    
                    // Key history section with better presentation
                    if !viewModel.contact.keyHistory.isEmpty {
                        KeyHistorySection(keyHistory: viewModel.contact.keyHistory)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, weight: .medium))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Contact") {
                            showingEditSheet = true
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
                            .font(.system(.body, weight: .medium))
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
                Button("Cancel", role: .cancel) {}
                Button(viewModel.contact.isBlocked ? "Unblock" : "Block") {
                    viewModel.toggleBlockStatus()
                    onContactUpdated(viewModel.contact)
                }
            } message: {
                Text(viewModel.contact.isBlocked 
                    ? "Are you sure you want to unblock this contact?" 
                    : "Are you sure you want to block this contact? You won't be able to send or receive messages from them.")
            }
            .alert("Delete Contact", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
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
}

// MARK: - Contact Header View (Enhanced but build-safe)
struct ContactHeaderView: View {
    let contact: Contact

    var body: some View {
        VStack(spacing: 16) {
            // Enhanced avatar with trust indicator
            ZStack {
                ContactAvatarView(contact: contact)
                    .scaleEffect(1.8)
                
                // Trust level overlay - enhanced
                if contact.trustLevel == .verified {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 30, y: -30)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }

            VStack(spacing: 8) {
                Text(contact.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Enhanced ID display
                HStack(spacing: 4) {
                    Image(systemName: "key")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("ID: \(contact.shortFingerprint)")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                if let lastSeen = contact.lastSeenAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Last seen: \(lastSeen, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Trust Status Section (Enhanced)
struct TrustStatusSection: View {
    let contact: Contact
    let onVerify: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.blue)
                Text("Trust Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    TrustBadgeView(trustLevel: contact.trustLevel)
                        .scaleEffect(1.1)
                    
                    Spacer()
                    
                    if contact.trustLevel != .verified {
                        Button("Verify Contact") {
                            onVerify()
                        }
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }

                Text(trustStatusDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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

// MARK: - Fingerprint Section (Enhanced)
struct FingerprintSection: View {
    let contact: Contact
    @State private var showingFullFingerprint = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "key.horizontal.fill")
                    .foregroundColor(.green)
                Text("Fingerprint")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingFullFingerprint ? "Hide" : "Show Full") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingFullFingerprint.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 8) {
                if showingFullFingerprint {
                    Text("Full Fingerprint:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(fullFingerprintDisplay)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    Text("Short ID:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(contact.shortFingerprint)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var fullFingerprintDisplay: String {
        return contact.fingerprint.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}

// MARK: - SAS Words Section (Enhanced)
struct SASWordsSection: View {
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.orange)
                Text("SAS Words")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Use these words to verify the contact in person:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(Array(contact.sasWords.enumerated()), id: \.offset) { index, word in
                        HStack {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .leading)
                            
                            Text(word)
                                .font(.system(.body, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Key Information Section (Enhanced)
struct KeyInformationSection: View {
    let contact: Contact
    @State private var showingTechnicalDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.purple)
                Text("Technical Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingTechnicalDetails ? "Hide Advanced" : "Show Advanced") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingTechnicalDetails.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            // Always show basic info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Version")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(contact.keyVersion)")
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(contact.createdAt, style: .date)
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            if showingTechnicalDetails {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Advanced Technical Details")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    Text("These cryptographic keys are for technical verification only. Do not share these values.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        KeyDisplayView(
                            title: "Encryption Key (X25519):",
                            key: contact.x25519PublicKey.base64EncodedString()
                        )
                        
                        if let ed25519Key = contact.ed25519PublicKey {
                            KeyDisplayView(
                                title: "Signing Key (Ed25519):",
                                key: ed25519Key.base64EncodedString()
                            )
                        }
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Key Display View
struct KeyDisplayView: View {
    let title: String
    let key: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(key)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(6)
        }
    }
}

// MARK: - Note Section (Enhanced)
struct NoteSection: View {
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.indigo)
                Text("Note")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Text(note)
                .font(.body)
                .foregroundColor(.primary)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Key History Section (Enhanced)
struct KeyHistorySection: View {
    let keyHistory: [KeyHistoryEntry]
    @State private var showingHistory = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.teal)
                Text("Key History")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingHistory ? "Hide" : "Show") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingHistory.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            if showingHistory {
                VStack(spacing: 8) {
                    ForEach(keyHistory.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { entry in
                        VStack(alignment: .leading, spacing: 6) {
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
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Note: ContactAvatarView and TrustBadgeView are defined in ContactListView.swift
// and are automatically available here since they're in the same module

// MARK: - Previews
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
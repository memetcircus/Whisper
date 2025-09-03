import SwiftUI

// MARK: - Contact Verification View

struct ContactVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    let contact: Contact
    let onVerificationComplete: (Bool) -> Void
    
    @State private var selectedVerificationMethod = 0
    @State private var fingerprintConfirmed = false
    @State private var sasWordsConfirmed = false
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ContactAvatarView(contact: contact)
                    
                    Text("Verify \(contact.displayName)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("To establish trust, verify this contact's identity using one of the methods below.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Verification method selector
                Picker("Verification Method", selection: $selectedVerificationMethod) {
                    Text("SAS Words").tag(0)
                    Text("Fingerprint").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected method
                TabView(selection: $selectedVerificationMethod) {
                    SASVerificationView(
                        contact: contact,
                        isConfirmed: $sasWordsConfirmed
                    )
                    .tag(0)
                    
                    FingerprintVerificationView(
                        contact: contact,
                        isConfirmed: $fingerprintConfirmed
                    )
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Confirm Verification") {
                        showingConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(!canConfirmVerification)
                    
                    Button("Skip Verification") {
                        onVerificationComplete(false)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Verify Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Verification", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Verify") {
                    verifyContact(sasConfirmed: canConfirmVerification)
                    onVerificationComplete(true)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to mark this contact as verified? This will establish trust for future communications.")
            }
        }
    }
    
    private var canConfirmVerification: Bool {
        return (selectedVerificationMethod == 0 && sasWordsConfirmed) ||
               (selectedVerificationMethod == 1 && fingerprintConfirmed)
    }
    
    private func verifyContact(sasConfirmed: Bool) {
        // This method handles the verification logic
        // In a real implementation, this would update the contact's trust level
        print("Verifying contact \(contact.displayName) with SAS confirmed: \(sasConfirmed)")
    }
}

// MARK: - SAS Verification View

struct SASVerificationView: View {
    let contact: Contact
    @Binding var isConfirmed: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("SAS Word Verification")
                        .font(.headline)
                    
                    Text("Ask \(contact.displayName) to read their SAS words aloud, then check each word below:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // SAS words checklist
                VStack(spacing: 12) {
                    ForEach(Array(contact.sasWords.enumerated()), id: \.offset) { index, word in
                        SASWordRow(
                            number: index + 1,
                            word: word,
                            isChecked: .constant(true) // For demo purposes
                        )
                    }
                }
                
                // Confirmation checkbox
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $isConfirmed) {
                        Text("I have verified all SAS words match")
                            .font(.subheadline)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    
                    Text("Only check this if you have personally verified each word with \(contact.displayName).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
}

// MARK: - SAS Word Row

struct SASWordRow: View {
    let number: Int
    let word: String
    @Binding var isChecked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Number
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .center)
            
            // Word
            Text(word)
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Checkmark (for visual feedback)
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isChecked ? .green : .secondary)
                .font(.title2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isChecked ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Fingerprint Verification View

struct FingerprintVerificationView: View {
    let contact: Contact
    @Binding var isConfirmed: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fingerprint Verification")
                        .font(.headline)
                    
                    Text("Compare this fingerprint with \(contact.displayName)'s fingerprint. They should match exactly:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Short fingerprint
                VStack(alignment: .leading, spacing: 8) {
                    Text("Short ID")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(contact.shortFingerprint)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .textSelection(.enabled)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Full fingerprint
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Fingerprint")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(fullFingerprintDisplay)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // QR code option
                VStack(alignment: .leading, spacing: 8) {
                    Text("QR Code Verification")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Show QR Code") {
                        // TODO: Show QR code with fingerprint
                    }
                    .buttonStyle(.bordered)
                    
                    Text("You can also scan each other's QR codes to verify fingerprints automatically.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Confirmation checkbox
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $isConfirmed) {
                        Text("I have verified the fingerprint matches")
                            .font(.subheadline)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    
                    Text("Only check this if you have personally verified the fingerprint with \(contact.displayName).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    private var fullFingerprintDisplay: String {
        let hex = contact.fingerprint.map { String(format: "%02x", $0) }
        var result = ""
        
        // Group into blocks of 4 bytes (8 hex chars) with spaces
        for i in stride(from: 0, to: hex.count, by: 4) {
            let endIndex = min(i + 4, hex.count)
            let block = hex[i..<endIndex].joined(separator: " ")
            result += block
            
            if endIndex < hex.count {
                result += "  " // Double space between blocks
            }
        }
        
        return result
    }
}

// MARK: - Checkbox Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .secondary)
                .font(.title2)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

// MARK: - Edit Contact View

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var note: String
    
    let contact: Contact
    let onSave: (Contact) -> Void
    
    init(contact: Contact, onSave: @escaping (Contact) -> Void) {
        self.contact = contact
        self.onSave = onSave
        self._displayName = State(initialValue: contact.displayName)
        self._note = State(initialValue: contact.note ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Information") {
                    TextField("Display Name", text: $displayName)
                    
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Fingerprint") {
                    Text(contact.shortFingerprint)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveContact() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var updatedContact = contact
        updatedContact = Contact(
            id: contact.id,
            displayName: trimmedName,
            x25519PublicKey: contact.x25519PublicKey,
            ed25519PublicKey: contact.ed25519PublicKey,
            fingerprint: contact.fingerprint,
            shortFingerprint: contact.shortFingerprint,
            sasWords: contact.sasWords,
            rkid: contact.rkid,
            trustLevel: contact.trustLevel,
            isBlocked: contact.isBlocked,
            keyVersion: contact.keyVersion,
            keyHistory: contact.keyHistory,
            createdAt: contact.createdAt,
            lastSeenAt: contact.lastSeenAt,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        
        onSave(updatedContact)
        dismiss()
    }
}

// MARK: - Preview

struct ContactVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        ContactVerificationView(contact: sampleContact) { _ in }
    }
    
    static var sampleContact: Contact {
        let publicKey = Data(repeating: 0x01, count: 32)
        return try! Contact(
            displayName: "Alice Smith",
            x25519PublicKey: publicKey,
            ed25519PublicKey: Data(repeating: 0x02, count: 32)
        )
    }
}
import SwiftUI
import UniformTypeIdentifiers

/// Main view for composing and encrypting messages
/// Provides identity selection, contact picker, encryption flow, and sharing options
struct ComposeView: View {
    @StateObject private var viewModel = ComposeViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Identity Selection Section
                identitySelectionSection
                
                // Recipient Selection Section
                recipientSelectionSection
                
                // Message Input Section
                messageInputSection
                
                // Options Section
                optionsSection
                
                // Action Buttons
                actionButtonsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Compose Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Biometric Authentication", isPresented: $viewModel.showingBiometricPrompt) {
                Button("Cancel") {
                    viewModel.cancelBiometricAuth()
                }
            } message: {
                Text("Touch ID or Face ID is required to sign this message.")
            }
            .sheet(isPresented: $viewModel.showingContactPicker) {
                ContactPickerView(selectedContact: $viewModel.selectedContact)
            }
            .sheet(isPresented: $viewModel.showingShareSheet) {
                if let encryptedMessage = viewModel.encryptedMessage {
                    ShareSheet(items: [encryptedMessage])
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var identitySelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("From Identity")
                .font(.headline)
            
            if let activeIdentity = viewModel.activeIdentity {
                HStack {
                    VStack(alignment: .leading) {
                        Text(activeIdentity.name)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("Active Identity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        viewModel.showIdentityPicker()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                Text("No active identity")
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private var recipientSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("To")
                .font(.headline)
            
            HStack {
                if let selectedContact = viewModel.selectedContact {
                    VStack(alignment: .leading) {
                        Text(selectedContact.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text(selectedContact.trustLevel.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(selectedContact.trustLevel.badgeColor))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            
                            Text(selectedContact.shortFingerprint)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        viewModel.showingContactPicker = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Select Contact") {
                            viewModel.showingContactPicker = true
                        }
                        .buttonStyle(.bordered)
                        
                        if !viewModel.isContactRequired {
                            Button("Use Raw Key") {
                                viewModel.showRawKeyInput()
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var messageInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message")
                .font(.headline)
            
            TextEditor(text: $viewModel.messageText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
            
            Toggle("Include Signature", isOn: $viewModel.includeSignature)
                .disabled(viewModel.isSignatureRequired)
            
            if viewModel.isSignatureRequired {
                Text("Signature required by policy for verified contacts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Encrypt Message") {
                Task {
                    await viewModel.encryptMessage()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canEncrypt)
            
            if viewModel.encryptedMessage != nil {
                HStack(spacing: 12) {
                    Button("Share") {
                        viewModel.showingShareSheet = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Copy") {
                        viewModel.copyToClipboard()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
    }
}

// MARK: - Contact Picker View

struct ContactPickerView: View {
    @Binding var selectedContact: Contact?
    @StateObject private var contactManager = ContactPickerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(contactManager.contacts, id: \.id) { contact in
                    ContactRowView(contact: contact) {
                        selectedContact = contact
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                contactManager.loadContacts()
            }
        }
    }
}

// MARK: - Contact Row View

struct ContactRowView: View {
    let contact: Contact
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(contact.trustLevel.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(contact.trustLevel.badgeColor))
                            .foregroundColor(.white)
                            .cornerRadius(3)
                        
                        Text(contact.shortFingerprint)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if contact.isBlocked {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(contact.isBlocked)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct ComposeView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeView()
    }
}
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
            .navigationTitle(LocalizationHelper.Encrypt.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationHelper.cancel) {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel compose")
                    .accessibilityHint("Double tap to cancel message composition")
                }
            }
            .alert(LocalizationHelper.Error.generic, isPresented: $viewModel.showingError) {
                Button(LocalizationHelper.ok) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert(LocalizationHelper.Sign.bioPrepTitle, isPresented: $viewModel.showingBiometricPrompt) {
                Button(LocalizationHelper.cancel) {
                    viewModel.cancelBiometricAuth()
                }
            } message: {
                Text(LocalizationHelper.Sign.bioPrepBody)
            }
            .sheet(isPresented: $viewModel.showingContactPicker) {
                ContactPickerView(selectedContact: $viewModel.selectedContact)
            }
            .sheet(isPresented: $viewModel.showingShareSheet) {
                if let encryptedMessage = viewModel.encryptedMessage {
                    ShareSheet(items: [encryptedMessage])
                }
            }
            .sheet(isPresented: $viewModel.showingQRCode) {
                if let qrResult = viewModel.qrCodeResult {
                    QRCodeDisplayView(
                        qrResult: qrResult,
                        title: "Encrypted Message"
                    )
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var identitySelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationHelper.Encrypt.fromIdentity)
                .font(.scaledHeadline)
            
            if let activeIdentity = viewModel.activeIdentity {
                HStack {
                    VStack(alignment: .leading) {
                        Text(activeIdentity.name)
                            .font(.scaledBody)
                            .fontWeight(.medium)
                        
                        Text(LocalizationHelper.Identity.active)
                            .font(.scaledCaption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(LocalizationHelper.Encrypt.change) {
                        viewModel.showIdentityPicker()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("Change sender identity")
                    .accessibilityHint("Double tap to select a different identity")
                }
                .padding()
                .background(Color.accessibleSecondaryBackground)
                .cornerRadius(8)
            } else {
                Text("No active identity")
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.accessibleSecondaryBackground)
                    .cornerRadius(8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LocalizationHelper.Accessibility.identitySelector)
    }
    
    private var recipientSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationHelper.Encrypt.to)
                .font(.scaledHeadline)
            
            HStack {
                if let selectedContact = viewModel.selectedContact {
                    VStack(alignment: .leading) {
                        Text(selectedContact.displayName)
                            .font(.scaledBody)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text(selectedContact.trustLevel.displayName)
                                .font(.scaledCaption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.trustLevelColor(for: selectedContact.trustLevel))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            
                            Text(selectedContact.shortFingerprint)
                                .font(.scaledCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(LocalizationHelper.Encrypt.change) {
                        viewModel.showingContactPicker = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("Change recipient")
                    .accessibilityHint("Double tap to select a different recipient")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Button(LocalizationHelper.Encrypt.selectContact) {
                            viewModel.showingContactPicker = true
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Select contact recipient")
                        .accessibilityHint("Double tap to choose a contact from your list")
                        
                        if !viewModel.isContactRequired {
                            Button(LocalizationHelper.Encrypt.useRawKey) {
                                viewModel.showRawKeyInput()
                            }
                            .buttonStyle(.plain)
                            .font(.scaledCaption)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Use raw public key")
                            .accessibilityHint("Double tap to enter a raw public key instead")
                        }
                    }
                }
            }
            .padding()
            .background(Color.accessibleSecondaryBackground)
            .cornerRadius(8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LocalizationHelper.Accessibility.contactSelector)
    }
    
    private var messageInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationHelper.Encrypt.message)
                .font(.scaledHeadline)
            
            TextEditor(text: $viewModel.messageText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.accessibleSecondaryBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .accessibilityLabel(LocalizationHelper.Accessibility.messageInput)
                .accessibilityHint("Enter the message you want to encrypt")
                .dynamicTypeSupport(.body)
        }
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationHelper.Encrypt.options)
                .font(.scaledHeadline)
            
            Toggle(LocalizationHelper.Encrypt.includeSignature, isOn: $viewModel.includeSignature)
                .disabled(viewModel.isSignatureRequired)
                .accessibilityLabel("Include digital signature")
                .accessibilityHint(viewModel.isSignatureRequired ? "Signature is required by policy" : "Toggle to include or exclude digital signature")
                .dynamicTypeSupport(.body)
            
            if viewModel.isSignatureRequired {
                Text(LocalizationHelper.Encrypt.signatureRequiredNote)
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(LocalizationHelper.Encrypt.encryptMessage) {
                Task {
                    await viewModel.encryptMessage()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canEncrypt)
            .frame(minHeight: AccessibilityConstants.minimumTouchTarget)
            .accessibilityLabel(LocalizationHelper.Accessibility.encryptButton)
            .accessibilityHint(LocalizationHelper.Accessibility.hintEncryptButton)
            .dynamicTypeSupport(.body)
            
            if viewModel.encryptedMessage != nil {
                HStack(spacing: 12) {
                    Button(LocalizationHelper.Encrypt.share) {
                        viewModel.showingShareSheet = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(minHeight: AccessibilityConstants.minimumTouchTarget)
                    .accessibilityLabel("Share encrypted message")
                    .accessibilityHint("Double tap to share the encrypted message")
                    
                    Button(LocalizationHelper.Encrypt.qrCode) {
                        viewModel.showQRCode()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(minHeight: AccessibilityConstants.minimumTouchTarget)
                    .accessibilityLabel("Show QR code")
                    .accessibilityHint("Double tap to display message as QR code")
                    
                    Button(LocalizationHelper.Encrypt.copy) {
                        viewModel.copyToClipboard()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(minHeight: AccessibilityConstants.minimumTouchTarget)
                    .accessibilityLabel("Copy to clipboard")
                    .accessibilityHint("Double tap to copy encrypted message to clipboard")
                }
                .dynamicTypeSupport(.body)
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
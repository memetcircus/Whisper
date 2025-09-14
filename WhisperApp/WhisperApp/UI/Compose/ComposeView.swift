import SwiftUI
import UniformTypeIdentifiers

/// Main view for composing and encrypting messages
/// Provides identity selection, contact picker, encryption flow, and sharing options
struct ComposeView: View {
    @StateObject private var viewModel = ComposeViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isMessageFieldFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with app context
                    headerSection

                    // Identity Selection Section
                    identitySelectionSection

                    // Recipient Selection Section
                    recipientSelectionSection

                    // Message Input Section
                    messageInputSection

                    // Action Buttons
                    actionButtonsSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Compose Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .accessibilityLabel("Cancel compose")
                    .accessibilityHint("Double tap to cancel message composition")
                }

                // Keyboard toolbar for message input
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    if isMessageFieldFocused {
                        Button("Done") {
                            isMessageFieldFocused = false
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert(
                "Biometric Authentication", isPresented: $viewModel.showingBiometricPrompt
            ) {
                Button("Cancel") {
                    viewModel.cancelBiometricAuth()
                }
            } message: {
                Text("Use biometric authentication to sign this message")
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
            .sheet(isPresented: $viewModel.showingIdentityPicker) {
                IdentityPickerView(viewModel: viewModel)
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("End-to-End Encryption")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Your message will be encrypted before sharing")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var identitySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.purple)

                Text("From Identity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            if let activeIdentity = viewModel.activeIdentity {
                Button(action: { viewModel.showIdentityPicker() }) {
                    HStack(spacing: 12) {
                        // Identity icon
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(activeIdentity.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)

                            Text("Rotated \(activeIdentity.createdAt, formatter: dateFormatter)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("Change")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Change sender identity")
                .accessibilityHint("Double tap to select a different identity")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("No Identity Available")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                        Spacer()
                    }

                    Text("Please set up your identity in Settings before proceeding.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Identity selector")
    }

    private var recipientSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)

                Text("To")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            if let selectedContact = viewModel.selectedContact {
                Button(action: { viewModel.showingContactPicker = true }) {
                    HStack(spacing: 12) {
                        // Contact avatar placeholder
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Text(String(selectedContact.displayName.prefix(1)).uppercased())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedContact.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)

                            HStack(spacing: 8) {
                                Text("Verified")
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)

                                Text(selectedContact.shortFingerprint)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Text("Change")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Change recipient")
                .accessibilityHint("Double tap to select a different recipient")
            } else {
                Button(action: { viewModel.showingContactPicker = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)

                        Text("Select Contact")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Select contact recipient")
                .accessibilityHint("Double tap to choose a contact from your list")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Contact selector")
    }

    private var messageInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)

                Text("Message")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                // Character count indicator
                HStack(spacing: 4) {
                    if viewModel.remainingCharacters < 1000 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }

                    Text("\(viewModel.characterCount)/40,000")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(
                            viewModel.remainingCharacters < 1000 ? .orange : .secondary)
                }
            }

            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isMessageFieldFocused ? Color.blue : Color(.systemGray5),
                                lineWidth: isMessageFieldFocused ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isMessageFieldFocused
                            ? Color.blue.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isMessageFieldFocused ? 4 : 2,
                        x: 0,
                        y: isMessageFieldFocused ? 2 : 1
                    )

                // Text editor with transparent background
                TextEditor(
                    text: Binding(
                        get: { viewModel.messageText },
                        set: { viewModel.updateMessageText($0) }
                    )
                )
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(minHeight: 200)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .focused($isMessageFieldFocused)
                .accessibilityLabel("Message input field")
                .accessibilityHint("Enter the message you want to encrypt")

                // Placeholder text - positioned on top
                if viewModel.messageText.isEmpty {
                    Text("Type your message here!")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isMessageFieldFocused)
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Show encrypt button only when no encrypted message exists
            if viewModel.showEncryptButton {
                Button(action: {
                    Task {
                        await viewModel.encryptMessage()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .medium))

                        Text("Encrypt Message")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: viewModel.canEncrypt
                                ? [Color.blue, Color.blue.opacity(0.8)]
                                : [Color.gray, Color.gray.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(
                        color: viewModel.canEncrypt ? Color.blue.opacity(0.3) : Color.clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                .disabled(!viewModel.canEncrypt)
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Encrypt message")
                .accessibilityHint("Tap to encrypt the message")
            }

            // Show post-encryption buttons only when encrypted message exists
            if viewModel.showPostEncryptionButtons {
                VStack(spacing: 12) {
                    // Success message
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)

                        Text("Message encrypted successfully!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: { viewModel.showingShareSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 16, weight: .medium))

                                Text("Share")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Share encrypted message")
                        .accessibilityHint("Double tap to share the encrypted message")

                        Button(action: { viewModel.showQRCode() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 16, weight: .medium))

                                Text("QR Code")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Show QR code")
                        .accessibilityHint(
                            "Double tap to display the encrypted message as a QR code")
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Contact Picker View

struct ContactPickerView: View {
    @Binding var selectedContact: Contact?
    @StateObject private var contactManager = ContactListViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header info
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)

                        Text("Only verified contacts are shown")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                }

                // Contact list - only verified contacts
                if contactManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)

                        Text("Loading contacts...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if verifiedContacts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            Text("No Verified Contacts")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(
                                "Add and verify contacts in the Contacts tab to send secure messages."
                            )
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(verifiedContacts, id: \.id) { contact in
                            ContactPickerRowView(
                                contact: contact,
                                isSelected: selectedContact?.id == contact.id,
                                onTap: {
                                    selectedContact = contact
                                    dismiss()
                                })
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .onAppear {
                contactManager.loadContacts()
            }
        }
    }

    private var verifiedContacts: [Contact] {
        return contactManager.contacts.filter { $0.trustLevel == .verified }
    }
}

// MARK: - Contact Picker Row View

struct ContactPickerRowView: View {
    let contact: Contact
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Text(String(contact.displayName.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                }

                // Contact info
                VStack(alignment: .leading, spacing: 6) {
                    Text(contact.displayName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text("Verified")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)

                        Text(contact.shortFingerprint)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.system(size: 24))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(contact.displayName)
        .accessibilityHint("Double tap to select this contact for encryption")
        .accessibilityAddTraits(.isButton)
    }
}

// ContactRowView is defined in ContactListView.swift
// ShareSheet is defined in QRCodeDisplayView.swift

// MARK: - Identity Picker View

struct IdentityPickerView: View {
    @ObservedObject var viewModel: ComposeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.availableIdentities.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            Text("No Identities Available")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Create an identity in Settings to start encrypting messages.")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        let activeIdentities = viewModel.availableIdentities.filter {
                            $0.status == .active
                        }
                        let archivedIdentities = viewModel.availableIdentities.filter {
                            $0.status == .archived
                        }

                        if !activeIdentities.isEmpty {
                            Section {
                                ForEach(activeIdentities, id: \.id) { identity in
                                    identityRow(for: identity, isActive: true)
                                }
                            } header: {
                                Text("Active Identities")
                            } footer: {
                                Text("Active identities can be used for encryption")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if !archivedIdentities.isEmpty {
                            Section {
                                ForEach(archivedIdentities, id: \.id) { identity in
                                    identityRow(for: identity, isActive: false)
                                }
                            } header: {
                                Text("Archived Identities")
                            } footer: {
                                Text("Archived identities are kept for decryption only")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Select Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingIdentityPicker = false
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .onAppear {
                // Ensure identities are loaded when view appears
                viewModel.showIdentityPicker()
            }
        }
    }

    private func identityRow(for identity: Identity, isActive: Bool) -> some View {
        Button(action: {
            viewModel.selectIdentity(identity)
            dismiss()
        }) {
            HStack(spacing: 16) {
                // Identity icon
                ZStack {
                    Circle()
                        .fill(isActive ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: isActive ? "person.circle.fill" : "archivebox.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isActive ? .purple : .gray)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(identity.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(isActive ? "Active" : "Archived")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isActive ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(4)

                        Text("Created: \(identity.createdAt, formatter: dateFormatter)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if viewModel.activeIdentity?.id == identity.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.system(size: 24))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

// MARK: - Preview

struct ComposeView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeView()
    }
}

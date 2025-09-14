import CoreData
import SwiftUI

// MARK: - Contact List View
struct ContactListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ContactListViewModel()
    @State private var showingAddContact = false
    @State private var showingContactDetail: Contact?
    @State private var searchText = ""
    @State private var showingKeyRotationWarning = false
    @State private var keyRotationContact: Contact?

    var body: some View {
        NavigationView {
            mainContent
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            searchBarSection
            contactListSection
        }
        .navigationTitle(LocalizationHelper.Contact.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddContact = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(LocalizationHelper.Contact.addTitle)
                .accessibilityHint("Double tap to add a new contact")
            }
        }
        .keyRotationWarning(
            isShowing: $showingKeyRotationWarning,
            contact: keyRotationContact,
            onReVerify: {
                if let contact = keyRotationContact {
                    showingContactDetail = contact
                }
            }
        )
        .sheet(isPresented: $showingAddContact) {
            AddContactView { newContact in
                viewModel.addContact(newContact)
            }
        }
        .sheet(item: $showingContactDetail) { contact in
            ContactDetailView(contact: contact) { updatedContact in
                viewModel.updateContact(updatedContact)
            }
        }
        .onAppear {
            viewModel.loadContacts()
            checkForKeyRotations()
        }
        .onChange(of: viewModel.contacts) { oldValue, newValue in
            checkForKeyRotations()
        }
    }

    private var searchBarSection: some View {
        SearchBar(text: $searchText, placeholder: LocalizationHelper.Contact.searchPlaceholder)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    private var contactListSection: some View {
        List {
            ForEach(filteredContacts, id: \.id) { contact in
                ContactRowView(contact: contact) {
                    showingContactDetail = contact
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    trailingSwipeActions(for: contact)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    leadingSwipeActions(for: contact)
                }
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshContacts()
        }
    }

    private var addContactButton: some View {
        Button(action: { showingAddContact = true }) {
            Image(systemName: "plus")
        }
        .accessibilityLabel(LocalizationHelper.Contact.addTitle)
        .accessibilityHint("Double tap to add a new contact")
    }

    @ViewBuilder
    private func trailingSwipeActions(for contact: Contact) -> some View {
        // Block/Unblock action
        Button(
            contact.isBlocked
                ? LocalizationHelper.Contact.unblockTitle
                : LocalizationHelper.Contact.blockTitle
        ) {
            toggleBlockStatus(for: contact)
        }
        .tint(contact.isBlocked ? .green : .orange)  // Changed from .red to .orange
        .accessibilityLabel(
            contact.isBlocked
                ? "Unblock \(contact.displayName)"
                : "Block \(contact.displayName)"
        )

        // Delete action - keep red for destructive action
        Button(LocalizationHelper.delete, role: .destructive) {
            deleteContact(contact)
        }
        .tint(.red)  // Explicitly set red for delete
        .accessibilityLabel("Delete \(contact.displayName)")
    }

    @ViewBuilder
    private func leadingSwipeActions(for contact: Contact) -> some View {
        // Verify action
        if contact.trustLevel != .verified {
            Button(LocalizationHelper.Contact.verifyTitle) {
                showingContactDetail = contact
            }
            .tint(.blue)
            .accessibilityLabel("Verify \(contact.displayName)")
        }
    }

    // MARK: - Computed Properties
    private var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return viewModel.contacts
        } else {
            return viewModel.searchContacts(query: searchText)
        }
    }

    // MARK: - Actions
    private func toggleBlockStatus(for contact: Contact) {
        do {
            if contact.isBlocked {
                try viewModel.unblockContact(contact.id)
            } else {
                try viewModel.blockContact(contact.id)
            }
        } catch {
            // TODO: Show error alert
            print("Error toggling block status: \(error)")
        }
    }

    private func deleteContact(_ contact: Contact) {
        do {
            try viewModel.deleteContact(contact.id)
        } catch {
            // TODO: Show error alert
            print("Error deleting contact: \(error)")
        }
    }

    private func checkForKeyRotations() {
        // Check for contacts that need key rotation warnings
        for contact in viewModel.contacts {
            if viewModel.needsKeyRotationWarning(for: contact) {
                keyRotationContact = contact
                showingKeyRotationWarning = true
                break
            }
        }
    }
}

// MARK: - Contact Row View
struct ContactRowView: View {
    let contact: Contact
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ContactAvatarView(contact: contact)

                // Contact info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(contact.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Trust badge
                        TrustBadgeView(trustLevel: contact.trustLevel)
                    }

                    HStack {
                        Text("ID: \(contact.shortFingerprint)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if contact.isBlocked {
                            Text(LocalizationHelper.Contact.blockedBadge)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                                .accessibilityLabel(LocalizationHelper.Accessibility.trustBadgeBlocked())
                        }
                        
                        if contact.needsReVerification {
                            HStack(spacing: 2) {
                                Image(systemName: "key.fill")
                                    .font(.caption2)
                                Text("Re-verify Required")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                            .accessibilityLabel("Key rotation detected, re-verification required")
                        }
                    }
                    
                    if let lastSeen = contact.lastSeenAt {
                        Text("\(LocalizationHelper.Contact.lastSeen): \(lastSeen, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(contact.displayName), \(contact.trustLevel.displayName)")
        .accessibilityHint("Double tap to view contact details")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Contact Avatar View
struct ContactAvatarView: View {
    let contact: Contact

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)
            
            Text(initials)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .accessibilityLabel(LocalizationHelper.Accessibility.contactAvatar(contact.displayName))
        .accessibilityAddTraits(.isImage)
    }

    private var initials: String {
        let components = contact.displayName.components(separatedBy: CharacterSet.whitespaces)
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }

    private var avatarColor: Color {
        // Generate consistent color based on contact ID
        let hash = contact.id.hashValue
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .indigo, .teal]
        return colors[abs(hash) % colors.count]
    }
}

// MARK: - Trust Badge View
struct TrustBadgeView: View {
    let trustLevel: TrustLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            
            Text(trustLevel.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor)
        .cornerRadius(8)
        .accessibilityLabel(trustLevel.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var iconName: String {
        switch trustLevel {
        case .verified:
            return "checkmark.shield.fill"
        case .unverified:
            return "questionmark.circle.fill"
        case .revoked:
            return "xmark.shield.fill"
        }
    }

    private var textColor: Color {
        switch trustLevel {
        case .verified:
            return .green
        case .unverified:
            return .orange
        case .revoked:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch trustLevel {
        case .verified:
            return .green.opacity(0.1)
        case .unverified:
            return .orange.opacity(0.1)
        case .revoked:
            return .red.opacity(0.1)
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .accessibilityLabel("Search contacts")
                .accessibilityHint("Enter text to search for contacts")

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
                .accessibilityHint("Double tap to clear search text")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Previews
struct ContactListView_Previews: PreviewProvider {
    static var previews: some View {
        ContactListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
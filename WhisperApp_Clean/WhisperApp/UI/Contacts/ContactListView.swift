import SwiftUI
import CoreData

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
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText, placeholder: LocalizationHelper.Contact.searchPlaceholder)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Contact list
                List {
                    ForEach(filteredContacts, id: \.id) { contact in
                        ContactRowView(contact: contact) {
                            showingContactDetail = contact
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Block/Unblock action
                            Button(contact.isBlocked ? LocalizationHelper.Contact.unblockTitle : LocalizationHelper.Contact.blockTitle) {
                                toggleBlockStatus(for: contact)
                            }
                            .tint(contact.isBlocked ? .green : .red)
                            .accessibilityLabel(contact.isBlocked ? "Unblock \(contact.displayName)" : "Block \(contact.displayName)")
                            
                            // Delete action
                            Button(LocalizationHelper.delete, role: .destructive) {
                                deleteContact(contact)
                            }
                            .accessibilityLabel("Delete \(contact.displayName)")
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            // Verify action
                            if contact.trustLevel != .verified {
                                Button(LocalizationHelper.Contact.verifyTitle) {
                                    showingContactDetail = contact
                                }
                                .tint(.blue)
                                .accessibilityLabel("Verify \(contact.displayName)")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.refreshContacts()
                }
            }
            .navigationTitle(LocalizationHelper.Contact.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddContact = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(LocalizationHelper.Contact.addTitle)
                    .accessibilityHint("Double tap to add a new contact")
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(LocalizationHelper.Contact.exportKeybook) {
                            exportKeybook()
                        }
                        
                        Button(LocalizationHelper.Contact.importContacts) {
                            // TODO: Implement import functionality
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Contact options menu")
                    .accessibilityHint("Double tap to open contact management options")
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
            .onChange(of: viewModel.contacts) { _ in
                checkForKeyRotations()
            }
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
    
    private func exportKeybook() {
        do {
            let keybookData = try viewModel.exportKeybook()
            // TODO: Present share sheet with keybook data
            print("Exported keybook: \(keybookData.count) bytes")
        } catch {
            // TODO: Show error alert
            print("Error exporting keybook: \(error)")
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
                            .font(.scaledHeadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Trust badge
                        TrustBadgeView(trustLevel: contact.trustLevel)
                    }
                    
                    HStack {
                        Text("ID: \(contact.shortFingerprint)")
                            .font(.scaledCaption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if contact.isBlocked {
                            Text(LocalizationHelper.Contact.blockedBadge)
                                .font(.scaledCaption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                                .accessibilityLabel(LocalizationHelper.Accessibility.trustBadgeBlocked())
                        }
                        
                        if let lastSeen = contact.lastSeenAt {
                            Text("\(LocalizationHelper.Contact.lastSeen): \(lastSeen, style: .relative)")
                                .font(.scaledCaption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .contactRowAccessibility(for: contact)
        .dynamicTypeSupport(.body)
    }
}

// MARK: - Contact Avatar View

struct ContactAvatarView: View {
    let contact: Contact
    
    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: AccessibilityConstants.minimumTouchTarget, 
                       height: AccessibilityConstants.minimumTouchTarget)
            
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
                .font(.scaledCaption2)
            
            Text(trustLevel.displayName)
                .font(.scaledCaption2)
                .fontWeight(.medium)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor)
        .cornerRadius(8)
        .trustBadgeAccessibility(for: trustLevel)
        .dynamicTypeSupport(.caption2)
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
                .dynamicTypeSupport(.body)
            
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
        .background(Color.accessibleSecondaryBackground)
        .cornerRadius(10)
    }
}

// MARK: - Preview

struct ContactListView_Previews: PreviewProvider {
    static var previews: some View {
        ContactListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
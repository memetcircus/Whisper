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
                SearchBar(text: $searchText, placeholder: "Search contacts...")
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
                            Button(contact.isBlocked ? "Unblock" : "Block") {
                                toggleBlockStatus(for: contact)
                            }
                            .tint(contact.isBlocked ? .green : .red)
                            
                            // Delete action
                            Button("Delete", role: .destructive) {
                                deleteContact(contact)
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            // Verify action
                            if contact.trustLevel != .verified {
                                Button("Verify") {
                                    showingContactDetail = contact
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.refreshContacts()
                }
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddContact = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Export Keybook") {
                            exportKeybook()
                        }
                        
                        Button("Import Contacts") {
                            // TODO: Implement import functionality
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
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
                            Text("Blocked")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if let lastSeen = contact.lastSeenAt {
                            Text("Last seen: \(lastSeen, style: .relative)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Contact Avatar View

struct ContactAvatarView: View {
    let contact: Contact
    
    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 40, height: 40)
            
            Text(initials)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var initials: String {
        let components = contact.displayName.components(separatedBy: .whitespaces)
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
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
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
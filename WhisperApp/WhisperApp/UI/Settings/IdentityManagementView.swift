import SwiftUI

struct IdentityManagementView: View {
    @StateObject private var viewModel = IdentityManagementViewModel()
    @State private var showingCreateIdentity = false
    @State private var showingRotateConfirmation = false
    @State private var identityToArchive: Identity?
    
    var body: some View {
        List {
            // Active Identity Section
            Section("Active Identity") {
                if let activeIdentity = viewModel.activeIdentity {
                    IdentityRowView(identity: activeIdentity, isActive: true) {
                        // Active identity actions
                        Button("Rotate Keys") {
                            showingRotateConfirmation = true
                        }
                        .foregroundColor(.orange)
                    }
                } else {
                    Text("No active identity")
                        .foregroundColor(.secondary)
                }
            }
            
            // All Identities Section
            Section("All Identities") {
                ForEach(viewModel.identities) { identity in
                    IdentityRowView(identity: identity, isActive: identity.id == viewModel.activeIdentity?.id) {
                        if identity.status != .active {
                            Button("Activate") {
                                viewModel.setActiveIdentity(identity)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if identity.status == .active {
                            Button("Archive") {
                                identityToArchive = identity
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Identity Management")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Create New") {
                    showingCreateIdentity = true
                }
            }
        }
        .sheet(isPresented: $showingCreateIdentity) {
            CreateIdentityView { name in
                viewModel.createIdentity(name: name)
            }
        }
        .alert("Rotate Keys", isPresented: $showingRotateConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Rotate", role: .destructive) {
                viewModel.rotateActiveIdentity()
            }
        } message: {
            Text("This will create a new identity and optionally archive the current one based on your auto-archive policy. This action cannot be undone.")
        }
        .alert("Archive Identity", isPresented: .constant(identityToArchive != nil)) {
            Button("Cancel", role: .cancel) {
                identityToArchive = nil
            }
            Button("Archive", role: .destructive) {
                if let identity = identityToArchive {
                    viewModel.archiveIdentity(identity)
                    identityToArchive = nil
                }
            }
        } message: {
            Text("Archiving will make this identity decrypt-only. You won't be able to send new messages with it.")
        }
        .onAppear {
            viewModel.loadIdentities()
        }
    }
}

struct IdentityRowView<Actions: View>: View {
    let identity: Identity
    let isActive: Bool
    @ViewBuilder let actions: () -> Actions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(identity.name)
                            .font(.headline)
                        
                        if isActive {
                            Text("ACTIVE")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Text(identity.status.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Created: \(identity.createdAt, formatter: DateFormatter.short)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Fingerprint: \(identity.shortFingerprint)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospaced()
                }
                
                Spacer()
            }
            
            HStack {
                actions()
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateIdentityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var identityName = ""
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Identity Details") {
                    TextField("Identity Name", text: $identityName)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section {
                    Text("This will create a new cryptographic identity with X25519 and Ed25519 key pairs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onCreate(identityName)
                        dismiss()
                    }
                    .disabled(identityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

extension IdentityStatus {
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .archived:
            return "Archived"
        case .rotated:
            return "Rotated"
        }
    }
}

extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    NavigationView {
        IdentityManagementView()
    }
}
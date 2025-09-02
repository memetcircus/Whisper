import SwiftUI
import UniformTypeIdentifiers

struct BackupRestoreView: View {
    @StateObject private var viewModel = BackupRestoreViewModel()
    @State private var showingBackupSheet = false
    @State private var showingRestoreSheet = false
    @State private var showingDocumentPicker = false
    
    var body: some View {
        List {
            Section("Identity Backup") {
                Button("Create Backup") {
                    showingBackupSheet = true
                }
                .disabled(viewModel.identities.isEmpty)
                
                Text("Create encrypted backups of your identities for safekeeping.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Identity Restore") {
                Button("Restore from Backup") {
                    showingDocumentPicker = true
                }
                
                Text("Restore identities from encrypted backup files.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Available Identities") {
                if viewModel.identities.isEmpty {
                    Text("No identities available")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(viewModel.identities) { identity in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(identity.name)
                                .font(.headline)
                            
                            Text("Created: \(identity.createdAt, formatter: DateFormatter.short)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Status: \(identity.status.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if let successMessage = viewModel.successMessage {
                Section("Success") {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingBackupSheet) {
            BackupIdentitySheet(
                identities: viewModel.identities,
                onBackup: { identity, passphrase in
                    viewModel.createBackup(identity: identity, passphrase: passphrase)
                }
            )
        }
        .sheet(isPresented: $showingRestoreSheet) {
            RestoreIdentitySheet(
                onRestore: { backupData, passphrase in
                    viewModel.restoreFromBackup(data: backupData, passphrase: passphrase)
                }
            )
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleFileImport(result: result)
        }
        .onAppear {
            viewModel.loadIdentities()
        }
    }
}

struct BackupIdentitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIdentity: Identity?
    @State private var passphrase = ""
    @State private var confirmPassphrase = ""
    @State private var showingShareSheet = false
    @State private var backupData: Data?
    
    let identities: [Identity]
    let onBackup: (Identity, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Select Identity") {
                    Picker("Identity", selection: $selectedIdentity) {
                        Text("Select an identity").tag(nil as Identity?)
                        ForEach(identities) { identity in
                            Text(identity.name).tag(identity as Identity?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Encryption Passphrase") {
                    SecureField("Passphrase", text: $passphrase)
                    SecureField("Confirm Passphrase", text: $confirmPassphrase)
                    
                    Text("Choose a strong passphrase to encrypt your backup. This cannot be recovered if lost.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        if let identity = selectedIdentity {
                            onBackup(identity, passphrase)
                            dismiss()
                        }
                    }
                    .disabled(!canCreateBackup)
                }
            }
        }
    }
    
    private var canCreateBackup: Bool {
        selectedIdentity != nil &&
        !passphrase.isEmpty &&
        passphrase == confirmPassphrase &&
        passphrase.count >= 8
    }
}

struct RestoreIdentitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var passphrase = ""
    @State private var backupData: Data?
    @State private var showingDocumentPicker = false
    
    let onRestore: (Data, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Backup File") {
                    Button("Select Backup File") {
                        showingDocumentPicker = true
                    }
                    
                    if backupData != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Backup file selected")
                        }
                    }
                }
                
                Section("Decryption Passphrase") {
                    SecureField("Passphrase", text: $passphrase)
                    
                    Text("Enter the passphrase used to encrypt this backup.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Restore Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        if let data = backupData {
                            onRestore(data, passphrase)
                            dismiss()
                        }
                    }
                    .disabled(backupData == nil || passphrase.isEmpty)
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        backupData = try Data(contentsOf: url)
                    } catch {
                        // Handle error
                    }
                }
            case .failure:
                break
            }
        }
    }
}

#Preview {
    NavigationView {
        BackupRestoreView()
    }
}
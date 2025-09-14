import SwiftUI
import UniformTypeIdentifiers

// Enhanced button styles for better UX
struct ModernBackupButtonStyle: ButtonStyle {
    let color: Color
    let isDisabled: Bool
    
    init(color: Color, isDisabled: Bool = false) {
        self.color = color
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDisabled ? Color.gray : color)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ModernBackupButtonStyle {
    static func modernBackup(color: Color, isDisabled: Bool = false) -> ModernBackupButtonStyle {
        ModernBackupButtonStyle(color: color, isDisabled: isDisabled)
    }
}

struct BackupRestoreView: View {
    @StateObject private var viewModel = BackupRestoreViewModel()
    @State private var showingBackupSheet = false
    @State private var showingRestoreSheet = false
    @State private var showingDocumentPicker = false

    var body: some View {
        List {
            // Header Section
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Backup & Restore")
                                .font(.headline)
                            Text("Secure your cryptographic identities")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Identity Backup Section
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text("Create encrypted backups of your identities for safekeeping.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        showingBackupSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Create Backup")
                        }
                    }
                    .buttonStyle(.modernBackup(color: .blue, isDisabled: viewModel.identities.isEmpty))
                    .disabled(viewModel.identities.isEmpty)
                }
                .padding(.vertical, 4)
            } header: {
                HStack {
                    Image(systemName: "externaldrive.badge.plus")
                        .foregroundColor(.blue)
                    Text("Identity Backup")
                        .font(.system(.subheadline, weight: .semibold))
                }
            }

            // Identity Restore Section
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        
                        Text("Restore identities from encrypted backup files.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                                .font(.title3)
                            Text("Restore from Backup")
                        }
                    }
                    .buttonStyle(.modernBackup(color: .green))
                }
                .padding(.vertical, 4)
            } header: {
                HStack {
                    Image(systemName: "externaldrive.badge.minus")
                        .foregroundColor(.green)
                    Text("Identity Restore")
                        .font(.system(.subheadline, weight: .semibold))
                }
            }

            // Available Identities Section
            Section {
                if viewModel.identities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.dashed")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("No Identities Available")
                            .font(.headline)
                        Text("Create an identity first to enable backup functionality")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(viewModel.identities) { identity in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(identity.name)
                                        .font(.headline)
                                    
                                    // Status badge
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(statusColor(for: identity.status))
                                            .frame(width: 8, height: 8)
                                        
                                        Text(identity.status.displayName)
                                            .font(.system(.caption, weight: .medium))
                                            .foregroundColor(statusColor(for: identity.status))
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            // Details section
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .frame(width: 16)
                                Text("Created: \(identity.createdAt, formatter: DateFormatter.short)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.purple)
                    Text("Available Identities")
                        .font(.system(.subheadline, weight: .semibold))
                }
            }

            // Error Message Section
            if let errorMessage = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // Success Message Section
            if let successMessage = viewModel.successMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(successMessage)
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingBackupSheet) {
            EnhancedBackupIdentitySheet(
                identities: viewModel.identities,
                onBackup: { identity, passphrase in
                    viewModel.createBackup(identity: identity, passphrase: passphrase)
                }
            )
        }
        .sheet(isPresented: $viewModel.showingRestoreSheet) {
            EnhancedRestoreIdentitySheet(
                backupData: viewModel.backupData,
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
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let shareURL = viewModel.shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }
    
    // Helper function for status colors
    private func statusColor(for status: IdentityStatus) -> Color {
        switch status {
        case .active:
            return .green
        case .archived:
            return .orange
        case .rotated:
            return .gray
        }
    }
}

struct EnhancedBackupIdentitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIdentity: Identity?
    @State private var passphrase = ""
    @State private var confirmPassphrase = ""
    
    let identities: [Identity]
    let onBackup: (Identity, String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "externaldrive.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Create Backup")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create an encrypted backup of your identity for safekeeping")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Select Identity Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECT IDENTITY")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Picker("Identity", selection: $selectedIdentity) {
                        Text("Select an identity").tag(nil as Identity?)
                        ForEach(identities) { identity in
                            Text(identity.name).tag(identity as Identity?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Encryption Passphrase Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("ENCRYPTION PASSPHRASE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        SecureField("Passphrase", text: $passphrase)
                            .textFieldStyle(.roundedBorder)
                        
                        SecureField("Confirm Passphrase", text: $confirmPassphrase)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal)
                
                // Warning Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Important")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    Text("Choose a strong passphrase to encrypt your backup. This cannot be recovered if lost.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
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
                    .fontWeight(.semibold)
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

struct EnhancedRestoreIdentitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var passphrase = ""
    
    let backupData: Data?
    let onRestore: (Data, String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "externaldrive.badge.minus")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Restore Backup")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Restore your identity from an encrypted backup file")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Backup File Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("BACKUP FILE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Backup file loaded successfully")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Decryption Passphrase Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("DECRYPTION PASSPHRASE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        SecureField("Passphrase", text: $passphrase)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Enter the passphrase used to encrypt this backup.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal)
                
                Spacer()
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
                    .fontWeight(.semibold)
                    .disabled(backupData == nil || passphrase.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        BackupRestoreView()
    }
}
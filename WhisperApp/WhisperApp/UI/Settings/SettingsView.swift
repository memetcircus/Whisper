import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingLegalDisclaimer = false

    var body: some View {
        NavigationView {
            List {
                // Security Section
                Section {
                    SettingsToggleRow(
                        icon: "arrow.clockwise.circle.fill",
                        iconColor: .blue,
                        title: "Auto-Archive on Rotation",
                        description: "Automatically archives old identities after key rotation",
                        isOn: $viewModel.autoArchiveOnRotation
                    )
                } header: {
                    Text("Message Security")
                } footer: {
                    Text("Security settings that affect message encryption and key management.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Identity & Keys Section
                Section {
                    SettingsNavigationRow(
                        icon: "person.badge.key.fill",
                        iconColor: .purple,
                        title: "Manage Identities",
                        description: "Create, rotate, and manage your encryption identities"
                    ) {
                        IdentityManagementView()
                    }

                    SettingsNavigationRow(
                        icon: "externaldrive.fill",
                        iconColor: .green,
                        title: "Backup & Restore",
                        description: "Backup your identities and restore from previous backups"
                    ) {
                        BackupRestoreView()
                    }
                } header: {
                    Text("Identity Management")
                } footer: {
                    Text("Manage your encryption identities and create secure backups.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Authentication Section
                Section {
                    SettingsNavigationRow(
                        icon: "faceid",
                        iconColor: .orange,
                        title: "Face ID Settings",
                        description: "Configure Face ID authentication for encryption"
                    ) {
                        BiometricSettingsView()
                    }
                } header: {
                    Text("Face ID Authentication")
                } footer: {
                    Text("Use Face ID authentication to secure your encryption keys.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Data Section
                Section {
                    SettingsNavigationRow(
                        icon: "square.and.arrow.up.fill",
                        iconColor: .indigo,
                        title: "Export/Import",
                        description: "Share public keys and import contacts"
                    ) {
                        ExportImportView()
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Export your public keys to share with contacts or import theirs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Legal Section
                Section {
                    SettingsActionRow(
                        icon: "doc.text.fill",
                        iconColor: .gray,
                        title: "View Legal Disclaimer",
                        description: "Privacy policy and terms of use"
                    ) {
                        showingLegalDisclaimer = true
                    }
                } header: {
                    Text("Legal")
                } footer: {
                    Text("Review the legal disclaimer and privacy information.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .sheet(isPresented: $showingLegalDisclaimer) {
            LegalDisclaimerView(isFirstLaunch: false)
        }
    }
}

// MARK: - Settings Row Components

struct SettingsNavigationRow<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct SettingsActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
}

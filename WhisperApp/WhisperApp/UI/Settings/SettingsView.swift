import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingLegalDisclaimer = false
    
    var body: some View {
        NavigationView {
            List {
                // Security Policies Section
                Section("Security Policies") {
                    Toggle("Contact Required to Send", isOn: $viewModel.contactRequiredToSend)
                        .help("Blocks sending to raw keys, requires recipient selection from contacts")
                    
                    Toggle("Require Signature for Verified", isOn: $viewModel.requireSignatureForVerified)
                        .help("Mandates signatures for all messages to verified contacts")
                    
                    Toggle("Auto-Archive on Rotation", isOn: $viewModel.autoArchiveOnRotation)
                        .help("Automatically archives old identities after key rotation")
                    
                    Toggle("Biometric-Gated Signing", isOn: $viewModel.biometricGatedSigning)
                        .help("Requires Face ID/Touch ID for every signature operation")
                }
                
                // Identity Management Section
                Section("Identity Management") {
                    NavigationLink("Manage Identities") {
                        IdentityManagementView()
                    }
                    
                    NavigationLink("Backup & Restore") {
                        BackupRestoreView()
                    }
                }
                
                // Biometric Settings Section
                Section("Biometric Authentication") {
                    NavigationLink("Biometric Settings") {
                        BiometricSettingsView()
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    NavigationLink("Export/Import") {
                        ExportImportView()
                    }
                }
                
                // Legal Section
                Section("Legal") {
                    Button("View Legal Disclaimer") {
                        showingLegalDisclaimer = true
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingLegalDisclaimer) {
            LegalDisclaimerView(isFirstLaunch: false)
        }
    }
}

#Preview {
    SettingsView()
}
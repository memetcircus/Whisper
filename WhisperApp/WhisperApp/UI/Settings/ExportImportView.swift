import SwiftUI
import UniformTypeIdentifiers

struct ExportImportView: View {
    @StateObject private var viewModel = ExportImportViewModel()
    @State private var showingContactExport = false
    @State private var showingContactImport = false
    @State private var showingIdentityExport = false
    
    var body: some View {
        List {
            Section("Contacts") {
                Button("Export Contacts") {
                    viewModel.exportContacts()
                }
                .disabled(viewModel.contacts.isEmpty)
                
                Button("Import Contacts") {
                    showingContactImport = true
                }
                
                Text("Export your contact list as a public keybook or import contacts from other Whisper instances.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Public Key Bundles") {
                Button("Export Identity Public Keys") {
                    showingIdentityExport = true
                }
                .disabled(viewModel.identities.isEmpty)
                
                Text("Export public key bundles for sharing your identity with others.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Statistics") {
                HStack {
                    Text("Contacts")
                    Spacer()
                    Text("\(viewModel.contacts.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Identities")
                    Spacer()
                    Text("\(viewModel.identities.count)")
                        .foregroundColor(.secondary)
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
        .navigationTitle("Export/Import")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingContactImport) {
            ContactImportSheet { data in
                viewModel.importContacts(data: data)
            }
        }
        .sheet(isPresented: $showingIdentityExport) {
            IdentityExportSheet(
                identities: viewModel.identities,
                onExport: { identity in
                    viewModel.exportIdentityPublicBundle(identity: identity)
                }
            )
        }
        .fileImporter(
            isPresented: $showingContactImport,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleContactImport(result: result)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

struct ContactImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var selectedData: Data?
    
    let onImport: (Data) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Import Contacts") {
                    Button("Select Contact File") {
                        showingFilePicker = true
                    }
                    
                    if selectedData != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Contact file selected")
                        }
                    }
                    
                    Text("Select a JSON file containing exported contacts from another Whisper instance.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Import Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        if let data = selectedData {
                            onImport(data)
                            dismiss()
                        }
                    }
                    .disabled(selectedData == nil)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        selectedData = try Data(contentsOf: url)
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

struct IdentityExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIdentity: Identity?
    
    let identities: [Identity]
    let onExport: (Identity) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Select Identity") {
                    Picker("Identity", selection: $selectedIdentity) {
                        Text("Select an identity").tag(nil as Identity?)
                        ForEach(identities) { identity in
                            VStack(alignment: .leading) {
                                Text(identity.name)
                                Text(identity.shortFingerprint)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(identity as Identity?)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section("Information") {
                    Text("This will export the public key bundle for the selected identity. This can be shared with others to allow them to send you encrypted messages.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Export Public Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        if let identity = selectedIdentity {
                            onExport(identity)
                            dismiss()
                        }
                    }
                    .disabled(selectedIdentity == nil)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ExportImportView()
    }
}
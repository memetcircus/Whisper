import SwiftUI
import UniformTypeIdentifiers

// Enhanced button styles for Export/Import
struct ExportImportActionButtonStyle: ButtonStyle {
    let color: Color
    let isDisabled: Bool
    
    init(color: Color, isDisabled: Bool = false) {
        self.color = color
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundColor(isDisabled ? .gray : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDisabled ? Color.gray.opacity(0.1) : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDisabled ? Color.gray.opacity(0.3) : color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ExportImportActionButtonStyle {
    static func exportImportAction(color: Color, isDisabled: Bool = false) -> ExportImportActionButtonStyle {
        ExportImportActionButtonStyle(color: color, isDisabled: isDisabled)
    }
}

struct ExportImportView: View {
    @StateObject private var viewModel = ExportImportViewModel()
    @State private var showingContactExport = false
    @State private var showingContactImport = false
    @State private var showingIdentityExport = false
    @State private var showingPublicKeyImport = false
    @State private var showingDocumentPicker = false

    var body: some View {
        List {
            // Header Section
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export/Import")
                                .font(.headline)
                            Text("Share and receive contacts and public keys")
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

            // Contacts Section
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "person.2.circle.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Text("Export your contact list as a public keybook or import contacts from other Whisper instances.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            viewModel.exportContacts()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.title3)
                                Text("Export Contacts")
                            }
                        }
                        .buttonStyle(.exportImportAction(color: .green, isDisabled: viewModel.contacts.isEmpty))
                        .disabled(viewModel.contacts.isEmpty)
                        
                        Button(action: {
                            print("🔍 UI DEBUG: Import Contacts button tapped")
                            print("🔍 UI DEBUG: Current showingContactImport value: \(showingContactImport)")
                            
                            // Try the fileImporter first
                            showingContactImport = true
                            print("🔍 UI DEBUG: showingContactImport set to true")
                            
                            // Add a small delay and then try DocumentPicker as fallback
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                print("🔍 UI DEBUG: After delay - showingContactImport is: \(showingContactImport)")
                                if showingContactImport {
                                    print("🔍 UI DEBUG: fileImporter didn't trigger, trying DocumentPicker fallback")
                                    showingContactImport = false
                                    showingDocumentPicker = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .font(.title3)
                                Text("Import Contacts")
                            }
                        }
                        .buttonStyle(.exportImportAction(color: .green))
                    }
                }
                .padding(.vertical, 8)
            } header: {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.green)
                    Text("Contacts")
                        .font(.system(.subheadline, weight: .semibold))
                }
            }

            // Public Key Bundles Section
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "key.horizontal.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Export your public keys for sharing, or import someone else's public key bundle to add them as a contact.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            showingIdentityExport = true
                        }) {
                            HStack {
                                Image(systemName: "key.radiowaves.forward.fill")
                                    .font(.title3)
                                Text("Export Identity Public Keys")
                            }
                        }
                        .buttonStyle(.exportImportAction(color: .blue, isDisabled: viewModel.identities.isEmpty))
                        .disabled(viewModel.identities.isEmpty)
                        
                        Button(action: {
                            showingPublicKeyImport = true
                        }) {
                            HStack {
                                Image(systemName: "key.viewfinder")
                                    .font(.title3)
                                Text("Import Public Key Bundle")
                            }
                        }
                        .buttonStyle(.exportImportAction(color: .blue))
                    }
                }
                .padding(.vertical, 8)
            } header: {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.blue)
                    Text("Public Key Bundles")
                        .font(.system(.subheadline, weight: .semibold))
                }
            }

            // Statistics Section
            Section {
                VStack(spacing: 12) {
                    StatisticRowView(
                        icon: "person.2.fill",
                        iconColor: .green,
                        title: "Contacts",
                        value: "\(viewModel.contacts.count)"
                    )
                    
                    StatisticRowView(
                        icon: "person.crop.circle.fill",
                        iconColor: .purple,
                        title: "Identities",
                        value: "\(viewModel.identities.count)"
                    )
                }
                .padding(.vertical, 8)
            } header: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.orange)
                    Text("Statistics")
                        .font(.system(.subheadline, weight: .semibold))
                }
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
        }
        .navigationTitle("Export/Import")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingIdentityExport) {
            EnhancedIdentityExportSheet(
                identities: viewModel.identities,
                onExport: { identity in
                    viewModel.exportIdentityPublicBundle(identity: identity)
                }
            )
        }
        .fileImporter(
            isPresented: $showingContactImport,
            allowedContentTypes: [.json, .plainText, .data, UTType(filenameExtension: "json") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            print("🔍 UI DEBUG: Contact fileImporter callback triggered")
            print("🔍 UI DEBUG: Result type: \(type(of: result))")
            viewModel.handleContactImport(result: result)
        }
        .fileImporter(
            isPresented: $showingPublicKeyImport,
            allowedContentTypes: [UTType(filenameExtension: "wpub") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handlePublicKeyBundleImport(result: result)
        }
        // ✅ Fallback sheet for UIKit document picker (previously missing)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(
                allowedContentTypes: [.json, .plainText, .data],
                onDocumentPicked: { result in
                    viewModel.handleContactImport(result: result)
                }
            )
        }
        .onAppear {
            viewModel.loadDataAndClearMessages()
        }
        .task(id: showingContactImport) {
            print("🔍 UI DEBUG: showingContactImport changed to: \(showingContactImport)")
        }
        .task(id: showingPublicKeyImport) {
            print("🔍 UI DEBUG: showingPublicKeyImport changed to: \(showingPublicKeyImport)")
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let shareURL = viewModel.shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }
}

struct StatisticRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

struct EnhancedIdentityExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIdentity: Identity?
    
    let identities: [Identity]
    let onExport: (Identity) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.radiowaves.forward.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Export Public Keys")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Share your public key bundle with others to allow them to send you encrypted messages")
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
                    .pickerStyle(.wheel)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Show details of selected identity
                    if let selected = selectedIdentity {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "key")
                                    .foregroundColor(.blue)
                                    .frame(width: 16)
                                Text("Fingerprint:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(selected.shortFingerprint)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.green)
                                    .frame(width: 16)
                                Text("Status:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(selected.status.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal)
                
                // Information Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Information")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    Text("This will export the public key bundle for the selected identity. This can be shared with others to allow them to send you encrypted messages.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
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
                    .fontWeight(.semibold)
                    .disabled(selectedIdentity == nil)
                }
            }
        }
    }
}

// MARK: - DocumentPicker for iOS File Access
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onDocumentPicked: (Result<[URL], Error>) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        print("🔍 DOCUMENT PICKER DEBUG: Creating UIDocumentPickerViewController")
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("🔍 DOCUMENT PICKER DEBUG: Documents picked: \(urls)")
            parent.onDocumentPicked(.success(urls))
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("🔍 DOCUMENT PICKER DEBUG: Document picker was cancelled")
            let error = NSError(domain: "DocumentPickerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User cancelled"])
            parent.onDocumentPicked(.failure(error))
        }
    }
}

#Preview {
    NavigationView {
        ExportImportView()
    }
}


import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingComposeView = false
    @State private var showingDecryptView = false
    @State private var showingContactsView = false
    @State private var showingSettingsView = false
    @State private var showingLegalDisclaimer = false
    @AppStorage("whisper.legal.accepted") private var legalAccepted = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Whisper")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Secure End-to-End Encryption")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Main Action Buttons
                VStack(spacing: 16) {
                    Button("Compose Message") {
                        showingComposeView = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Button("Decrypt Message") {
                        showingDecryptView = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Button("Manage Contacts") {
                        showingContactsView = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Button("Settings") {
                        showingSettingsView = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Security Notice
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("No Network • Local Only • Private")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Whisper")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingComposeView) {
            ComposeView()
        }
        .sheet(isPresented: $showingDecryptView) {
            DecryptView()
        }
        .sheet(isPresented: $showingContactsView) {
            ContactListView()
        }
        .sheet(isPresented: $showingSettingsView) {
            SettingsView()
        }
        .sheet(isPresented: $showingLegalDisclaimer) {
            LegalDisclaimerView(isFirstLaunch: true)
        }
        .onAppear {
            // Show legal disclaimer on first launch
            if !legalAccepted {
                showingLegalDisclaimer = true
            }
        }
    }
}

// Placeholder Views for now
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .padding()
                
                Text("Settings interface will be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
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
            VStack {
                Image(systemName: "lock.shield")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 60))
                
                Text("Whisper")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Secure End-to-End Encryption")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
                
                VStack(spacing: 16) {
                    Button("Compose Message") {
                        showingComposeView = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Decrypt Message") {
                        showingDecryptView = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Manage Contacts") {
                        showingContactsView = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Settings") {
                        showingSettingsView = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("Whisper")
        }
        .clipboardBanner() // Add clipboard detection banner
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
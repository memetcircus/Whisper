import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

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
                        // TODO: Navigate to compose view
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Decrypt Message") {
                        // TODO: Navigate to decrypt view
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Manage Contacts") {
                        // TODO: Navigate to contacts view
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Settings") {
                        // TODO: Navigate to settings view
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("Whisper")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
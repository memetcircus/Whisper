import CoreData
import SwiftUI

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
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section with App Icon Design
                        VStack(spacing: 24) {
                            Spacer(minLength: 60)

                            // App Icon
                            Image("Secure_chat_icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)

                            // App Title and Subtitle
                            VStack(spacing: 8) {
                                Text("Whisper")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("Secure End-to-End Encryption")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }

                            Spacer(minLength: 40)
                        }
                        .frame(minHeight: geometry.size.height * 0.5)

                        // Action Buttons Section
                        VStack(spacing: 20) {
                            // Primary Action - Compose
                            Button(action: { showingComposeView = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 20, weight: .medium))
                                    Text("Compose Message")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }

                            // Secondary Actions Grid
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    // Decrypt Message
                                    ActionButton(
                                        icon: "lock.open",
                                        title: "Decrypt",
                                        subtitle: "Message",
                                        color: .green
                                    ) {
                                        showingDecryptView = true
                                    }

                                    // Manage Contacts
                                    ActionButton(
                                        icon: "person.2",
                                        title: "Manage",
                                        subtitle: "Contacts",
                                        color: .orange
                                    ) {
                                        showingContactsView = true
                                    }
                                }

                                // Settings Button (Full Width)
                                Button(action: { showingSettingsView = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "gearshape")
                                            .font(.system(size: 18, weight: .medium))
                                        Text("Settings")
                                            .font(.system(size: 16, weight: .medium))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)
                                    .frame(height: 50)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        // .clipboardBanner() // Clipboard monitoring removed for better testing experience
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

// MARK: - Action Button Component
struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(
            \.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

import SwiftUI

// Enhanced button style for better UX
struct ModernOutlineButtonStyle: ButtonStyle {
    let color: Color
    let isDestructive: Bool
    
    init(color: Color, isDestructive: Bool = false) {
        self.color = color
        self.isDestructive = isDestructive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundColor(isDestructive ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDestructive ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(isDestructive ? 0 : 0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ModernOutlineButtonStyle {
    static func modernOutline(color: Color, isDestructive: Bool = false) -> ModernOutlineButtonStyle {
        ModernOutlineButtonStyle(color: color, isDestructive: isDestructive)
    }
}

struct IdentityManagementView: View {
    @StateObject private var viewModel = IdentityManagementViewModel()
    @State private var showingCreateIdentity = false
    @State private var showingRotateConfirmation = false
    @State private var identityToArchive: Identity?
    @State private var identityToDelete: Identity?

    var body: some View {
        List {
            // Header Section with Create Button
            Section {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Identity Management")
                                .font(.headline)
                            Text("Manage your cryptographic identities")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        showingCreateIdentity = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Create New Identity")
                                .font(.system(.subheadline, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Default Identity Section
            Section {
                if let activeIdentity = viewModel.activeIdentity {
                    EnhancedIdentityRowView(identity: activeIdentity, isDefault: true) {
                        HStack(spacing: 8) {
                            Button("QR Code") {
                                viewModel.generateQRCode(for: activeIdentity)
                            }
                            .buttonStyle(.modernOutline(color: .blue))

                            Button("Rotate Keys") {
                                showingRotateConfirmation = true
                            }
                            .buttonStyle(.modernOutline(color: .orange))
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("No Default Identity")
                            .font(.headline)
                        Text("Create or select an identity to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                }
            } header: {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.blue)
                    Text("Default Identity")
                        .font(.system(.subheadline, weight: .semibold))
                }
            }

            // All Identities Section
            if !viewModel.identities.isEmpty {
                Section {
                    ForEach(viewModel.identities) { identity in
                        EnhancedIdentityRowView(
                            identity: identity, 
                            isDefault: identity.id == viewModel.activeIdentity?.id
                        ) {
                            HStack(spacing: 8) {
                                Button("QR Code") {
                                    viewModel.generateQRCode(for: identity)
                                }
                                .buttonStyle(.modernOutline(color: .blue))

                                if identity.status != .active {
                                    Button("Activate") {
                                        viewModel.setActiveIdentity(identity)
                                    }
                                    .buttonStyle(.modernOutline(color: .green))

                                    Button("Delete") {
                                        identityToDelete = identity
                                    }
                                    .buttonStyle(.modernOutline(color: .red, isDestructive: true))
                                }

                                if identity.status == .active {
                                    if identity.id != viewModel.activeIdentity?.id {
                                        Button("Set Default") {
                                            viewModel.setActiveIdentity(identity)
                                        }
                                        .buttonStyle(.modernOutline(color: .blue))
                                    }

                                    Button("Archive") {
                                        identityToArchive = identity
                                    }
                                    .buttonStyle(.modernOutline(color: .orange))
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.green)
                        Text("All Identities")
                            .font(.system(.subheadline, weight: .semibold))
                    }
                }
            }
        }
        .navigationTitle("Identity Management")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreateIdentity) {
            EnhancedCreateIdentityView(viewModel: viewModel)
        }
        .alert("Rotate Keys", isPresented: $showingRotateConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Rotate", role: .destructive) {
                viewModel.rotateActiveIdentity()
            }
        } message: {
            Text("This will create a new identity and optionally archive the current one based on your auto-archive policy. This action cannot be undone.")
        }
        .alert("Archive Identity", isPresented: .constant(identityToArchive != nil)) {
            Button("Cancel", role: .cancel) {
                identityToArchive = nil
            }
            Button("Archive", role: .destructive) {
                if let identity = identityToArchive {
                    viewModel.archiveIdentity(identity)
                    identityToArchive = nil
                }
            }
        } message: {
            Text("Archiving will make this identity decrypt-only. You won't be able to send new messages with it.")
        }
        .alert("Delete Identity", isPresented: .constant(identityToDelete != nil)) {
            Button("Cancel", role: .cancel) {
                identityToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let identity = identityToDelete {
                    viewModel.deleteIdentity(identity)
                    identityToDelete = nil
                }
            }
        } message: {
            Text("This will permanently delete the identity and its private keys. This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showingQRCode) {
            if let qrResult = viewModel.qrCodeResult {
                QRCodeDisplayView(
                    qrResult: qrResult,
                    title: "Identity QR Code"
                )
            }
        }
        .onAppear {
            viewModel.loadIdentities()
        }
    }
}

struct EnhancedIdentityRowView<Actions: View>: View {
    let identity: Identity
    let isDefault: Bool
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and badges
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        IdentityNameView(name: identity.name)
                        
                        if isDefault && identity.status == .active {
                            Text("DEFAULT")
                                .font(.system(.caption2, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    // Status badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(identity.status.displayName)
                            .font(.system(.caption, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
            }
            
            // Details section with better layout
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .frame(width: 16)
                    Text("Created: \(identity.createdAt, formatter: DateFormatter.short)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "key")
                        .foregroundColor(.green)
                        .frame(width: 16)
                    Text("Fingerprint: \(identity.shortFingerprint)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // Actions
            HStack {
                actions()
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch identity.status {
        case .active:
            return .green
        case .archived:
            return .orange
        case .rotated:
            return .gray
        }
    }
}

struct EnhancedCreateIdentityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var identityName = ""
    @ObservedObject var viewModel: IdentityManagementViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Create New Identity")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Generate a new cryptographic identity for secure messaging")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("IDENTITY DETAILS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextField("Identity Name", text: $identityName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Info Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("What happens next?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRowView(icon: "key.fill", text: "X25519 and Ed25519 key pairs will be generated")
                        InfoRowView(icon: "lock.shield.fill", text: "Keys are stored securely in the Keychain")
                        InfoRowView(icon: "qrcode", text: "QR code will be available for sharing")
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Create Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.errorMessage = nil
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.errorMessage = nil
                        viewModel.createIdentity(name: identityName)
                        
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(identityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct InfoRowView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Identity Name View

struct IdentityNameView: View {
    let name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(baseName)
                .font(.headline)
            
            if let timestamp = rotationTimestamp {
                Text("Rotated \(timestamp)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var baseName: String {
        // Extract base name by removing rotation suffix
        let pattern = #" \(Rotated \d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2})?\)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: name.utf16.count)
        let cleanName = regex.stringByReplacingMatches(in: name, options: [], range: range, withTemplate: "")
        
        return cleanName.isEmpty ? name : cleanName
    }
    
    private var rotationTimestamp: String? {
        // Extract timestamp from rotation suffix
        let pattern = #"\(Rotated (\d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2})?)\)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: name.utf16.count)
        
        if let match = regex.firstMatch(in: name, options: [], range: range) {
            let matchRange = Range(match.range(at: 1), in: name)!
            return String(name[matchRange])
        }
        
        return nil
    }
}

extension IdentityStatus {
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .archived:
            return "Archived"
        case .rotated:
            return "Rotated"
        }
    }
}

extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    NavigationView {
        IdentityManagementView()
    }
}
import SwiftUI

// MARK: - Key Rotation Warning View

struct KeyRotationWarningView: View {
    let contact: Contact
    let onReVerify: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Changed — Re-verify")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(contact.displayName)'s encryption key has changed. Please re-verify to ensure secure communication.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 12) {
                Button("Re-verify Contact") {
                    onReVerify()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange, lineWidth: 1)
        )
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Key Rotation Banner Modifier

struct KeyRotationBannerModifier: ViewModifier {
    @Binding var showingKeyRotationWarning: Bool
    let contact: Contact?
    let onReVerify: () -> Void
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if showingKeyRotationWarning, let contact = contact {
                KeyRotationWarningView(
                    contact: contact,
                    onReVerify: {
                        onReVerify()
                        showingKeyRotationWarning = false
                    },
                    onDismiss: {
                        showingKeyRotationWarning = false
                    }
                )
                .padding(.horizontal)
                .padding(.top)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            content
        }
        .animation(.easeInOut(duration: 0.3), value: showingKeyRotationWarning)
    }
}

extension View {
    func keyRotationWarning(
        isShowing: Binding<Bool>,
        contact: Contact?,
        onReVerify: @escaping () -> Void
    ) -> some View {
        modifier(KeyRotationBannerModifier(
            showingKeyRotationWarning: isShowing,
            contact: contact,
            onReVerify: onReVerify
        ))
    }
}

// MARK: - Preview

struct KeyRotationWarningView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            KeyRotationWarningView(
                contact: sampleContact,
                onReVerify: {},
                onDismiss: {}
            )
            .padding()
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    static var sampleContact: Contact {
        let publicKey = Data(repeating: 0x01, count: 32)
        return try! Contact(
            displayName: "Alice Smith",
            x25519PublicKey: publicKey
        )
    }
}
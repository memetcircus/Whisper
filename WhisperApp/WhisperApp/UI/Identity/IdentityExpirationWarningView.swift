import SwiftUI

/// View that displays warnings for identities approaching key rotation deadlines
/// Shows when identities are within 30 days of recommended rotation (1 year)
struct IdentityExpirationWarningView: View {
    let identities: [Identity]
    let onRotateIdentity: (Identity) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Key Rotation Recommended")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Warning message
            Text("The following identities are approaching their recommended key rotation deadline. For optimal security, consider rotating these keys.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            // Identity list
            LazyVStack(spacing: 12) {
                ForEach(identities, id: \.id) { identity in
                    IdentityExpirationRowView(
                        identity: identity,
                        onRotate: { onRotateIdentity(identity) }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

/// Individual row for each identity needing rotation warning
private struct IdentityExpirationRowView: View {
    let identity: Identity
    let onRotate: () -> Void
    
    private var daysUntilRecommendedRotation: Int {
        let now = Date()
        let timeSinceCreation = now.timeIntervalSince(identity.createdAt)
        let recommendedRotationInterval: TimeInterval = 365 * 24 * 60 * 60 // 1 year
        let timeUntilRotation = recommendedRotationInterval - timeSinceCreation
        return max(0, Int(timeUntilRotation / (24 * 60 * 60)))
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(identity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Created \(formatDate(identity.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if daysUntilRecommendedRotation > 0 {
                    Text("\(daysUntilRecommendedRotation) days until recommended rotation")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Rotation recommended now")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            Button("Rotate") {
                onRotate()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleIdentities = [
        Identity(
            id: UUID(),
            name: "Personal Identity",
            x25519KeyPair: X25519KeyPair(
                privateKey: Curve25519.KeyAgreement.PrivateKey(),
                publicKey: Data(repeating: 0x01, count: 32)
            ),
            ed25519KeyPair: Ed25519KeyPair(
                privateKey: Curve25519.Signing.PrivateKey(),
                publicKey: Data(repeating: 0x02, count: 32)
            ),
            fingerprint: Data(repeating: 0x03, count: 32),
            createdAt: Calendar.current.date(byAdding: .day, value: -340, to: Date()) ?? Date(),
            status: .active,
            keyVersion: 1
        ),
        Identity(
            id: UUID(),
            name: "Work Identity",
            x25519KeyPair: X25519KeyPair(
                privateKey: Curve25519.KeyAgreement.PrivateKey(),
                publicKey: Data(repeating: 0x04, count: 32)
            ),
            ed25519KeyPair: nil,
            fingerprint: Data(repeating: 0x05, count: 32),
            createdAt: Calendar.current.date(byAdding: .day, value: -350, to: Date()) ?? Date(),
            status: .active,
            keyVersion: 1
        )
    ]
    
    IdentityExpirationWarningView(
        identities: sampleIdentities,
        onRotateIdentity: { _ in },
        onDismiss: { }
    )
}
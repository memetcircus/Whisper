import SwiftUI

struct LegalDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("whisper.legal.accepted") private var legalAccepted = false

    let isFirstLaunch: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header Section
                    VStack(alignment: .center, spacing: 12) {
                        Text("Legal Disclaimer")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Important information about using Whisper")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)

                    // Disclaimer Sections
                    VStack(spacing: 28) {
                        ImprovedDisclaimerSection(
                            icon: "exclamationmark.triangle",
                            iconColor: .orange,
                            title: "No Warranty",
                            content:
                                "This software is provided \"as is\" without warranty of any kind, express or implied. The developers make no representations or warranties regarding the security, reliability, or fitness for any particular purpose."
                        )

                        ImprovedDisclaimerSection(
                            icon: "shield.lefthalf.filled",
                            iconColor: .blue,
                            title: "Security Limitations",
                            content:
                                "While this application uses industry-standard cryptographic algorithms, no security system is perfect.",
                            bulletPoints: [
                                "Device compromise may expose private keys",
                                "Implementation bugs may exist despite testing",
                                "Cryptographic algorithms may be broken in the future",
                                "Side-channel attacks may be possible",
                            ]
                        )

                        ImprovedDisclaimerSection(
                            icon: "person.fill.checkmark",
                            iconColor: .green,
                            title: "User Responsibility",
                            content: "Users are responsible for:",
                            bulletPoints: [
                                "Keeping their devices secure and updated",
                                "Protecting their identity backups and passphrases",
                                "Verifying contact identities through secure channels",
                                "Understanding the risks of encrypted communication",
                            ]
                        )

                        ImprovedDisclaimerSection(
                            icon: "globe",
                            iconColor: .purple,
                            title: "Export Compliance",
                            content:
                                "This software contains cryptographic functionality. Export and use may be restricted in some jurisdictions. Users are responsible for compliance with applicable laws and regulations."
                        )

                        ImprovedDisclaimerSection(
                            icon: "scale.3d",
                            iconColor: .red,
                            title: "Limitation of Liability",
                            content:
                                "In no event shall the developers be liable for any damages arising from the use or inability to use this software, including but not limited to data loss, privacy breaches, or communication failures."
                        )
                    }

                    // Accept Button Section
                    if isFirstLaunch {
                        VStack(spacing: 20) {
                            Divider()
                                .padding(.vertical, 8)

                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.blue)
                                    Text(
                                        "By continuing, you acknowledge that you have read and understood these terms."
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }

                                Button("Accept and Continue") {
                                    legalAccepted = true
                                    dismiss()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isFirstLaunch {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(isFirstLaunch && !legalAccepted)
    }
}

struct ImprovedDisclaimerSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    let bulletPoints: [String]?

    init(
        icon: String, iconColor: Color, title: String, content: String,
        bulletPoints: [String]? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.content = content
        self.bulletPoints = bulletPoints
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Bullet points if provided
                if let bulletPoints = bulletPoints {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(bulletPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(width: 12, alignment: .leading)

                                Text(point)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
            }
            .padding(.leading, 36)  // Align with title text
        }
        .padding(.vertical, 4)
    }
}

#Preview("First Launch") {
    LegalDisclaimerView(isFirstLaunch: true)
}

#Preview("Settings View") {
    LegalDisclaimerView(isFirstLaunch: false)
}

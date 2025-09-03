import SwiftUI

struct LegalDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("whisper.legal.accepted") private var legalAccepted = false
    
    let isFirstLaunch: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Legal Disclaimer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Group {
                        DisclaimerSection(
                            title: "No Warranty",
                            content: """
                            This software is provided "as is" without warranty of any kind, express or implied. The developers make no representations or warranties regarding the security, reliability, or fitness for any particular purpose.
                            """
                        )
                        
                        DisclaimerSection(
                            title: "Security Limitations",
                            content: """
                            While this application uses industry-standard cryptographic algorithms, no security system is perfect. Users should understand that:
                            
                            • Device compromise may expose private keys
                            • Implementation bugs may exist despite testing
                            • Cryptographic algorithms may be broken in the future
                            • Side-channel attacks may be possible
                            """
                        )
                        
                        DisclaimerSection(
                            title: "User Responsibility",
                            content: """
                            Users are responsible for:
                            
                            • Keeping their devices secure and updated
                            • Protecting their identity backups and passphrases
                            • Verifying contact identities through secure channels
                            • Understanding the risks of encrypted communication
                            """
                        )
                        
                        DisclaimerSection(
                            title: "Export Compliance",
                            content: """
                            This software contains cryptographic functionality. Export and use may be restricted in some jurisdictions. Users are responsible for compliance with applicable laws and regulations.
                            """
                        )
                        
                        DisclaimerSection(
                            title: "Limitation of Liability",
                            content: """
                            In no event shall the developers be liable for any damages arising from the use or inability to use this software, including but not limited to data loss, privacy breaches, or communication failures.
                            """
                        )
                    }
                    
                    if isFirstLaunch {
                        VStack(spacing: 16) {
                            Text("By continuing, you acknowledge that you have read and understood these terms.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Accept and Continue") {
                                legalAccepted = true
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        .padding(.top, 20)
                    }
                }
                .padding()
            }
            .navigationTitle("Legal")
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

struct DisclaimerSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("First Launch") {
    LegalDisclaimerView(isFirstLaunch: true)
}

#Preview("Settings View") {
    LegalDisclaimerView(isFirstLaunch: false)
}
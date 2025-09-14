import SwiftUI
import LocalAuthentication

// Enhanced button styles for Biometric Settings
struct BiometricActionButtonStyle: ButtonStyle {
    let color: Color
    let isDestructive: Bool
    
    init(color: Color, isDestructive: Bool = false) {
        self.color = color
        self.isDestructive = isDestructive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundColor(isDestructive ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDestructive ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(isDestructive ? 0 : 0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BiometricActionButtonStyle {
    static func biometricAction(color: Color, isDestructive: Bool = false) -> BiometricActionButtonStyle {
        BiometricActionButtonStyle(color: color, isDestructive: isDestructive)
    }
}

struct BiometricSettingsView: View {
    @StateObject private var viewModel = BiometricSettingsViewModel()
    @State private var showingEnrollmentAlert = false
    @State private var showingUnenrollmentAlert = false

    var body: some View {
        List {
            // Header Section
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "touchid")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Biometric Settings")
                                .font(.headline)
                            Text("Secure your encryption keys with biometric authentication")
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

            // Biometric Authentication Status Section
            Section {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: biometricIcon)
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(biometricTypeText)
                                .font(.headline)
                            
                            Text(biometricStatusText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Status Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            
                            Text(statusText)
                                .font(.system(.caption, weight: .medium))
                                .foregroundColor(statusColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.blue)
                    Text("Biometric Authentication")
                        .font(.system(.subheadline, weight: .semibold))
                }
            }

            // Policy Section
            if viewModel.isBiometricAvailable {
                Section {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Require for Encryption")
                                    .font(.headline)
                                
                                Text("Require biometric authentication for encrypting and decrypting messages")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.biometricSigningEnabled)
                                .onChange(of: viewModel.biometricSigningEnabled) { _ in
                                    viewModel.toggleBiometricSigning()
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.orange)
                        Text("Policy")
                            .font(.system(.subheadline, weight: .semibold))
                    }
                }

                // Actions Section
                Section {
                    VStack(spacing: 12) {
                        if !viewModel.isEnrolled {
                            Button(action: {
                                showingEnrollmentAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                    Text("Enroll Encryption Key")
                                }
                            }
                            .buttonStyle(.biometricAction(color: .blue))
                        } else {
                            Button(action: {
                                Task {
                                    await viewModel.testAuthentication()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.title3)
                                    Text("Test Authentication")
                                }
                            }
                            .buttonStyle(.biometricAction(color: .green))
                            
                            Button(action: {
                                showingUnenrollmentAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.title3)
                                    Text("Remove Enrollment")
                                }
                            }
                            .buttonStyle(.biometricAction(color: .red, isDestructive: true))
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.green)
                        Text("Actions")
                            .font(.system(.subheadline, weight: .semibold))
                    }
                }
            }

            // Information Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Biometric Protection")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Text("When enabled, your encryption keys are protected by biometric authentication. You'll need to authenticate with \(biometricTypeText) each time you encrypt or decrypt a message.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            } header: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.purple)
                    Text("Information")
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
                            .fixedSize(horizontal: false, vertical: true)
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
        .navigationTitle("Biometric Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Enroll Encryption Key", isPresented: $showingEnrollmentAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Enroll") {
                Task {
                    await viewModel.enrollSigningKey()
                }
            }
        } message: {
            Text("This will create a new encryption key protected by biometric authentication. You'll need to authenticate each time you encrypt or decrypt a message.")
        }
        .alert("Remove Enrollment", isPresented: $showingUnenrollmentAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                viewModel.removeEnrollment()
            }
        } message: {
            Text("This will remove your biometric-protected encryption key. You won't be able to encrypt or decrypt messages with biometric authentication until you enroll again.")
        }
        .onAppear {
            viewModel.checkBiometricStatus()
        }
    }

    // MARK: - Helper Properties
    
    private var biometricIcon: String {
        switch viewModel.biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock"
        }
    }

    private var biometricTypeText: String {
        switch viewModel.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric Authentication"
        }
    }

    private var biometricStatusText: String {
        if !viewModel.isBiometricAvailable {
            return "Not available on this device"
        } else if viewModel.isEnrolled {
            return "Encryption key enrolled and protected"
        } else {
            return "Available for enrollment"
        }
    }
    
    private var statusText: String {
        if viewModel.isEnrolled {
            return "Enrolled"
        } else if viewModel.isBiometricAvailable {
            return "Available"
        } else {
            return "Unavailable"
        }
    }
    
    private var statusColor: Color {
        if viewModel.isEnrolled {
            return .green
        } else if viewModel.isBiometricAvailable {
            return .orange
        } else {
            return .gray
        }
    }
}

#Preview {
    NavigationView {
        BiometricSettingsView()
    }
}
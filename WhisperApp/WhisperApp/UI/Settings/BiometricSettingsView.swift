import SwiftUI
import LocalAuthentication

struct BiometricSettingsView: View {
    @StateObject private var viewModel = BiometricSettingsViewModel()
    @State private var showingEnrollmentAlert = false
    @State private var showingUnenrollmentAlert = false
    
    var body: some View {
        List {
            Section("Biometric Authentication") {
                HStack {
                    Image(systemName: biometricIcon)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(biometricTypeText)
                            .font(.headline)
                        
                        Text(biometricStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if viewModel.isBiometricAvailable {
                        Text(viewModel.isEnrolled ? "Enrolled" : "Available")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(viewModel.isEnrolled ? Color.green : Color.orange)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    } else {
                        Text("Unavailable")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            
            if viewModel.isBiometricAvailable {
                Section("Actions") {
                    if !viewModel.isEnrolled {
                        Button("Enroll Signing Key") {
                            showingEnrollmentAlert = true
                        }
                        .foregroundColor(.blue)
                    } else {
                        Button("Test Authentication") {
                            Task {
                                await viewModel.testAuthentication()
                            }
                        }
                        .foregroundColor(.blue)
                        
                        Button("Remove Enrollment") {
                            showingUnenrollmentAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            
            Section("Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Biometric Protection")
                        .font(.headline)
                    
                    Text("When enabled, your signing keys are protected by biometric authentication. You'll need to authenticate with Face ID or Touch ID each time you sign a message.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Biometric Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Enroll Signing Key", isPresented: $showingEnrollmentAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Enroll") {
                Task {
                    await viewModel.enrollSigningKey()
                }
            }
        } message: {
            Text("This will create a new signing key protected by biometric authentication. You'll need to authenticate each time you sign a message.")
        }
        .alert("Remove Enrollment", isPresented: $showingUnenrollmentAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                viewModel.removeEnrollment()
            }
        } message: {
            Text("This will remove your biometric-protected signing key. You won't be able to sign messages with biometric authentication until you enroll again.")
        }
        .onAppear {
            viewModel.checkBiometricStatus()
        }
    }
    
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
            return "Signing key enrolled and protected"
        } else {
            return "Available for enrollment"
        }
    }
}

#Preview {
    NavigationView {
        BiometricSettingsView()
    }
}
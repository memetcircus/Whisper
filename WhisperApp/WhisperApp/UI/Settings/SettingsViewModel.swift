import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    private let policyManager: PolicyManager
    
    @Published var contactRequiredToSend: Bool {
        didSet {
            policyManager.contactRequiredToSend = contactRequiredToSend
        }
    }
    
    @Published var requireSignatureForVerified: Bool {
        didSet {
            policyManager.requireSignatureForVerified = requireSignatureForVerified
        }
    }
    
    @Published var autoArchiveOnRotation: Bool {
        didSet {
            policyManager.autoArchiveOnRotation = autoArchiveOnRotation
        }
    }
    
    @Published var biometricGatedSigning: Bool {
        didSet {
            policyManager.biometricGatedSigning = biometricGatedSigning
        }
    }
    
    init(policyManager: PolicyManager = UserDefaultsPolicyManager()) {
        self.policyManager = policyManager
        
        // Initialize published properties with current policy values
        self.contactRequiredToSend = policyManager.contactRequiredToSend
        self.requireSignatureForVerified = policyManager.requireSignatureForVerified
        self.autoArchiveOnRotation = policyManager.autoArchiveOnRotation
        self.biometricGatedSigning = policyManager.biometricGatedSigning
    }
}
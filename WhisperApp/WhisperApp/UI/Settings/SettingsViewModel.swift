import Combine
import Foundation

// Simple protocol for settings-specific policy management
protocol SettingsPolicyManager {
    var autoArchiveOnRotation: Bool { get set }
}

// Simple implementation using UserDefaults
class UserDefaultsSettingsPolicyManager: SettingsPolicyManager {
    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let autoArchiveOnRotation = "whisper.policy.autoArchiveOnRotation"
        // Legacy keys for cleanup
        static let alwaysIncludeSignatures = "whisper.policy.alwaysIncludeSignatures"
        static let requireSignatureForVerified = "whisper.policy.requireSignatureForVerified"
    }

    init() {
        // Clean up legacy signature settings
        cleanupLegacySignatureSettings()
    }

    var autoArchiveOnRotation: Bool {
        get { userDefaults.bool(forKey: Keys.autoArchiveOnRotation) }
        set { userDefaults.set(newValue, forKey: Keys.autoArchiveOnRotation) }
    }

    /// Cleans up legacy signature settings that are no longer needed
    /// Removes both old signature-related UserDefaults keys
    private func cleanupLegacySignatureSettings() {
        // Remove legacy signature settings
        userDefaults.removeObject(forKey: Keys.alwaysIncludeSignatures)
        userDefaults.removeObject(forKey: Keys.requireSignatureForVerified)
        userDefaults.synchronize()
        print("✅ Cleaned up legacy signature settings")
    }
}

@MainActor
class SettingsViewModel: ObservableObject {
    private var policyManager: SettingsPolicyManager

    @Published var autoArchiveOnRotation: Bool = false

    init(policyManager: SettingsPolicyManager = UserDefaultsSettingsPolicyManager()) {
        self.policyManager = policyManager

        // Initialize published properties with current policy values
        self.autoArchiveOnRotation = policyManager.autoArchiveOnRotation

        // Set up observers to update policy manager when properties change
        setupPolicyObservers()
    }

    private func setupPolicyObservers() {
        $autoArchiveOnRotation
            .dropFirst()  // Skip initial value
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.policyManager.autoArchiveOnRotation = newValue
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}

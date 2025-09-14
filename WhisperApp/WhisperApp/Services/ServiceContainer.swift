import CoreData
import CryptoKit
import Foundation

/// Centralized service container for dependency injection
/// Provides real implementations of all services throughout the app
class ServiceContainer {
    static let shared = ServiceContainer()

    private init() {}

    // MARK: - Service Factory Methods

    /// Creates a real WhisperService with all dependencies
    func createWhisperService() -> DefaultWhisperService {
        let cryptoEngine = CryptoKitEngine()
        let envelopeProcessor = WhisperEnvelopeProcessor(cryptoEngine: cryptoEngine)
        let policyManager = UserDefaultsPolicyManager()
        let identityManager = CoreDataIdentityManager(
            context: PersistenceController.shared.container.viewContext,
            cryptoEngine: cryptoEngine,
            policyManager: policyManager
        )
        let contactManager = CoreDataContactManager(
            persistentContainer: PersistenceController.shared.container
        )
        let biometricService = KeychainBiometricService()
        let replayProtector = CoreDataReplayProtector(
            context: PersistenceController.shared.container.viewContext
        )

        return DefaultWhisperService(
            cryptoEngine: cryptoEngine,
            envelopeProcessor: envelopeProcessor,
            identityManager: identityManager,
            contactManager: contactManager,
            policyManager: policyManager,
            biometricService: biometricService,
            replayProtector: replayProtector
        )
    }

    // MARK: - Lazy Services

    private var _whisperService: DefaultWhisperService?
    private var _identityManager: CoreDataIdentityManager?
    private var _contactManager: CoreDataContactManager?
    private var _policyManager: UserDefaultsPolicyManager?

    var whisperService: DefaultWhisperService {
        if let service = _whisperService {
            return service
        }
        let service = createWhisperService()
        _whisperService = service
        return service
    }

    var identityManager: CoreDataIdentityManager {
        if let manager = _identityManager {
            return manager
        }
        let cryptoEngine = CryptoKitEngine()
        let policyManager = self.policyManager
        let manager = CoreDataIdentityManager(
            context: PersistenceController.shared.container.viewContext,
            cryptoEngine: cryptoEngine,
            policyManager: policyManager
        )
        _identityManager = manager
        return manager
    }

    var contactManager: CoreDataContactManager {
        if let manager = _contactManager {
            return manager
        }
        let manager = CoreDataContactManager(
            persistentContainer: PersistenceController.shared.container
        )
        _contactManager = manager
        return manager
    }

    var policyManager: UserDefaultsPolicyManager {
        if let manager = _policyManager {
            return manager
        }
        let manager = UserDefaultsPolicyManager()
        _policyManager = manager
        return manager
    }
}

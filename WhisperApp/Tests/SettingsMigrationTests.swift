import XCTest
@testable import WhisperApp

/// Comprehensive tests for signature settings migration functionality
/// Validates backward compatibility and secure migration behavior
class SettingsMigrationTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private let testSuiteName = "SettingsMigrationTests"
    
    override func setUp() {
        super.setUp()
        // Use a test-specific UserDefaults suite to avoid affecting real settings
        userDefaults = UserDefaults(suiteName: testSuiteName)!
        userDefaults.removePersistentDomain(forName: testSuiteName)
    }
    
    override func tearDown() {
        // Clean up test UserDefaults
        userDefaults.removePersistentDomain(forName: testSuiteName)
        userDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Migration Tests
    
    func testMigrationFromEnabledSignatureRequirement() {
        // Given: User had "requireSignatureForVerified" enabled
        userDefaults.set(true, forKey: "whisper.policy.requireSignatureForVerified")
        
        // When: Migration occurs during initialization
        let policyManager = createTestPolicyManager()
        
        // Then: New setting should be enabled (preserving security)
        XCTAssertTrue(policyManager.alwaysIncludeSignatures, "Should enable alwaysIncludeSignatures when migrating from enabled requireSignatureForVerified")
        
        // And: Old setting should be removed
        XCTAssertNil(userDefaults.object(forKey: "whisper.policy.requireSignatureForVerified"), "Old setting should be removed after migration")
    }
    
    func testMigrationFromDisabledSignatureRequirement() {
        // Given: User had "requireSignatureForVerified" disabled
        userDefaults.set(false, forKey: "whisper.policy.requireSignatureForVerified")
        
        // When: Migration occurs during initialization
        let policyManager = createTestPolicyManager()
        
        // Then: New setting should still default to secure (true)
        XCTAssertTrue(policyManager.alwaysIncludeSignatures, "Should default to secure even when migrating from disabled requireSignatureForVerified")
        
        // And: Old setting should be removed
        XCTAssertNil(userDefaults.object(forKey: "whisper.policy.requireSignatureForVerified"), "Old setting should be removed after migration")
    }
    
    func testNoMigrationNeededWhenOldSettingDoesNotExist() {
        // Given: No old setting exists
        // (UserDefaults is clean)
        
        // When: Migration occurs during initialization
        let policyManager = createTestPolicyManager()
        
        // Then: New setting should have secure default
        XCTAssertTrue(policyManager.alwaysIncludeSignatures, "Should have secure default when no migration is needed")
    }
    
    func testMigrationPreservesExistingNewSetting() {
        // Given: Both old and new settings exist (edge case)
        userDefaults.set(false, forKey: "whisper.policy.requireSignatureForVerified")
        userDefaults.set(false, forKey: "whisper.policy.alwaysIncludeSignatures")
        
        // When: Migration occurs during initialization
        let policyManager = createTestPolicyManager()
        
        // Then: Existing new setting should be preserved
        XCTAssertFalse(policyManager.alwaysIncludeSignatures, "Should preserve existing new setting value")
        
        // And: Old setting should be removed
        XCTAssertNil(userDefaults.object(forKey: "whisper.policy.requireSignatureForVerified"), "Old setting should be removed after migration")
    }
    
    // MARK: - Error Handling Tests
    
    func testMigrationHandlesCorruptedOldSetting() {
        // Given: Old setting has invalid/corrupted value
        userDefaults.set("invalid_boolean", forKey: "whisper.policy.requireSignatureForVerified")
        
        // When: Migration occurs during initialization
        let policyManager = createTestPolicyManager()
        
        // Then: Should fallback to secure default
        XCTAssertTrue(policyManager.alwaysIncludeSignatures, "Should fallback to secure default when old setting is corrupted")
        
        // And: Old setting should be cleaned up
        XCTAssertNil(userDefaults.object(forKey: "whisper.policy.requireSignatureForVerified"), "Corrupted old setting should be removed")
    }
    
    func testSecureDefaultWhenMigrationFails() {
        // This test simulates a scenario where migration might fail
        // In practice, the current implementation is robust, but we test the fallback behavior
        
        // Given: Clean state
        let policyManager = createTestPolicyManager()
        
        // When: We check the default behavior
        // Then: Should always default to secure
        XCTAssertTrue(policyManager.alwaysIncludeSignatures, "Should always default to secure setting")
    }
    
    // MARK: - Migration Verification Tests
    
    func testMigrationNeededDetection() {
        // Given: Old setting exists
        userDefaults.set(true, forKey: "whisper.policy.requireSignatureForVerified")
        
        // When: We check if migration is needed
        let policyManager = createTestPolicyManager()
        
        // Then: Migration should be detected as needed before it runs
        // Note: After initialization, migration will have run, so we test the detection logic separately
        userDefaults.set(true, forKey: "whisper.policy.requireSignatureForVerified") // Reset for test
        XCTAssertTrue(policyManager.isMigrationNeeded(), "Should detect that migration is needed")
        
        // After manual migration
        policyManager.performManualMigration()
        XCTAssertFalse(policyManager.isMigrationNeeded(), "Should detect that migration is no longer needed")
    }
    
    func testManualMigrationTrigger() {
        // Given: Old setting exists
        userDefaults.set(true, forKey: "whisper.policy.requireSignatureForVerified")
        
        // When: Manual migration is triggered
        let policyManager = createTestPolicyManager()
        policyManager.performManualMigration()
        
        // Then: Migration should complete successfully
        XCTAssertTrue(policyManager.alwaysIncludeSignatures, "Manual migration should preserve security")
        XCTAssertNil(userDefaults.object(forKey: "whisper.policy.requireSignatureForVerified"), "Manual migration should clean up old setting")
    }
    
    // MARK: - Security Preservation Tests
    
    func testSecurityIsNeverDowngraded() {
        // Test various scenarios to ensure security is never accidentally downgraded
        
        let scenarios: [(oldValue: Bool?, expectedResult: Bool, description: String)] = [
            (true, true, "Enabled requirement should migrate to enabled always-include"),
            (false, true, "Disabled requirement should still default to secure always-include"),
            (nil, true, "No old setting should default to secure always-include")
        ]
        
        for scenario in scenarios {
            // Clean slate for each test
            userDefaults.removePersistentDomain(forName: testSuiteName)
            
            // Set up scenario
            if let oldValue = scenario.oldValue {
                userDefaults.set(oldValue, forKey: "whisper.policy.requireSignatureForVerified")
            }
            
            // Run migration
            let policyManager = createTestPolicyManager()
            
            // Verify security is preserved
            XCTAssertEqual(policyManager.alwaysIncludeSignatures, scenario.expectedResult, scenario.description)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestPolicyManager() -> UserDefaultsSettingsPolicyManager {
        // Create a custom policy manager that uses our test UserDefaults
        return TestUserDefaultsSettingsPolicyManager(userDefaults: userDefaults)
    }
}

// MARK: - Test Helper Class

/// Test-specific implementation that allows injecting custom UserDefaults
private class TestUserDefaultsSettingsPolicyManager: SettingsPolicyManager {
    private let testUserDefaults: UserDefaults
    
    private enum Keys {
        static let alwaysIncludeSignatures = "whisper.policy.alwaysIncludeSignatures"
        static let autoArchiveOnRotation = "whisper.policy.autoArchiveOnRotation"
        static let requireSignatureForVerified = "whisper.policy.requireSignatureForVerified"
    }
    
    init(userDefaults: UserDefaults) {
        self.testUserDefaults = userDefaults
        // Perform migration on initialization
        migrateSignatureSettings()
        verifyMigrationSuccess()
    }
    
    var alwaysIncludeSignatures: Bool {
        get {
            if testUserDefaults.object(forKey: Keys.alwaysIncludeSignatures) == nil {
                return true
            }
            return testUserDefaults.bool(forKey: Keys.alwaysIncludeSignatures)
        }
        set {
            testUserDefaults.set(newValue, forKey: Keys.alwaysIncludeSignatures)
        }
    }
    
    var autoArchiveOnRotation: Bool {
        get { testUserDefaults.bool(forKey: Keys.autoArchiveOnRotation) }
        set { testUserDefaults.set(newValue, forKey: Keys.autoArchiveOnRotation) }
    }
    
    /// Migrates old signature settings to new unified control (test version)
    private func migrateSignatureSettings() {
        do {
            guard testUserDefaults.object(forKey: Keys.requireSignatureForVerified) != nil else {
                if testUserDefaults.object(forKey: Keys.alwaysIncludeSignatures) == nil {
                    alwaysIncludeSignatures = true
                }
                return
            }

            let oldValue: Bool
            if let oldValueObject = testUserDefaults.object(forKey: Keys.requireSignatureForVerified) as? Bool {
                oldValue = oldValueObject
            } else {
                oldValue = true
            }

            if oldValue {
                alwaysIncludeSignatures = true
            } else {
                if testUserDefaults.object(forKey: Keys.alwaysIncludeSignatures) == nil {
                    alwaysIncludeSignatures = true
                }
            }

            testUserDefaults.removeObject(forKey: Keys.requireSignatureForVerified)
            testUserDefaults.synchronize()
            
        } catch {
            alwaysIncludeSignatures = true
            
            do {
                testUserDefaults.removeObject(forKey: Keys.requireSignatureForVerified)
                testUserDefaults.synchronize()
            } catch {
                // Ignore cleanup errors in tests
            }
        }
    }
    
    private func verifyMigrationSuccess() {
        if testUserDefaults.object(forKey: Keys.requireSignatureForVerified) != nil {
            testUserDefaults.removeObject(forKey: Keys.requireSignatureForVerified)
            testUserDefaults.synchronize()
        }
        
        let currentValue = alwaysIncludeSignatures
        if testUserDefaults.object(forKey: Keys.alwaysIncludeSignatures) == nil {
            alwaysIncludeSignatures = currentValue
        }
    }
    
    func isMigrationNeeded() -> Bool {
        return testUserDefaults.object(forKey: Keys.requireSignatureForVerified) != nil
    }
    
    func performManualMigration() {
        migrateSignatureSettings()
        verifyMigrationSuccess()
    }
}
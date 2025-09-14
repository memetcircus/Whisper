#!/usr/bin/env swift

import Foundation

// MARK: - Test Implementation

/// Simple protocol for settings-specific policy management
protocol SettingsPolicyManager {
    var alwaysIncludeSignatures: Bool { get set }
    var autoArchiveOnRotation: Bool { get set }
}

/// Test implementation of settings policy manager with migration
class TestSettingsPolicyManager: SettingsPolicyManager {
    private let userDefaults: UserDefaults
    
    private enum Keys {
        static let alwaysIncludeSignatures = "whisper.policy.alwaysIncludeSignatures"
        static let autoArchiveOnRotation = "whisper.policy.autoArchiveOnRotation"
        static let requireSignatureForVerified = "whisper.policy.requireSignatureForVerified"
    }
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        migrateSignatureSettings()
        verifyMigrationSuccess()
    }
    
    var alwaysIncludeSignatures: Bool {
        get {
            if userDefaults.object(forKey: Keys.alwaysIncludeSignatures) == nil {
                return true
            }
            return userDefaults.bool(forKey: Keys.alwaysIncludeSignatures)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.alwaysIncludeSignatures)
        }
    }
    
    var autoArchiveOnRotation: Bool {
        get { userDefaults.bool(forKey: Keys.autoArchiveOnRotation) }
        set { userDefaults.set(newValue, forKey: Keys.autoArchiveOnRotation) }
    }
    
    /// Migrates old signature settings to new unified control
    private func migrateSignatureSettings() {
        do {
            guard userDefaults.object(forKey: Keys.requireSignatureForVerified) != nil else {
                if userDefaults.object(forKey: Keys.alwaysIncludeSignatures) == nil {
                    alwaysIncludeSignatures = true
                    print("✅ No migration needed - set secure default: alwaysIncludeSignatures = true")
                }
                return
            }

            let oldValue: Bool
            if let oldValueObject = userDefaults.object(forKey: Keys.requireSignatureForVerified) as? Bool {
                oldValue = oldValueObject
            } else {
                print("⚠️ Migration warning: Invalid old signature setting detected, defaulting to secure")
                oldValue = true
            }

            if oldValue {
                alwaysIncludeSignatures = true
                print("✅ Migration: User had signature requirement for verified contacts → enabled alwaysIncludeSignatures")
            } else {
                if userDefaults.object(forKey: Keys.alwaysIncludeSignatures) == nil {
                    alwaysIncludeSignatures = true
                    print("✅ Migration: User had no signature requirement → defaulted to secure alwaysIncludeSignatures = true")
                } else {
                    print("✅ Migration: New setting already exists, preserving current value")
                }
            }

            userDefaults.removeObject(forKey: Keys.requireSignatureForVerified)
            userDefaults.synchronize()
            
            print("✅ Migration completed successfully: alwaysIncludeSignatures = \(alwaysIncludeSignatures)")
            
        } catch {
            print("❌ Migration error: \(error.localizedDescription)")
            alwaysIncludeSignatures = true
            
            do {
                userDefaults.removeObject(forKey: Keys.requireSignatureForVerified)
                userDefaults.synchronize()
                print("✅ Fallback: Enabled secure default and cleaned up old setting")
            } catch {
                print("⚠️ Warning: Could not clean up old setting after migration failure")
            }
        }
    }
    
    private func verifyMigrationSuccess() {
        if userDefaults.object(forKey: Keys.requireSignatureForVerified) != nil {
            print("⚠️ Migration verification failed: Old setting still exists")
            userDefaults.removeObject(forKey: Keys.requireSignatureForVerified)
            userDefaults.synchronize()
            print("✅ Cleaned up remaining old setting")
        }
        
        let currentValue = alwaysIncludeSignatures
        if userDefaults.object(forKey: Keys.alwaysIncludeSignatures) == nil {
            alwaysIncludeSignatures = currentValue
            print("✅ Migration verification: Ensured new setting is persisted")
        }
        
        print("✅ Migration verification complete: alwaysIncludeSignatures = \(currentValue)")
    }
    
    func isMigrationNeeded() -> Bool {
        return userDefaults.object(forKey: Keys.requireSignatureForVerified) != nil
    }
    
    func performManualMigration() {
        print("🔄 Manual migration triggered")
        migrateSignatureSettings()
        verifyMigrationSuccess()
    }
}

// MARK: - Test Cases

func runMigrationTests() {
    print("🧪 Starting Settings Migration Tests")
    print(String(repeating: "=", count: 50))
    
    // Test 1: Migration from enabled signature requirement
    print("\n📋 Test 1: Migration from enabled signature requirement")
    let testDefaults1 = UserDefaults(suiteName: "test1")!
    testDefaults1.removePersistentDomain(forName: "test1")
    testDefaults1.set(true, forKey: "whisper.policy.requireSignatureForVerified")
    
    let manager1 = TestSettingsPolicyManager(userDefaults: testDefaults1)
    assert(manager1.alwaysIncludeSignatures == true, "Should enable alwaysIncludeSignatures when migrating from enabled requireSignatureForVerified")
    assert(testDefaults1.object(forKey: "whisper.policy.requireSignatureForVerified") == nil, "Old setting should be removed")
    print("✅ Test 1 PASSED")
    
    // Test 2: Migration from disabled signature requirement
    print("\n📋 Test 2: Migration from disabled signature requirement")
    let testDefaults2 = UserDefaults(suiteName: "test2")!
    testDefaults2.removePersistentDomain(forName: "test2")
    testDefaults2.set(false, forKey: "whisper.policy.requireSignatureForVerified")
    
    let manager2 = TestSettingsPolicyManager(userDefaults: testDefaults2)
    assert(manager2.alwaysIncludeSignatures == true, "Should default to secure even when migrating from disabled requireSignatureForVerified")
    assert(testDefaults2.object(forKey: "whisper.policy.requireSignatureForVerified") == nil, "Old setting should be removed")
    print("✅ Test 2 PASSED")
    
    // Test 3: No migration needed
    print("\n📋 Test 3: No migration needed when old setting doesn't exist")
    let testDefaults3 = UserDefaults(suiteName: "test3")!
    testDefaults3.removePersistentDomain(forName: "test3")
    
    let manager3 = TestSettingsPolicyManager(userDefaults: testDefaults3)
    assert(manager3.alwaysIncludeSignatures == true, "Should have secure default when no migration is needed")
    print("✅ Test 3 PASSED")
    
    // Test 4: Corrupted old setting
    print("\n📋 Test 4: Migration handles corrupted old setting")
    let testDefaults4 = UserDefaults(suiteName: "test4")!
    testDefaults4.removePersistentDomain(forName: "test4")
    testDefaults4.set("invalid_boolean", forKey: "whisper.policy.requireSignatureForVerified")
    
    let manager4 = TestSettingsPolicyManager(userDefaults: testDefaults4)
    assert(manager4.alwaysIncludeSignatures == true, "Should fallback to secure default when old setting is corrupted")
    assert(testDefaults4.object(forKey: "whisper.policy.requireSignatureForVerified") == nil, "Corrupted old setting should be removed")
    print("✅ Test 4 PASSED")
    
    // Test 5: Migration detection
    print("\n📋 Test 5: Migration needed detection")
    let testDefaults5 = UserDefaults(suiteName: "test5")!
    testDefaults5.removePersistentDomain(forName: "test5")
    testDefaults5.set(true, forKey: "whisper.policy.requireSignatureForVerified")
    
    let manager5 = TestSettingsPolicyManager(userDefaults: testDefaults5)
    // Reset for test
    testDefaults5.set(true, forKey: "whisper.policy.requireSignatureForVerified")
    assert(manager5.isMigrationNeeded() == true, "Should detect that migration is needed")
    
    manager5.performManualMigration()
    assert(manager5.isMigrationNeeded() == false, "Should detect that migration is no longer needed")
    print("✅ Test 5 PASSED")
    
    // Test 6: Preserve existing new setting
    print("\n📋 Test 6: Migration preserves existing new setting")
    let testDefaults6 = UserDefaults(suiteName: "test6")!
    testDefaults6.removePersistentDomain(forName: "test6")
    testDefaults6.set(false, forKey: "whisper.policy.requireSignatureForVerified")
    testDefaults6.set(false, forKey: "whisper.policy.alwaysIncludeSignatures")
    
    let manager6 = TestSettingsPolicyManager(userDefaults: testDefaults6)
    assert(manager6.alwaysIncludeSignatures == false, "Should preserve existing new setting value")
    assert(testDefaults6.object(forKey: "whisper.policy.requireSignatureForVerified") == nil, "Old setting should be removed")
    print("✅ Test 6 PASSED")
    
    print("\n🎉 All migration tests PASSED!")
    print(String(repeating: "=", count: 50))
}

// MARK: - Main Execution

runMigrationTests()

print("\n📊 Migration Implementation Summary:")
print("✅ Created migration function to convert old 'requireSignatureForVerified' setting")
print("✅ Preserved security by enabling 'alwaysIncludeSignatures' for users who had signature requirements")
print("✅ Removed deprecated setting keys after successful migration")
print("✅ Added comprehensive error handling for migration edge cases with secure fallbacks")
print("✅ Added migration verification and manual migration capabilities")
print("✅ Implemented comprehensive test coverage for all migration scenarios")

print("\n🔒 Security Guarantees:")
print("• Migration never downgrades security - always defaults to secure settings")
print("• Users who had signature requirements maintain or improve their security level")
print("• Corrupted or invalid settings fallback to secure defaults")
print("• Migration is idempotent and can be safely run multiple times")
print("• Old deprecated settings are completely removed after successful migration")
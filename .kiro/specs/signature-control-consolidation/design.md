# Signature Control Consolidation Design

## Overview

This design consolidates cryptographic signature control from two separate UI locations (Compose Message toggle + Settings policy) into a single, unified Settings-based control. The solution eliminates user confusion, reduces decision fatigue, and provides consistent security behavior across all messages.

## Architecture

### Current State Problems
- **Dual Controls**: "Include Signature" toggle in Compose + "Require Signature for Verified" in Settings
- **User Confusion**: Same feature controlled in two different places
- **Inconsistent Behavior**: Per-message decisions vs. policy-based decisions
- **Decision Fatigue**: Users must choose signature inclusion for every message

### New Architecture
- **Single Control Point**: Settings-only signature management
- **Consistent Behavior**: All messages follow the same signature policy
- **Simplified UX**: Compose UI focuses on message content, not security decisions
- **Security-First**: Default to signatures enabled for all users

## Components and Interfaces

### 1. Settings UI Changes

#### Remove Existing Controls
```swift
// REMOVE from SettingsView.swift:
Toggle("Require Signatures for Verified", isOn: $viewModel.requireSignatureForVerified)
```

#### Add New Unified Control
```swift
// ADD to SettingsView.swift:
Section("Message Security") {
    Toggle("Always Include Signatures", isOn: $viewModel.alwaysIncludeSignatures)
        .help("Include cryptographic signatures in all messages for authenticity verification")
}
```

### 2. Settings Data Model Changes

#### Update SettingsPolicyManager Protocol
```swift
protocol SettingsPolicyManager {
    var alwaysIncludeSignatures: Bool { get set }
    // REMOVE: var requireSignatureForVerified: Bool { get set }
    var autoArchiveOnRotation: Bool { get set }
}
```

#### Update UserDefaults Implementation
```swift
class UserDefaultsSettingsPolicyManager: SettingsPolicyManager {
    private enum Keys {
        static let alwaysIncludeSignatures = "whisper.policy.alwaysIncludeSignatures"
        // REMOVE: static let requireSignatureForVerified = "whisper.policy.requireSignatureForVerified"
        static let autoArchiveOnRotation = "whisper.policy.autoArchiveOnRotation"
    }
    
    var alwaysIncludeSignatures: Bool {
        get { 
            // Default to true for security-first approach
            if userDefaults.object(forKey: Keys.alwaysIncludeSignatures) == nil {
                return true
            }
            return userDefaults.bool(forKey: Keys.alwaysIncludeSignatures)
        }
        set { userDefaults.set(newValue, forKey: Keys.alwaysIncludeSignatures) }
    }
}
```

### 3. Compose UI Changes

#### Remove Signature Toggle from ComposeView
```swift
// REMOVE from ComposeView.swift:
HStack {
    Text("Include Signature")
    Spacer()
    Toggle("", isOn: $viewModel.includeSignature)
}
```

#### Update ComposeViewModel Logic
```swift
// REPLACE in ComposeViewModel.swift:
func encryptMessage() async {
    // OLD: Per-message signature decision
    // let authenticity: MessageAuthenticity = includeSignature ? .signed : .anonymous
    
    // NEW: Settings-based signature decision
    let shouldIncludeSignature = settingsManager.alwaysIncludeSignatures
    let authenticity: MessageAuthenticity = shouldIncludeSignature ? .signed : .anonymous
    
    let result = try await whisperService.encrypt(
        message: messageText,
        recipient: selectedContact,
        authenticity: authenticity
    )
}
```

### 4. Migration Strategy

#### Settings Migration
```swift
// Add to SettingsViewModel initialization:
private func migrateSignatureSettings() {
    let oldRequireSignatureKey = "whisper.policy.requireSignatureForVerified"
    
    // If old setting exists and was enabled, enable new unified setting
    if userDefaults.object(forKey: oldRequireSignatureKey) != nil {
        let oldValue = userDefaults.bool(forKey: oldRequireSignatureKey)
        if oldValue {
            // Preserve security: if they required signatures for verified, enable for all
            policyManager.alwaysIncludeSignatures = true
        }
        // Remove old setting
        userDefaults.removeObject(forKey: oldRequireSignatureKey)
    }
}
```

## Data Models

### Settings Data Flow
```
User Toggles "Always Include Signatures" in Settings
    ↓
SettingsViewModel updates @Published property
    ↓
UserDefaultsSettingsPolicyManager persists to UserDefaults
    ↓
ComposeViewModel reads setting when encrypting
    ↓
WhisperService.encrypt() called with appropriate MessageAuthenticity
```

### Message Authenticity Determination
```swift
// Simple, unified logic:
let authenticity: MessageAuthenticity = settingsManager.alwaysIncludeSignatures ? .signed : .anonymous
```

## Error Handling

### Settings Validation
- No complex validation needed - simple boolean toggle
- Default to secure option (true) if setting is missing
- Graceful fallback to signed messages on read errors

### Migration Error Handling
```swift
private func migrateSignatureSettings() {
    do {
        // Migration logic with error handling
        if let oldValue = userDefaults.object(forKey: oldRequireSignatureKey) as? Bool {
            policyManager.alwaysIncludeSignatures = oldValue
        }
        userDefaults.removeObject(forKey: oldRequireSignatureKey)
    } catch {
        // Fallback to secure default
        policyManager.alwaysIncludeSignatures = true
        print("Migration warning: Defaulting to signatures enabled for security")
    }
}
```

## Testing Strategy

### Unit Tests
1. **Settings Persistence Tests**
   - Verify "Always Include Signatures" setting saves/loads correctly
   - Test default value behavior (should be true)
   - Test migration from old "Require Signature for Verified" setting

2. **ComposeViewModel Tests**
   - Verify signature inclusion based on Settings value
   - Test that per-message signature controls are removed
   - Verify WhisperService receives correct MessageAuthenticity

3. **UI Tests**
   - Verify Compose screen no longer shows signature toggle
   - Verify Settings screen shows unified signature control
   - Test Settings toggle functionality

### Integration Tests
1. **End-to-End Message Flow**
   - Send message with signatures enabled → verify signature included
   - Send message with signatures disabled → verify anonymous mode
   - Change setting → verify immediate effect on next message

2. **Migration Tests**
   - Test upgrade from version with old settings
   - Verify security preservation during migration
   - Test clean install behavior (defaults to secure)

### Security Tests
1. **Default Security Verification**
   - New installations default to signatures enabled
   - Migration preserves or enhances security level
   - No regression in cryptographic signature functionality

## Implementation Phases

### Phase 1: Settings Consolidation
1. Update SettingsPolicyManager protocol and implementation
2. Modify SettingsView to show unified control
3. Remove old "Require Signature for Verified" toggle
4. Add migration logic for existing users

### Phase 2: Compose UI Simplification  
1. Remove signature toggle from ComposeView
2. Update ComposeViewModel to use Settings-based logic
3. Remove per-message signature state management
4. Update UI layout without signature controls

### Phase 3: Testing and Validation
1. Comprehensive unit test coverage
2. UI automation tests for new Settings behavior
3. Migration testing with various user configurations
4. Security validation of signature behavior

## Security Considerations

### Secure Defaults
- New users get signatures enabled by default
- Migration preserves existing security levels
- No path for accidental security downgrade

### User Control
- Clear, single point of control in Settings
- Immediate effect on message behavior
- No hidden or complex signature policies

### Backward Compatibility
- Existing "Require Signature for Verified" users maintain security
- Migration to more secure "always include" approach
- No loss of cryptographic functionality
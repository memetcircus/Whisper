# Implementation Plan

- [x] 1. Update Settings Data Model for Unified Signature Control
  - Remove "requireSignatureForVerified" from SettingsPolicyManager protocol
  - Keep only "alwaysIncludeSignatures" property with secure default (true)
  - Update UserDefaultsSettingsPolicyManager implementation to remove old signature policy
  - Add migration logic to preserve existing user security preferences
  - _Requirements: 2.1, 2.2, 6.1, 6.2_

- [x] 2. Simplify Settings UI to Single Signature Control
  - Remove "Require Signatures for Verified" toggle from SettingsView
  - Update "Message Security" section to show only "Always Include Signatures" toggle
  - Update help text to clearly explain unified signature behavior
  - Remove requireSignatureForVerified binding from SettingsViewModel
  - _Requirements: 2.1, 2.2, 3.2_

- [x] 3. Remove Signature Toggle from Compose Message Screen
  - Remove "Include Signature" toggle and related UI elements from ComposeView
  - Remove includeSignature state property from ComposeViewModel
  - Update ComposeView layout to focus on message content without signature controls
  - Clean up any signature-related UI state management in Compose components
  - _Requirements: 1.1, 1.2, 5.1, 5.2_

- [x] 4. Update ComposeViewModel to Use Settings-Based Signature Logic
  - Modify encryptMessage() method to determine signatures from Settings only
  - Replace per-message signature logic with settingsManager.alwaysIncludeSignatures check
  - Remove signature-related properties and methods from ComposeViewModel
  - Ensure MessageAuthenticity is set based solely on Settings preference
  - _Requirements: 1.3, 2.5, 3.4_

- [ ] 5. Implement Settings Migration for Backward Compatibility
  - Create migration function to convert old "requireSignatureForVerified" setting
  - Preserve security by enabling "alwaysIncludeSignatures" for users who had signature requirements
  - Remove deprecated setting keys after successful migration
  - Add error handling for migration edge cases with secure fallbacks
  - _Requirements: 6.1, 6.2, 6.3, 6.4_


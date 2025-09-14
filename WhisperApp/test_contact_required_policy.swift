#!/usr/bin/env swift

import Foundation

print("=== Contact Required to Send Policy Test Plan ===")

print("""

## Test Plan: Contact Required to Send Policy

### What This Policy Does:
- When ENABLED: Users can only send messages to contacts (blocks raw key sending)
- When DISABLED: Users can send messages to both contacts and raw public keys

### Test Scenarios:

### 1. Policy Toggle Test
**Steps:**
1. Open WhisperApp on iPhone
2. Go to Settings
3. Find "Contact Required to Send" toggle
4. Toggle it ON and OFF
5. Verify the setting persists after app restart

**Expected Results:**
- Toggle should work smoothly
- Setting should save and persist
- UI should reflect current state

### 2. Raw Key Sending - Policy DISABLED
**Steps:**
1. Ensure "Contact Required to Send" is OFF in Settings
2. Go to Compose Message
3. Try to enter a raw public key (64-character hex string)
4. Attempt to send a message

**Expected Results:**
- Should allow entering raw public key
- Should allow sending message to raw key
- Message should encrypt and send successfully

### 3. Raw Key Sending - Policy ENABLED
**Steps:**
1. Enable "Contact Required to Send" in Settings
2. Go to Compose Message
3. Try to enter a raw public key
4. Attempt to send a message

**Expected Results:**
- Should block sending to raw key
- Should show policy violation error
- Error message should be clear and helpful

### 4. Contact Sending - Policy ENABLED
**Steps:**
1. Ensure "Contact Required to Send" is ON
2. Add a contact first (if none exist)
3. Go to Compose Message
4. Select an existing contact
5. Send a message

**Expected Results:**
- Should allow selecting contacts
- Should allow sending to contacts
- Message should send normally

### 5. Contact Sending - Policy DISABLED
**Steps:**
1. Ensure "Contact Required to Send" is OFF
2. Go to Compose Message
3. Select an existing contact
4. Send a message

**Expected Results:**
- Should work normally (policy doesn't restrict contact sending)
- Message should send successfully

### 6. Edge Cases
**Test A: Empty Contact List**
1. Enable "Contact Required to Send"
2. Ensure no contacts exist
3. Try to compose a message

**Expected:** Should show appropriate message about needing contacts

**Test B: Policy Change During Compose**
1. Start composing to raw key with policy OFF
2. Switch to Settings and enable policy
3. Return to compose and try to send

**Expected:** Should respect new policy setting

### Manual Testing Steps:

""")

// Generate test data for manual testing
let testPublicKey = "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"
let shortKey = "abc123"
let invalidKey = "not-a-valid-key"

print("### Test Data:")
print("**Valid Test Public Key (64 chars):**")
print(testPublicKey)
print("")
print("**Invalid Test Keys:**")
print("- Short key: \(shortKey)")
print("- Invalid key: \(invalidKey)")
print("")

print("""
### How to Test on iPhone:

1. **Build and Install:**
   - Build WhisperApp in Xcode
   - Install on iPhone device or simulator
   - Launch the app

2. **Test Settings UI:**
   - Navigate to Settings
   - Look for "Contact Required to Send" toggle
   - Test toggling ON/OFF
   - Verify setting persists after app restart

3. **Test Message Composition:**
   - Go to Compose Message screen
   - Test with policy OFF: Try sending to raw key (should work)
   - Test with policy ON: Try sending to raw key (should be blocked)
   - Test with policy ON: Try sending to contact (should work)

4. **Verify Error Messages:**
   - When policy blocks sending, check error message is clear
   - Error should explain why sending was blocked
   - Error should suggest adding contact first

5. **Test Policy Enforcement:**
   - Policy should be enforced at send time
   - Policy should prevent message encryption for raw keys when enabled
   - Policy should allow normal contact messaging

### Expected Policy Violation Error:
"Raw key sending is blocked by policy"

### Files to Check:
- Settings UI: WhisperApp/UI/Settings/SettingsView.swift
- Policy Logic: WhisperApp/Core/Policies/PolicyManager.swift  
- Compose Logic: WhisperApp/UI/Compose/ComposeViewModel.swift
- Message Service: WhisperApp/Services/WhisperService.swift

### Debugging Tips:
- Check Xcode console for policy validation logs
- Verify PolicyManager.contactRequiredToSend property
- Check WhisperService.validateSendPolicy() calls
- Monitor UserDefaults for policy persistence

""")

print("✅ Test plan generated! Follow the manual steps above to test the Contact Required to Send policy on iPhone.")
# Contact Required to Send Policy - iPhone Testing Guide

## Overview
The "Contact Required to Send" policy prevents users from sending messages to raw public keys when enabled. This forces users to add contacts before messaging, improving security and user experience.

## Policy Implementation Status ✅
- ✅ **Settings UI**: Toggle exists in Settings > Security Policies
- ✅ **Policy Storage**: Uses UserDefaults via PolicyManager
- ✅ **Policy Validation**: Implemented in DefaultWhisperService.encrypt()
- ✅ **Error Handling**: Returns "Raw key sending is blocked by policy"

## Testing Steps on iPhone

### 1. Build and Install
```bash
# In Xcode
1. Open WhisperApp.xcodeproj
2. Select iPhone device or simulator
3. Build and run (Cmd+R)
4. Install app on device
```

### 2. Test Settings UI

**Step 2.1: Access Settings**
1. Launch WhisperApp
2. Navigate to Settings (gear icon or menu)
3. Look for "Security Policies" section
4. Find "Contact Required to Send" toggle

**Step 2.2: Test Toggle**
1. Toggle "Contact Required to Send" ON
2. Verify toggle state changes
3. Toggle OFF
4. Verify toggle state changes
5. Close app completely
6. Reopen app
7. Check that setting persisted

**Expected Results:**
- Toggle should work smoothly
- Setting should persist after app restart
- UI should clearly show current state

### 3. Test Policy Enforcement

**Step 3.1: Prepare Test Data**
Use this test public key (64 hex characters):
```
a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

**Step 3.2: Test with Policy DISABLED**
1. Ensure "Contact Required to Send" is OFF in Settings
2. Go to Compose Message screen
3. Enter the test public key as recipient
4. Type a test message: "Testing raw key with policy disabled"
5. Tap Send

**Expected Results:**
- Should accept the raw public key
- Should allow message composition
- Should encrypt and "send" successfully (or show success message)

**Step 3.3: Test with Policy ENABLED**
1. Go to Settings
2. Enable "Contact Required to Send" toggle
3. Return to Compose Message screen
4. Try to enter the same test public key
5. Type a test message: "Testing raw key with policy enabled"
6. Tap Send

**Expected Results:**
- Should block the send operation
- Should show error: "Raw key sending is blocked by policy"
- Message should NOT be encrypted/sent

**Step 3.4: Test Contact Sending (Policy ON)**
1. Ensure "Contact Required to Send" is ON
2. Add a contact first (if none exist):
   - Go to Contacts
   - Add Contact with any public key
   - Give it a name like "Test Contact"
3. Go to Compose Message
4. Select the contact from picker
5. Type message: "Testing contact with policy enabled"
6. Tap Send

**Expected Results:**
- Should allow selecting contacts
- Should allow sending to contacts
- Message should encrypt and send normally

### 4. Edge Case Testing

**Test 4.1: Empty Contact List**
1. Enable "Contact Required to Send"
2. Ensure no contacts exist (delete all if needed)
3. Go to Compose Message
4. Try to compose a message

**Expected:** Should show appropriate guidance about needing contacts

**Test 4.2: Policy Change During Compose**
1. Start composing message to raw key with policy OFF
2. Switch to Settings mid-compose
3. Enable "Contact Required to Send"
4. Return to compose screen
5. Try to send the message

**Expected:** Should respect the new policy setting and block sending

### 5. Debugging and Verification

**Check Xcode Console for:**
- Policy validation logs
- Error messages when policy is violated
- UserDefaults persistence logs

**Verify in Code:**
- `PolicyManager.contactRequiredToSend` property value
- `DefaultWhisperService.encrypt()` calls `validateSendPolicy()`
- Error propagation to UI

### 6. Test Results Checklist

- [ ] Settings toggle works and persists
- [ ] Policy OFF: Raw key sending works
- [ ] Policy ON: Raw key sending blocked with clear error
- [ ] Policy ON: Contact sending still works
- [ ] Error message is user-friendly
- [ ] Policy changes take effect immediately
- [ ] No crashes or unexpected behavior

## Expected Error Messages

When policy blocks raw key sending:
```
"Raw key sending is blocked by policy"
```

## Troubleshooting

**If toggle doesn't work:**
- Check SettingsViewModel.contactRequiredToSend binding
- Verify UserDefaultsPolicyManager.contactRequiredToSend property

**If policy not enforced:**
- Check DefaultWhisperService.encrypt() calls validateSendPolicy()
- Verify PolicyManager.validateSendPolicy() implementation
- Check error propagation to ComposeViewModel

**If errors not shown:**
- Check ComposeViewModel error handling
- Verify WhisperError.policyViolation propagation
- Check UI error display logic

## Files to Monitor
- `WhisperApp/UI/Settings/SettingsView.swift` - Settings UI
- `WhisperApp/UI/Settings/SettingsViewModel.swift` - Settings logic  
- `WhisperApp/Core/Policies/PolicyManager.swift` - Policy validation
- `WhisperApp/Services/WhisperService.swift` - Policy enforcement
- `WhisperApp/UI/Compose/ComposeViewModel.swift` - Error handling

## Success Criteria
✅ Policy toggle works in Settings
✅ Policy blocks raw key sending when enabled
✅ Policy allows contact sending when enabled  
✅ Policy allows raw key sending when disabled
✅ Clear error messages shown to user
✅ Settings persist across app restarts
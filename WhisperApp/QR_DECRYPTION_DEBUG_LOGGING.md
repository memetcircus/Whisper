# QR Decryption Debug Logging Implementation

## Overview
Added comprehensive logging throughout the QR workflow to identify exactly where decryption failures occur during real device testing.

## Logging Points Added

### 1. QR Code Service (`QRCodeService.swift`)
**Location**: `parseQRCode()` and `parseEncryptedMessage()`
**Logs**:
- QR content length and full content
- Format detection (whisper-bundle vs whisper1)
- Component parsing and validation
- Base64 component validation

**Sample Output**:
```
🔍 QR_SERVICE: parseQRCode called
🔍 QR_SERVICE: Content length: 245
🔍 QR_SERVICE: Content prefix (50 chars): whisper1:dGVzdA.dGVzdA.AQ.dGVzdA...
🔍 QR_SERVICE: Detected whisper1 format
🔍 QR_SERVICE: ✅ Has whisper1: prefix
🔍 QR_SERVICE: Component count: 9
🔍 QR_SERVICE: ✅ Valid component count: 9
```

### 2. Decrypt View Model (`DecryptViewModel.swift`)
**Location**: `handleQRScanResult()`, `validateQRContent()`, `decryptMessage()`
**Logs**:
- QR scan result processing
- Envelope validation
- Decryption process start/completion
- Success/failure outcomes

**Sample Output**:
```
🔍 QR_SCAN: Received QR content: whisper1:dGVzdA...
🔍 QR_SCAN: ✅ Envelope validation passed
🔍 DECRYPT_VM: Starting decryption process...
🔍 DECRYPT_VM: ✅ Decryption successful!
```

### 3. Whisper Service (`WhisperService.swift`)
**Location**: `detect()` method
**Logs**:
- Envelope detection process
- Text analysis for whisper1: prefix

**Sample Output**:
```
🔍 WHISPER_SERVICE: detect called
🔍 WHISPER_SERVICE: Text length: 245
🔍 WHISPER_SERVICE: Contains whisper1:: true
```

### 4. Envelope Processor (`EnvelopeProcessor.swift`)
**Location**: `parseEnvelope()` method
**Logs**:
- Complete envelope parsing process
- Component-by-component decoding
- Version validation
- Signature flag consistency

**Sample Output**:
```
🔍 ENVELOPE_PROCESSOR: parseEnvelope called
🔍 ENVELOPE_PROCESSOR: ✅ Has whisper1: prefix
🔍 ENVELOPE_PROCESSOR: All components count: 9
🔍 ENVELOPE_PROCESSOR: ✅ Valid version: v1.c20p
🔍 ENVELOPE_PROCESSOR: ✅ RKID decoded: dGVzdA==
🔍 ENVELOPE_PROCESSOR: ✅ Envelope parsing completed successfully
```

### 5. Identity Manager (`IdentityManager.swift`)
**Location**: `getIdentity(byRkid:)` method
**Logs**:
- Identity lookup by RKID
- Available identities enumeration
- RKID comparison for each identity

**Sample Output**:
```
🔍 IDENTITY_MANAGER: getIdentity(byRkid:) called
🔍 IDENTITY_MANAGER: Looking for RKID: dGVzdA==
🔍 IDENTITY_MANAGER: Available identities: 2
🔍 IDENTITY_MANAGER: Checking identity 0: 'Alice'
🔍 IDENTITY_MANAGER: Identity RKID: bXlSa2lk
🔍 IDENTITY_MANAGER: Match: ❌ NO
🔍 IDENTITY_MANAGER: ✅ Found matching identity: 'Bob'
```

### 6. Contact Manager (`ContactManager.swift`)
**Location**: `listContacts()` method
**Logs**:
- Available contacts enumeration
- Contact fingerprints and signing keys
- Trust levels

**Sample Output**:
```
🔍 CONTACT_MANAGER: Found 3 contacts
🔍 CONTACT_MANAGER: Contact 0: 'Alice'
🔍 CONTACT_MANAGER:   - Fingerprint: dGVzdA==...
🔍 CONTACT_MANAGER:   - Has signing key: true
🔍 CONTACT_MANAGER:   - Trust level: verified
```

## How to Use the Logs

### 1. Enable Console Logging
In Xcode:
1. Run the app on device
2. Open **Window > Devices and Simulators**
3. Select your device
4. Click **Open Console**
5. Filter by your app name or search for "🔍"

### 2. Test QR Workflow
1. Generate QR code on sender device
2. Scan QR code on receiver device
3. Attempt decryption
4. Monitor console for detailed logs

### 3. Identify Failure Points
Look for these patterns in the logs:

**QR Parsing Issues**:
```
🔍 QR_SERVICE: ❌ Missing whisper1: prefix
🔍 QR_SERVICE: ❌ Invalid component count: 7, expected 8-9
```

**Envelope Processing Issues**:
```
🔍 ENVELOPE_PROCESSOR: ❌ Unsupported version: v2.test, expected v1.c20p
🔍 ENVELOPE_PROCESSOR: ❌ Invalid RKID length: 6, expected 8
```

**Identity Mismatch Issues**:
```
🔍 IDENTITY_MANAGER: ❌ No matching identity found for RKID
🔍 DECRYPT DEBUG: ❌ IDENTITY MISMATCH - No matching identity found!
```

**Contact/Signature Issues**:
```
🔍 CONTACT_MANAGER: Found 0 contacts
🔍 DECRYPT DEBUG: No matching contact found for signature
```

## Common Failure Patterns

### 1. Identity Mismatch
**Symptoms**: `messageNotForMe` error
**Logs to Check**:
- RKID in envelope vs available identity RKIDs
- Identity names and key pairs

### 2. Envelope Format Issues
**Symptoms**: `invalidEnvelope` error
**Logs to Check**:
- Component count (should be 8-9)
- Version string (should be v1.c20p)
- Base64 encoding validity

### 3. Contact Missing
**Symptoms**: `contactNotFound` or signature verification failure
**Logs to Check**:
- Available contacts list
- Sender fingerprint matching

### 4. Signature Verification
**Symptoms**: `invalidSignature` or attribution failure
**Logs to Check**:
- Signature flag vs signature data presence
- Contact signing keys availability

## Testing Checklist

When testing with real devices, verify:

1. **QR Generation**: Check that QR contains valid whisper1: envelope
2. **QR Scanning**: Verify QR content is correctly parsed
3. **Identity Setup**: Ensure both devices have matching identities
4. **Contact Setup**: Verify sender is in recipient's contact list
5. **Envelope Format**: Check component count and version
6. **RKID Matching**: Verify recipient identity matches envelope RKID

## Next Steps

After running tests with logging:

1. **Collect Logs**: Copy relevant log sections from Xcode console
2. **Identify Pattern**: Look for the first ❌ error in the sequence
3. **Root Cause**: Match error pattern to common failure types above
4. **Fix Issue**: Address the specific root cause (identity sync, contact setup, etc.)

The comprehensive logging will pinpoint exactly where in the QR workflow the failure occurs, making it much easier to diagnose and fix the decryption issues.
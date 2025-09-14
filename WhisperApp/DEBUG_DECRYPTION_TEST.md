# 🔍 Decryption Debug Test Guide

## How to Get Debug Logs

### 1. Build and Run
```bash
cd WhisperApp
# Build the project
xcodebuild -project WhisperApp.xcodeproj -scheme WhisperApp -destination 'platform=iOS Simulator,name=iPhone 15' build

# Or just run in Xcode
```

### 2. Open Console in Xcode
- **Xcode → View → Debug Area → Activate Console**
- Or press **⌘+Shift+C**

### 3. Test Decryption
1. Open the app in simulator
2. Go to **Decrypt** tab
3. Paste your encrypted message:
   ```
   whisper1:v1.c20p.0eXcjEuWHjw.AA.5m5K...
   ```
4. Tap **"Decrypt Message"**

### 4. Copy Console Output
The console will show a formatted debug log like this:

```
================================================================================
🔍 WHISPER DECRYPTION DEBUG LOG - START
================================================================================
🔍 DECRYPT DEBUG: Starting decryption process
🔍 DECRYPT DEBUG: Envelope length: 513
🔍 DECRYPT DEBUG: Step 4 - Finding recipient identity...
🔍 DECRYPT DEBUG: Message RKID: 0eXcjEuWHjw
🔍 DECRYPT DEBUG: Available identities: 2
🔍 DECRYPT DEBUG: Identity 0: 'Tugba'
🔍 DECRYPT DEBUG:   - RKID: ABC123xyz
🔍 DECRYPT DEBUG:   - Matches: ❌ NO
🔍 DECRYPT DEBUG: Identity 1: 'Test User'
🔍 DECRYPT DEBUG:   - RKID: XYZ789abc
🔍 DECRYPT DEBUG:   - Matches: ❌ NO
🔍 DECRYPT DEBUG: ❌ IDENTITY MISMATCH - No matching identity found!
================================================================================
🔍 WHISPER DECRYPTION DEBUG LOG - FAILED
================================================================================
```

### 5. Share the Logs
**Copy the entire section between the `====` lines and paste it here.**

## 🎯 What We're Looking For

### Most Likely Issue: Identity Mismatch
If you see:
```
🔍 DECRYPT DEBUG: ❌ IDENTITY MISMATCH - No matching identity found!
```

**This means:**
- Akif encrypted the message to a specific identity (RKID)
- Tugba's phone has different identities
- The RKIDs don't match

### Solution Options:

1. **Use Same Identity Name**
   - Both phones should have identity with same name (e.g., "Tugba")
   - Export/import identity between phones

2. **Check Contact Setup**
   - Verify Akif has Tugba's correct public key
   - Verify Tugba has Akif as verified contact

3. **Re-create Identities**
   - Create fresh identities on both phones
   - Exchange public keys via QR codes

## 🚀 Quick Test

To verify the app works, try **self-encryption**:

1. **Compose** tab → **Raw Key** mode
2. Go to **Settings** → copy your own public key
3. Paste your public key as recipient
4. Type "test" and encrypt
5. Copy result and decrypt it
6. Should decrypt to "test" ✅

This confirms the crypto works - then we fix the identity matching!
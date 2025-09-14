# Real Contact Testing Guide - Two iPhone Setup

## 📱 **Device Setup**
- **iPhone XR** = Tugba
- **iPhone 11 Pro** = Akif
- Both devices have Whisper app installed

## 🎯 **Testing Workflow Overview**

### **Phase 1: Create Identities (Generate Public Keys)**
### **Phase 2: Manual Contact Addition**
### **Phase 3: QR Code Contact Addition**
### **Phase 4: End-to-End Message Testing**

---

## 📋 **Phase 1: Create Identities**

### **Step 1.1: Create Identity on Tugba's iPhone XR**

1. **Open Whisper app on iPhone XR**
2. **Go to Settings**
3. **Tap "Identity Management"**
4. **Tap "Create New Identity"**
5. **Enter details:**
   - **Name:** "Tugba"
   - **Description:** "Tugba's main identity"
6. **Tap "Create Identity"**
7. **Wait for key generation to complete**
8. **Note down or screenshot the identity details:**
   - Identity ID
   - X25519 Public Key
   - Ed25519 Public Key (if shown)

### **Step 1.2: Create Identity on Akif's iPhone 11 Pro**

1. **Open Whisper app on iPhone 11 Pro**
2. **Go to Settings**
3. **Tap "Identity Management"**
4. **Tap "Create New Identity"**
5. **Enter details:**
   - **Name:** "Akif"
   - **Description:** "Akif's main identity"
6. **Tap "Create Identity"**
7. **Wait for key generation to complete**
8. **Note down or screenshot the identity details:**
   - Identity ID
   - X25519 Public Key
   - Ed25519 Public Key (if shown)

### **Step 1.3: Export Public Keys**

**On Tugba's iPhone XR:**
1. **Go to Settings → Identity Management**
2. **Tap on "Tugba" identity**
3. **Look for "Export Public Key" or "Share Public Key"**
4. **Copy or share the public key data**

**On Akif's iPhone 11 Pro:**
1. **Go to Settings → Identity Management**
2. **Tap on "Akif" identity**
3. **Look for "Export Public Key" or "Share Public Key"**
4. **Copy or share the public key data**

---

## 📋 **Phase 2: Manual Contact Addition**

### **Step 2.1: Add Akif to Tugba's Contacts (Manual Entry)**

**On Tugba's iPhone XR:**

1. **Open Whisper app**
2. **Tap "Manage Contacts"**
3. **Tap the "+" button (Add Contact)**
4. **Select "Manual Entry" tab**
5. **Fill in the form:**
   - **Display Name:** "Akif"
   - **X25519 Public Key:** [Paste Akif's X25519 public key]
   - **Ed25519 Signing Key:** [Paste Akif's Ed25519 public key if available]
   - **Note:** "Akif from iPhone 11 Pro"
6. **Tap "Add"**
7. **Verify contact appears in contact list**

### **Step 2.2: Add Tugba to Akif's Contacts (Manual Entry)**

**On Akif's iPhone 11 Pro:**

1. **Open Whisper app**
2. **Tap "Manage Contacts"**
3. **Tap the "+" button (Add Contact)**
4. **Select "Manual Entry" tab**
5. **Fill in the form:**
   - **Display Name:** "Tugba"
   - **X25519 Public Key:** [Paste Tugba's X25519 public key]
   - **Ed25519 Signing Key:** [Paste Tugba's Ed25519 public key if available]
   - **Note:** "Tugba from iPhone XR"
6. **Tap "Add"**
7. **Verify contact appears in contact list**

### **Step 2.3: Verify Manual Addition**

**On both devices:**
1. **Go to Contacts**
2. **Verify the other person appears in the list**
3. **Check contact details:**
   - Name is correct
   - Trust level shows "Unverified" (orange badge)
   - ID/fingerprint is shown
4. **Close and reopen app**
5. **Verify contacts persist (no dummy contacts)**

---

## 📋 **Phase 3: QR Code Contact Addition**

### **Step 3.1: Generate QR Code for Contact Sharing**

**On Tugba's iPhone XR:**
1. **Go to Settings → Identity Management**
2. **Tap on "Tugba" identity**
3. **Look for "Generate QR Code" or "Share as QR Code"**
4. **Generate QR code containing public key bundle**
5. **Display QR code on screen**

### **Step 3.2: Scan QR Code to Add Contact**

**On Akif's iPhone 11 Pro:**
1. **Go to Contacts → Add Contact**
2. **Select "QR Code" tab**
3. **Tap "Open Camera"**
4. **Point camera at Tugba's QR code**
5. **Wait for scan to complete**
6. **Verify contact preview appears**
7. **Tap "Add Contact"**
8. **Verify "Tugba" appears in contact list**

### **Step 3.3: Reverse QR Code Test**

**On Akif's iPhone 11 Pro:**
1. **Generate QR code for Akif's identity**

**On Tugba's iPhone XR:**
1. **Scan Akif's QR code using Add Contact → QR Code**
2. **Verify contact is added successfully**

---

## 📋 **Phase 4: End-to-End Message Testing**

### **Step 4.1: Send Message from Tugba to Akif**

**On Tugba's iPhone XR:**
1. **Tap "Compose Message"**
2. **Select "Tugba" identity (if multiple)**
3. **Select "Akif" as recipient**
4. **Type message:** "Hello Akif! This is a test message from Tugba's iPhone XR."
5. **Tap "Encrypt Message"**
6. **Wait for encryption to complete**
7. **Tap "Share" and copy encrypted message**
8. **Send encrypted message to Akif via any method (AirDrop, Messages, etc.)**

### **Step 4.2: Decrypt Message on Akif's Device**

**On Akif's iPhone 11 Pro:**
1. **Copy the encrypted message from Tugba**
2. **Open Whisper app**
3. **Tap "Decrypt Message"**
4. **Paste encrypted message**
5. **Tap "Decrypt"**
6. **Verify message decrypts successfully**
7. **Verify sender shows as "Tugba"**

### **Step 4.3: Send Reply from Akif to Tugba**

**On Akif's iPhone 11 Pro:**
1. **Tap "Compose Message"**
2. **Select "Akif" identity**
3. **Select "Tugba" as recipient**
4. **Type message:** "Hello Tugba! Got your message. This is Akif replying from iPhone 11 Pro."
5. **Encrypt and share message**

**On Tugba's iPhone XR:**
1. **Decrypt Akif's reply**
2. **Verify successful decryption**

---

## 🔍 **Troubleshooting Common Issues**

### **Identity Creation Issues:**
- **Problem:** "Create Identity" button doesn't work
- **Solution:** Check if app has keychain access permissions

### **Manual Contact Addition Issues:**
- **Problem:** "Invalid public key" error
- **Solution:** Ensure public key is properly formatted (Base64 or hex)
- **Check:** Key length should be 32 bytes for X25519

### **QR Code Issues:**
- **Problem:** QR code won't scan
- **Solution:** Ensure good lighting and steady camera
- **Check:** QR code contains valid contact data format

### **Message Encryption/Decryption Issues:**
- **Problem:** "Contact not found" error
- **Solution:** Ensure contact is properly added with correct public key
- **Check:** Identity is created and active

---

## 📊 **Expected Results**

### **After Phase 1 (Identity Creation):**
- ✅ Both devices have unique identities
- ✅ Public keys are generated and accessible
- ✅ Identities persist after app restart

### **After Phase 2 (Manual Addition):**
- ✅ Each device has the other as a contact
- ✅ Contacts show "Unverified" trust level
- ✅ Contacts persist after app restart
- ✅ No dummy contacts (Alice, Bob, Charlie) appear

### **After Phase 3 (QR Code Addition):**
- ✅ QR code scanning works without blank screens
- ✅ Contacts can be added via QR code
- ✅ QR-added contacts appear in contact list

### **After Phase 4 (Message Testing):**
- ✅ Messages encrypt successfully
- ✅ Messages decrypt successfully
- ✅ Sender identification works correctly
- ✅ End-to-end encryption is functional

---

## 🚨 **Issues to Report**

### **Critical Issues:**
- App crashes during any step
- Identities not persisting
- Contacts not persisting
- Encryption/decryption failures

### **UI Issues:**
- Blank screens
- Buttons not responding
- Navigation problems
- Missing or incorrect data display

### **Data Issues:**
- Dummy contacts appearing
- Real contacts disappearing
- Invalid key formats
- Persistence problems

---

## 📝 **Testing Checklist**

### **Pre-Testing:**
- [ ] Both iPhones have Whisper app installed
- [ ] Apps are updated to latest version
- [ ] Devices have camera permissions enabled

### **Phase 1 - Identity Creation:**
- [ ] Tugba's identity created successfully
- [ ] Akif's identity created successfully
- [ ] Public keys are accessible
- [ ] Identities persist after app restart

### **Phase 2 - Manual Contact Addition:**
- [ ] Tugba added Akif manually
- [ ] Akif added Tugba manually
- [ ] Contacts appear in both contact lists
- [ ] No dummy contacts present
- [ ] Contacts persist after app restart

### **Phase 3 - QR Code Addition:**
- [ ] QR codes generate successfully
- [ ] QR codes scan without blank screens
- [ ] Contacts added via QR code
- [ ] QR-added contacts persist

### **Phase 4 - Message Testing:**
- [ ] Message encryption works
- [ ] Message decryption works
- [ ] Sender identification correct
- [ ] Bidirectional messaging works

### **Final Verification:**
- [ ] No dummy contacts in either app
- [ ] Real contacts persist across app restarts
- [ ] End-to-end encryption functional
- [ ] UI navigation works smoothly

---

## 🎉 **Success Criteria**

**The real implementation testing is successful when:**

1. ✅ **Both devices have real identities** (not mock)
2. ✅ **Contacts are real user-added contacts** (not dummy)
3. ✅ **Manual contact addition works**
4. ✅ **QR code contact addition works**
5. ✅ **End-to-end message encryption/decryption works**
6. ✅ **All data persists across app restarts**
7. ✅ **No UI navigation issues or blank screens**

**Ready to test the real implementation!** 🚀
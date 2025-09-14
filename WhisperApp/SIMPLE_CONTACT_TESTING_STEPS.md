# Simple Contact Testing Steps - Tugba & Akif

## 🎯 **Quick Testing Guide**

### **Step 1: Create Identities (Both Phones)**

**On Tugba's iPhone XR:**
1. Open Whisper app
2. Tap "Settings"
3. Tap "Identity Management"
4. Tap "Create New" (top right)
5. Enter name: "Tugba"
6. Tap "Create"
7. Wait for completion

**On Akif's iPhone 11 Pro:**
1. Open Whisper app
2. Tap "Settings"
3. Tap "Identity Management"
4. Tap "Create New" (top right)
5. Enter name: "Akif"
6. Tap "Create"
7. Wait for completion

### **Step 2: Generate QR Codes**

**On Tugba's iPhone XR:**
1. In Identity Management
2. Tap "Generate QR Code" next to Tugba identity
3. QR code will appear on screen
4. Keep this screen open

**On Akif's iPhone 11 Pro:**
1. In Identity Management
2. Tap "Generate QR Code" next to Akif identity
3. QR code will appear on screen
4. Keep this screen open

### **Step 3: Add Contacts via QR Code**

**Add Tugba to Akif's contacts:**
1. On Akif's phone: Go to main screen → "Manage Contacts"
2. Tap "+" (Add Contact)
3. Select "QR Code" tab
4. Tap "Open Camera"
5. Point camera at Tugba's QR code (on her screen)
6. Wait for scan to complete
7. Verify contact preview shows "Tugba"
8. Tap "Add"

**Add Akif to Tugba's contacts:**
1. On Tugba's phone: Go to main screen → "Manage Contacts"
2. Tap "+" (Add Contact)
3. Select "QR Code" tab
4. Tap "Open Camera"
5. Point camera at Akif's QR code (on his screen)
6. Wait for scan to complete
7. Verify contact preview shows "Akif"
8. Tap "Add"

### **Step 4: Verify Contacts**

**On both phones:**
1. Go to "Manage Contacts"
2. Verify the other person appears in contact list
3. Check that trust level shows "Unverified" (orange badge)
4. No dummy contacts (Alice, Bob, Charlie) should appear

### **Step 5: Test Manual Entry (Alternative)**

If QR code doesn't work, try manual entry:

**Get Public Key:**
1. On Tugba's phone: Settings → Identity Management
2. Tap on "Tugba" identity
3. Look for public key display or copy option
4. Copy the X25519 public key

**Add Manually:**
1. On Akif's phone: Manage Contacts → Add Contact
2. Select "Manual Entry" tab
3. Enter:
   - Display Name: "Tugba"
   - X25519 Public Key: [paste Tugba's key]
4. Tap "Add"

### **Step 6: Test End-to-End Messaging**

**Send message from Tugba to Akif:**
1. On Tugba's phone: Tap "Compose Message"
2. Select "Tugba" identity (if multiple)
3. Select "Akif" as recipient
4. Type: "Hello Akif! Test message from Tugba."
5. Tap "Encrypt Message"
6. Tap "Share" and copy the encrypted text
7. Send to Akif via any method (AirDrop, Messages, etc.)

**Decrypt on Akif's phone:**
1. Copy the encrypted message from Tugba
2. Open Whisper app
3. Tap "Decrypt Message"
4. Paste the encrypted message
5. Tap "Decrypt"
6. Verify message appears correctly

## 🚨 **Common Issues & Solutions**

### **QR Code Issues:**
- **Camera won't open:** Check camera permissions in iOS Settings
- **QR code won't scan:** Ensure good lighting, hold steady
- **Blank screen after cancel:** This should be fixed now

### **Contact Issues:**
- **Dummy contacts appear:** Check that real implementation is active
- **Contacts don't persist:** Check CoreData permissions
- **"Invalid public key" error:** Ensure key is properly formatted

### **Identity Issues:**
- **Can't create identity:** Check keychain permissions
- **No QR code generated:** Check if QRCodeService is working

## ✅ **Success Criteria**

After completing these steps, you should have:
- ✅ Real identities created (not mock)
- ✅ Real contacts added (not dummy)
- ✅ QR code scanning working
- ✅ Manual contact entry working
- ✅ End-to-end messaging working
- ✅ Data persisting across app restarts

## 📝 **What to Report**

**If successful:** "Contact addition working! Both QR and manual entry successful."

**If issues:** Report which step failed and what error appeared:
- Step number where it failed
- Exact error message
- Which phone (iPhone XR/11 Pro)
- Screenshot if helpful

**Ready to test!** 🚀
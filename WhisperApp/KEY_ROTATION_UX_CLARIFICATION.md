# Key Rotation UX Clarification & Improvements

## 🤔 User Confusion Identified

**Issue**: After clicking "Rotate Keys", a new identity with the same name appeared, causing confusion about whether this was intended behavior.

**User Question**: "Do we create a new identity at the end of this process?"

## ✅ Answer: Yes, This Is Correct Behavior

Key rotation in Whisper **intentionally creates a new identity** rather than updating the existing one. This is a **security best practice** for the following reasons:

### **Why Create New Identity Instead of Updating Keys?**

1. **Forward Secrecy**: Old messages remain decryptable with archived identity
2. **Clean Separation**: Clear distinction between old and new cryptographic material  
3. **Audit Trail**: Maintains history of key rotations for security analysis
4. **Rollback Safety**: If new keys are compromised, old identity remains separate

## 🔧 UX Improvements Implemented

### **1. Clear Naming Convention**
**Before**: Both identities had identical names (confusing)
```
Project A  (Active)
Project A  (Active) ← Confusing duplicate!
```

**After**: New identity has clear rotation indicator
```
Project A                    (Archived)
Project A (Rotated 2025-01-09)  (Active) ← Clear distinction!
```

### **2. Automatic Archiving**
**Before**: Old identity remained active (security risk)
**After**: Old identity is automatically archived for decrypt-only access

### **3. Improved User Messaging**
**Before**: "This will create a new identity and optionally archive the current one"
**After**: "This will create a new identity with fresh keys and archive the current one for security. The old identity will remain available for decrypting past messages."

### **4. Better Visual Hierarchy**
- **New Identity**: Shows as "Active" with rotation date
- **Old Identity**: Shows as "Archived" status
- **Clear Status**: Users can immediately see which is current

## 📱 Updated User Experience Flow

### **Before Rotation:**
```
DEFAULT IDENTITY
├── Project A (Active) ← Current identity

ALL IDENTITIES  
├── Project A (Active)
```

### **After Rotation:**
```
DEFAULT IDENTITY
├── Project A (Rotated 2025-01-09) (Active) ← New default

ALL IDENTITIES
├── Project A (Rotated 2025-01-09) (Active) ← New identity  
├── Project A (Archived)                    ← Old identity (decrypt-only)
```

## 🔒 Security Benefits

1. **Forward Secrecy**: Past messages remain decryptable with archived keys
2. **Key Isolation**: New and old keys are completely separate
3. **Forced Archiving**: Old keys can't be used for new messages
4. **Clear Audit Trail**: Easy to track when keys were rotated

## 🎯 User Understanding

**Key Rotation Process:**
1. **Creates** a new identity with fresh cryptographic keys
2. **Archives** the old identity (making it decrypt-only)
3. **Sets** the new identity as the active default
4. **Preserves** the old identity for decrypting past messages

**This is NOT a bug** - it's the intended security behavior that ensures proper key hygiene and forward secrecy!

## ✅ Result

Users now clearly understand that:
- ✅ Key rotation creates a new identity (by design)
- ✅ Old identity is preserved for decrypting past messages  
- ✅ New identity has a clear name indicating when it was rotated
- ✅ Only the new identity can be used for sending new messages
- ✅ This provides better security through key separation

The behavior is now **clear and intentional** rather than confusing!
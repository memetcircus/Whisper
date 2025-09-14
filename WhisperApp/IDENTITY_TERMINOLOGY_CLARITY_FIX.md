# Identity Terminology Clarity Fix

## 🚨 Problem Identified

**Confusing Terminology**: The app was using "ACTIVE" for two different concepts:

1. **"ACTIVE" badge** = Currently selected/default identity for compose messages
2. **"Active" status** = Identity lifecycle state (not archived)

**Result**: Project A showed both "ACTIVE" badge AND "Active" status, creating redundancy and user confusion.

## 💡 Solution Applied

Changed **"ACTIVE" badge** to **"DEFAULT"** to clearly distinguish:

- **"DEFAULT" badge** = Currently selected identity for composing messages
- **"Active" status** = Identity lifecycle state (Active/Archived)

## 🔧 Changes Made

### **1. Identity Management View**

**File**: `WhisperApp/UI/Settings/IdentityManagementView.swift`

```swift
// BEFORE: Confusing dual "ACTIVE" indicators
if isActive && identity.status == .active {
    Text("ACTIVE")
        .background(Color.green)
}
Section("Active Identity") {
    // ...
}

// AFTER: Clear distinction
if isActive && identity.status == .active {
    Text("DEFAULT")
        .background(Color.blue)  // Different color too
}
Section("Default Identity") {
    // ...
}
```

### **2. Localization Strings**

**File**: `WhisperApp/WhisperApp/Localizable.strings`

```swift
// BEFORE: Confusing terminology
"identity.active" = "Active Identity";
"encrypt.error.no_identity" = "No active identity selected";
"accessibility.identity_selector" = "Select active identity";

// AFTER: Clear terminology
"identity.active" = "Default Identity";
"encrypt.error.no_identity" = "No default identity selected";
"accessibility.identity_selector" = "Select default identity";
```

### **3. Compose View**

**File**: `WhisperApp/UI/Compose/ComposeView.swift`

```swift
// BEFORE: Confusing message
Text("No active identity")

// AFTER: Clear message
Text("No default identity selected")
```

## 🎨 Visual Improvements

### **Color Coding**
- **DEFAULT badge**: Blue background (distinguishes from status)
- **Active status**: Green text (lifecycle state)
- **Archived status**: Gray text (lifecycle state)

### **Clear Hierarchy**
```
Identity Management Screen:
┌─────────────────────────────────┐
│ DEFAULT IDENTITY                │
├─────────────────────────────────┤
│ Project A [DEFAULT]             │ ← Blue badge
│ Status: Active                  │ ← Green text
├─────────────────────────────────┤
│ ALL IDENTITIES                  │
├─────────────────────────────────┤
│ Project C                       │
│ Status: Active                  │ ← No badge, just status
│ Project B                       │
│ Status: Active                  │
│ Work                            │
│ Status: Archived                │ ← Gray text
└─────────────────────────────────┘
```

## 📊 Terminology Comparison

| Concept | Before | After | Purpose |
|---------|--------|-------|---------|
| **Currently Selected** | "ACTIVE" badge | "DEFAULT" badge | Identity used for composing |
| **Lifecycle State** | "Active" status | "Active" status | Not archived/deprecated |
| **Section Header** | "Active Identity" | "Default Identity" | Currently selected section |

## ✅ Benefits

1. **Clear Purpose**: "Default" clearly indicates the identity used by default for composing
2. **No Confusion**: Distinguishes from lifecycle status (Active/Archived)
3. **User-Friendly**: Users understand "default" means "currently selected"
4. **Visual Distinction**: Blue badge vs green status text
5. **Industry Standard**: Many apps use "Default" for currently selected options

## 🎯 Expected User Experience

### **Before (Confusing)**
- User sees "Project A [ACTIVE]" with "Status: Active" → "Why is ACTIVE mentioned twice?"
- User sees "Work [ACTIVE]" with "Status: Archived" → "How can it be both ACTIVE and Archived?"

### **After (Clear)**
- User sees "Project A [DEFAULT]" with "Status: Active" → "This is my default identity and it's active"
- User sees "Work" with "Status: Archived" → "This identity is archived and not my default"

## 🧪 Testing

Build and test the app to verify:

1. ✅ **Identity Management**: Shows "DEFAULT" badge only for currently selected identity
2. ✅ **Section Headers**: "Default Identity" section is clear
3. ✅ **Status Display**: Active/Archived status is separate from DEFAULT badge
4. ✅ **Compose View**: Uses "default identity" terminology consistently
5. ✅ **Color Coding**: Blue for DEFAULT badge, green/gray for status

## 📝 Files Modified

1. **`WhisperApp/UI/Settings/IdentityManagementView.swift`**
   - Changed "ACTIVE" badge to "DEFAULT" with blue background
   - Updated section header to "Default Identity"
   - Updated error message

2. **`WhisperApp/WhisperApp/Localizable.strings`**
   - Updated identity-related localization strings
   - Changed "active identity" to "default identity"

3. **`WhisperApp/UI/Compose/ComposeView.swift`**
   - Updated error message for consistency

4. **`WhisperApp/IDENTITY_TERMINOLOGY_CLARITY_FIX.md`**
   - This documentation

## 🎯 Resolution Status

**TERMINOLOGY CONFUSION RESOLVED**:

✅ **Clear Badge Purpose**: "DEFAULT" badge indicates currently selected identity
✅ **Distinct Status Display**: Active/Archived status separate from selection
✅ **Consistent Language**: All UI text uses "default identity" terminology
✅ **Visual Distinction**: Blue badge vs green/gray status text
✅ **User-Friendly**: Intuitive understanding of identity selection vs lifecycle

The identity management system now uses clear, unambiguous terminology that helps users understand the difference between their currently selected identity and the lifecycle status of their identities.
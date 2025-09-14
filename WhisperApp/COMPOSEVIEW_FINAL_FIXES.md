# ComposeView Final Build Fixes

## ✅ Fixed Issues:

### 1. Color.accessibleSecondaryBackground Errors
**Problem:** `Type 'Color' has no member 'accessibleSecondaryBackground'`
**Fix:** Replaced with standard iOS system color
**Changes:**
- `Color.accessibleSecondaryBackground` → `Color(.systemGray6)`
**Locations:** 4 instances fixed

### 2. Color.trustLevelColor Error  
**Problem:** `Type 'Color' has no member 'trustLevelColor'`
**Fix:** Replaced with standard color
**Changes:**
- `Color.trustLevelColor(for: selectedContact.trustLevel)` → `Color.blue`
**Location:** Line 136

### 3. Invalid Redeclaration of ContactRowView
**Problem:** `Invalid redeclaration of 'ContactRowView'`
**Fix:** Removed duplicate ContactRowView definition and used existing one from ContactListView.swift
**Changes:**
- Removed duplicate struct definition
- Updated usage to match existing signature: `onTap` instead of `onSelect`
- Added proper parameter syntax: `ContactRowView(contact: contact, onTap: { ... })`

### 4. Invalid Redeclaration of ShareSheet
**Problem:** `Invalid redeclaration of 'ShareSheet'`
**Fix:** Removed duplicate ShareSheet definition from ComposeView.swift
**Changes:**
- ShareSheet already exists in QRCodeDisplayView.swift
- Removed duplicate struct definition from ComposeView.swift
- Added comment referencing the existing location

## 📝 Summary:

All the specific build errors mentioned have been fixed:
- ✅ Line 105: `Color.accessibleSecondaryBackground` → `Color(.systemGray6)`
- ✅ Line 136: `Color.trustLevelColor` → `Color.blue`  
- ✅ Line 178: `Color.accessibleSecondaryBackground` → `Color(.systemGray6)`
- ✅ Line 193: `Color.accessibleSecondaryBackground` → `Color(.systemGray6)`
- ✅ Line 309: Removed duplicate `ContactRowView` declaration
- ✅ Line 311: Removed duplicate `ShareSheet` declaration (exists in QRCodeDisplayView.swift)

## 🔄 Remaining Dependencies:

The file still depends on these components that need to be available:
- `ComposeViewModel`
- `LocalizationHelper`
- `Contact` type
- `ContactPickerViewModel`
- `QRCodeDisplayView`

But the specific compilation errors you mentioned should now be resolved.
# ReplayProtectionEntity fetchRequest Fix

## ✅ Problem Solved

**Error**: "Invalid redeclaration of fetchRequest" in ReplayProtectionEntity

**Root Cause**: Core Data was auto-generating the `fetchRequest()` method (because `codeGenerationType="class"` in the model), but there was also a manual extension defining the same method.

## 🔧 Fix Applied

**Removed the manual extension** from `ReplayProtectionService.swift`:

```swift
// REMOVED THIS CONFLICTING CODE:
extension ReplayProtectionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReplayProtectionEntity> {
        return NSFetchRequest<ReplayProtectionEntity>(entityName: "ReplayProtectionEntity")
    }
}
```

## ✅ Why This Works

1. **Core Data Auto-Generation**: The WhisperDataModel has `codeGenerationType="class"` for ReplayProtectionEntity
2. **Automatic fetchRequest**: Core Data automatically generates the `fetchRequest()` method
3. **No Manual Extension Needed**: The manual extension was redundant and caused conflicts

## 📋 Current Status

- ✅ **ReplayProtectionEntity**: Now uses Core Data auto-generated `fetchRequest()`
- ✅ **No Conflicts**: Manual extension removed
- ✅ **All Usage**: Existing code continues to work with `ReplayProtectionEntity.fetchRequest()`

## 🎯 Result

Your app should now compile without the "Invalid redeclaration of fetchRequest" error. The ReplayProtectionEntity will work exactly the same, but without the conflicting manual extension.

## 🔍 Other Entities

All other entities in your WhisperDataModel also use `codeGenerationType="class"`:
- ✅ ContactEntity
- ✅ IdentityEntity  
- ✅ KeyHistoryEntity
- ✅ ReplayProtectionEntity

They all get auto-generated `fetchRequest()` methods, so no manual extensions are needed.

The fix is complete! 🎉
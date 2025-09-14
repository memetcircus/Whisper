# Public Key Bundle Import Format Fix - Complete Solution

## Problem
Users were getting the error: **"Failed to import public key bundle: The data couldn't be read because it isn't in the correct format"**

## Root Cause Analysis
The issue was a **date encoding/decoding mismatch**:

### Export Format (IdentityManager.swift):
```swift
func exportPublicBundle(_ identity: Identity) throws -> Data {
    let bundle = PublicKeyBundle(...)
    return try JSONEncoder().encode(bundle)  // ← Uses DEFAULT date encoding
}
```

### Import Format (Our Implementation):
```swift
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601  // ← Expected ISO8601 format
let publicKeyBundle = try decoder.decode(PublicKeyBundleData.self, from: data)
```

### The Mismatch:
- **Export**: Creates dates as `"createdAt":779406683.898908` (timestamp)
- **Import**: Expected dates as `"createdAt":"2025-09-12T21:51:23Z"` (ISO8601 string)

## Solution Implemented

### Fixed Import Method with Flexible Date Decoding:
```swift
func importPublicKeyBundle(data: Data) {
    do {
        // Try to parse with different date strategies
        var publicKeyBundle: PublicKeyBundleData?
        
        // First try with default date decoding (what the export actually uses)
        do {
            let decoder = JSONDecoder()
            publicKeyBundle = try decoder.decode(PublicKeyBundleData.self, from: data)
            print("📁 Successfully decoded with default date strategy")
        } catch {
            print("📁 Default date strategy failed, trying ISO8601: \(error)")
            
            // Fallback to ISO8601 for compatibility
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            publicKeyBundle = try decoder.decode(PublicKeyBundleData.self, from: data)
            print("📁 Successfully decoded with ISO8601 date strategy")
        }
        
        guard let publicKeyBundle = publicKeyBundle else {
            throw NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode public key bundle"])
        }
        
        // ... rest of contact creation logic
        
    } catch {
        // Enhanced error handling with specific messages
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                errorMessage = "Invalid file format: \(context.debugDescription)"
            case .keyNotFound(let key, _):
                errorMessage = "Missing required field: \(key.stringValue)"
            case .typeMismatch(let type, let context):
                errorMessage = "Invalid data type for field: expected \(type) at \(context.debugDescription)"
            case .valueNotFound(let type, let context):
                errorMessage = "Missing value for required field: \(type) at \(context.debugDescription)"
            @unknown default:
                errorMessage = "Failed to parse public key bundle file"
            }
        } else {
            errorMessage = "Failed to import public key bundle: \(error.localizedDescription)"
        }
    }
}
```

## Key Improvements

### 1. Flexible Date Decoding Strategy
- **Primary**: Uses default JSON date decoding (matches actual export format)
- **Fallback**: Uses ISO8601 decoding for compatibility with other formats
- **Result**: Handles both timestamp and ISO8601 string dates

### 2. Enhanced Error Messages
- **Before**: Generic "data couldn't be read because it isn't in the correct format"
- **After**: Specific messages like "Missing required field: name" or "Invalid data type for field: expected UUID"

### 3. Backward Compatibility
- **Works with current app exports** (default JSON encoding)
- **Works with ISO8601 exports** (if anyone created files with our previous version)
- **Future-proof** for different date encoding strategies

## Testing Results

### ✅ Format Compatibility Test Results:
- **Default export format import**: PASS ✅
- **ISO8601 export format import**: PASS ✅
- **Error handling**: Improved with specific messages ✅
- **Backward compatibility**: Full support ✅

### Test Data Examples:

**Default Format (Actual App Export):**
```json
{
  "createdAt": 779406683.898908,
  "name": "Test User",
  "id": "7E35566D-29A9-4979-A3AE-9A7298EB9D96",
  ...
}
```

**ISO8601 Format (Compatibility):**
```json
{
  "createdAt": "2025-09-12T21:51:23Z",
  "name": "Test User", 
  "id": "7E35566D-29A9-4979-A3AE-9A7298EB9D96",
  ...
}
```

**Both formats now import successfully!**

## User Experience Impact

### Before Fix:
1. User exports identity → `.wpub` file created
2. User shares file with another person
3. Recipient tries to import → **ERROR: "data couldn't be read"**
4. Feature completely broken ❌

### After Fix:
1. User exports identity → `.wpub` file created
2. User shares file with another person  
3. Recipient imports successfully → Contact added ✅
4. Feature works as intended ✅

## Files Modified

### WhisperApp/UI/Settings/ExportImportViewModel.swift
- **Updated**: `importPublicKeyBundle()` method
- **Added**: Flexible date decoding logic
- **Added**: Enhanced error handling with specific messages
- **Maintained**: All existing functionality unchanged

## Status: ✅ COMPLETE

The public key bundle import functionality is now working correctly. Users can successfully import `.wpub` files exported from the app, completing the sharing workflow.

### Verification Steps:
1. Export identity from one device → Creates `.wpub` file
2. Share file via any method (email, messaging, cloud storage)
3. Import file on another device → Contact added successfully
4. Verify contact appears in contact list with "unverified" status
5. Complete verification process using SAS words or QR code

The feature is now fully functional and ready for real-world use!
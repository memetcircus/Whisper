# Identity Rotation Naming Fix

## 🚨 Problem Identified

**Issue**: Key rotation was creating nested, extremely long identity names by appending rotation suffixes to already-rotated names.

**Example of the Problem**:
```
Original: Project A
After 1st rotation: Project A (Rotated 2025-09-09)
After 2nd rotation: Project A (Rotated 2025-09-09) (Rotated 2025-09-09)
After 3rd rotation: Project A (Rotated 2025-09-09) (Rotated 2025-09-09) (Rotated 2025-09-09)
```

This created unreadable, extremely long identity names that broke the UI layout.

## 🔧 Root Cause

The `rotateActiveIdentity()` method was taking the current identity's full name (including any existing rotation suffix) and appending a new rotation suffix:

```swift
// ❌ PROBLEMATIC CODE
let newName = "\(currentActive.name) (Rotated \(dateString))"
```

If `currentActive.name` was already "Project A (Rotated 2025-09-09)", this would create "Project A (Rotated 2025-09-09) (Rotated 2025-09-09)".

## ✅ Solution Implemented

### **1. Base Name Extraction**
Added a `extractBaseName()` method that removes all existing rotation suffixes:

```swift
private func extractBaseName(from name: String) -> String {
    let pattern = #" \(Rotated \d{4}-\d{2}-\d{2}\)"#
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: name.utf16.count)
    let cleanName = regex.stringByReplacingMatches(in: name, options: [], range: range, withTemplate: "")
    
    return cleanName.isEmpty ? name : cleanName
}
```

### **2. Clean Rotation Logic**
Updated `rotateActiveIdentity()` to use the base name:

```swift
// Extract the base name by removing any existing rotation suffix
let baseName = extractBaseName(from: currentActive.name)

// Create new identity with clean rotation suffix
let newName = "\(baseName) (Rotated \(dateString))"
```

## 🎯 Results

### **Before Fix**:
```
Project A (Rotated 2025-09-09) (Rotated 2025-09-09) (Rotated 2025-09-09) (Rotated 2025-09-09)
```

### **After Fix**:
```
Project A (Archived)
Project A (Rotated 2025-09-09) (Active)
```

### **Subsequent Rotations**:
```
Project A (Archived)
Project A (Rotated 2025-09-09) (Archived)  
Project A (Rotated 2025-09-10) (Active) ← Clean, readable name
```

## 🔍 How It Works

### **Base Name Extraction Examples**:
- `"Project A"` → `"Project A"` (no change)
- `"Project A (Rotated 2025-01-09)"` → `"Project A"`
- `"Project A (Rotated 2025-01-09) (Rotated 2025-01-10)"` → `"Project A"`
- `"My Work Identity (Rotated 2024-12-15)"` → `"My Work Identity"`

### **Regex Pattern Explanation**:
```regex
 \(Rotated \d{4}-\d{2}-\d{2}\)
```
- ` \(` - Literal space and opening parenthesis
- `Rotated ` - Literal "Rotated " text
- `\d{4}-\d{2}-\d{2}` - Date pattern (YYYY-MM-DD)
- `\)` - Literal closing parenthesis

This pattern matches and removes ALL rotation suffixes, no matter how many times the identity has been rotated.

## ✅ Benefits

1. **Clean Names**: Identity names remain readable and concise
2. **Consistent Format**: All rotated identities follow the same naming pattern
3. **UI Friendly**: Names fit properly in the interface
4. **Future Proof**: Can handle unlimited rotations without name explosion
5. **Backward Compatible**: Works with existing rotated identities

## 🧪 Test Cases

The fix handles these scenarios correctly:

| Input Name | Expected Output |
|------------|----------------|
| `"Project A"` | `"Project A (Rotated 2025-09-09)"` |
| `"Project A (Rotated 2025-01-01)"` | `"Project A (Rotated 2025-09-09)"` |
| `"Work (Rotated 2024-12-15) (Rotated 2025-01-01)"` | `"Work (Rotated 2025-09-09)"` |
| `"My Identity"` | `"My Identity (Rotated 2025-09-09)"` |

The naming is now clean, predictable, and user-friendly! 🎉
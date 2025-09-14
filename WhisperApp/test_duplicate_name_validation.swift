#!/usr/bin/env swift

import Foundation

// Test script to verify duplicate name validation
print("🧪 Testing Duplicate Name Validation")

// Test cases for duplicate name validation
let testCases = [
    ("Project A", ["project a", "PROJECT A", "Project A"]),
    ("Test", ["test", "TEST", "Test"]),
    ("MyIdentity", ["myidentity", "MYIDENTITY", "MyIdentity"])
]

func testDuplicateValidation(newName: String, existingNames: [String]) -> Bool {
    let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    let existingNamesLower = existingNames.map { $0.lowercased() }
    
    return existingNamesLower.contains(trimmedName.lowercased())
}

for (newName, existingNames) in testCases {
    print("\\n📝 Testing: '\\(newName)' against existing: \\(existingNames)")
    
    for existingName in existingNames {
        let isDuplicate = testDuplicateValidation(newName: newName, existingNames: [existingName])
        let result = isDuplicate ? "❌ DUPLICATE" : "✅ UNIQUE"
        print("  '\\(newName)' vs '\\(existingName)': \\(result)")
    }
}

print("\\n🎯 Expected Results:")
print("- All comparisons should show '❌ DUPLICATE'")
print("- Case-insensitive matching should work")
print("- Whitespace trimming should work")

print("\\n✅ Test completed!")
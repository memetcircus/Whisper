# Duplicate ContactPickerViewModel Fix

## 🚨 Build Error Fixed

**Error**: Invalid redeclaration of 'ContactPickerViewModel' at line 243

**Root Cause**: There were two `ContactPickerViewModel` class declarations in different files:
1. `WhisperApp/UI/Compose/ComposeViewModel.swift` (line 314) - duplicate with MockContactManager
2. `WhisperApp/UI/Contacts/ContactListViewModel.swift` (line 243) - proper implementation with real ContactManager

## 🔧 Solution

Removed the duplicate `ContactPickerViewModel` class from `ComposeViewModel.swift` and kept the proper implementation in `ContactListViewModel.swift`.

**Removed duplicate from ComposeViewModel.swift**:
```swift
// ❌ REMOVED - This was the duplicate causing the build error
@MainActor
class ContactPickerViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    private let contactManager: ContactManager
    init(contactManager: ContactManager = MockContactManager()) {
        self.contactManager = contactManager
    }
    func loadContacts() {
        contacts = contactManager.listContacts().filter { !$0.isBlocked }
    }
}
```

**Kept the working version in ContactListViewModel.swift that includes**:
- ✅ Real contact data integration (no mock data)
- ✅ Contact filtering (removes blocked contacts)
- ✅ Alphabetical sorting
- ✅ Async loading with proper error handling
- ✅ @MainActor for UI updates
- ✅ Uses SharedContactManager.shared for real data

## ✅ Result

- ✅ Build error resolved
- ✅ Single, working ContactPickerViewModel class
- ✅ No more dummy contacts in compose message contact picker
- ✅ Clean, production-ready contact selection

The ContactPickerViewModel now works properly without duplicate declarations!
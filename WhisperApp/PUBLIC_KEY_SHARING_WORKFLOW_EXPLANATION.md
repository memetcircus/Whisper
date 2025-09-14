# Public Key Sharing Workflow - Complete Explanation

## The Two Different Export/Import Functions

### 1. Contact Export/Import (JSON)
**Purpose**: Manage your contact list
- **Export**: Save all your contacts to a JSON file
- **Import**: Load contacts from another Whisper instance
- **Use Cases**:
  - Backup your contacts
  - Transfer contacts to a new device
  - Share contact lists between team members

**Workflow Example:**
```
Alice's Phone → Export Contacts → contacts.json → Bob's Phone → Import Contacts
Result: Bob now has all of Alice's contacts in his app
```

### 2. Identity Public Key Export (.wpub)
**Purpose**: Share YOUR identity with others
- **Export**: Create a file containing YOUR public key
- **Import**: NOT done in the same app - others import YOUR key
- **Use Cases**:
  - Give your public key to someone new
  - Share your identity via email, messaging, etc.
  - Alternative to QR code sharing

**Workflow Example:**
```
Alice's Phone → Export Identity → alice-identity.wpub → Send to Bob → Bob imports as new contact
Result: Bob can now send encrypted messages to Alice
```

## Why No "Import Public Key Bundle" Feature?

You don't import `.wpub` files into your own app because:

1. **They contain someone else's public key**, not yours
2. **You already have your own private keys** in your keychain
3. **The recipient imports it as a contact**, not as an identity

## Current Implementation Analysis

Looking at the current app, I can see:

### ✅ What's Implemented:
- Contact export (JSON) ✅
- Contact import (JSON) ✅  
- Identity public key export (.wpub) ✅

### ❓ What's Missing:
- **Public key bundle import** - to add contacts from `.wpub` files

## The Missing Piece: Import Public Key Bundle

Currently, users can only add contacts via:
- QR code scanning
- Manual key entry

But they **cannot** import `.wpub` files that others have shared with them.

## Should We Add Public Key Bundle Import?

**YES!** This would complete the sharing workflow:

### Current Workflow (Incomplete):
1. Alice exports her identity → `alice-identity.wpub`
2. Alice sends file to Bob
3. Bob receives file but **cannot import it** ❌
4. Bob has to ask Alice to show QR code instead

### Complete Workflow (What we should have):
1. Alice exports her identity → `alice-identity.wpub`
2. Alice sends file to Bob  
3. Bob imports the `.wpub` file → Alice added as contact ✅
4. Bob can now send encrypted messages to Alice

## Implementation Needed

We should add:

```swift
// In ExportImportView
Section("Public Key Bundles") {
    Button("Export Identity Public Keys") {
        showingIdentityExport = true
    }
    
    // NEW: Import public key bundle
    Button("Import Public Key Bundle") {
        showingPublicKeyImport = true
    }
    
    Text("Export your public keys for sharing, or import someone else's public key bundle to add them as a contact.")
}
```

```swift
// In ExportImportViewModel
func importPublicKeyBundle(data: Data) {
    do {
        let publicBundle = try PublicKeyBundle.decode(from: data)
        let contact = Contact(from: publicBundle)
        try contactManager.addContact(contact)
        successMessage = "Successfully added \(contact.displayName) as a contact"
    } catch {
        errorMessage = "Failed to import public key bundle: \(error.localizedDescription)"
    }
}
```

## File Type Associations

The app should handle:
- `.json` files → Contact list import
- `.wpub` files → Public key bundle import (add as contact)

## Security Considerations

When importing `.wpub` files:
- Validate the public key format
- Check for duplicate contacts
- Set trust level to "unverified" initially
- Require user verification (SAS words) before marking as verified

## User Experience

With this feature, users could:
1. **Share via email**: "Here's my Whisper public key" (attach .wpub file)
2. **Share via messaging**: Send .wpub file through any messaging app
3. **Share via cloud storage**: Put .wpub file in shared folder
4. **Import easily**: Tap file in Files app → "Open with Whisper" → Contact added

This would make Whisper much more user-friendly for onboarding new contacts without requiring in-person QR code scanning.
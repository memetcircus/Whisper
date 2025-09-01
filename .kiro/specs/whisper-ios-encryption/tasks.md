# Implementation Plan

- [x] 1. Set up project structure and security foundation
  - Create iOS project with proper entitlements and build configuration
  - Implement build-time networking detection test that fails if URLSession, Network, or socket symbols are present
  - Set up Core Data model with Identity, Contact, and ReplayProtection entities
  - Configure Keychain access with proper security attributes
  - _Requirements: 8.1, 8.4, 4.1, 8.2_

- [x] 2. Implement core cryptographic engine
  - Create CryptoEngine protocol and implementation using CryptoKit exclusively
  - Implement X25519 key agreement with ECDH and HKDF-SHA256 key derivation using separate labels ("key", "nonce")
  - Include ephemeral public key (epk) and message ID (msgid) in HKDF input for context binding
  - Add ChaCha20-Poly1305 AEAD encryption/decryption with proper AAD handling
  - Implement Ed25519 signing and verification for optional message authentication
  - Add secure random number generation and ephemeral key zeroization
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 7.1_

- [x] 3. Create envelope processing system
  - Implement EnvelopeProcessor with whisper1: format parsing and generation
  - Add canonical context binding with deterministic CBOR/length-prefixed encoding
  - Implement recipient key ID (rkid) generation using BLAKE2s or SHA-256 fallback
  - Add strict algorithm validation that only accepts v1.c20p and rejects all others
  - Implement Base64URL encoding/decoding for envelope fields
  - Add error handling with generic user-facing messages ("Invalid envelope") and detailed errors only in debug builds
  - _Requirements: 2.1, 2.2, 2.3, 2.6, 7.5, 7.3_

- [ ] 4. Implement message padding and length hiding
  - Create MessagePadding utility with bucket-based padding (256/512/1024 bytes)
  - Implement padding format: len(2-byte big-endian) | msg | pad(0x00)
  - Add constant-time comparison for padding validation during decryption to prevent timing attacks
  - Create unit tests for padding round-trip and invalid padding rejection with timing analysis
  - _Requirements: 10.1, 10.2, 10.4_

- [ ] 5. Build identity management system
  - Create Identity model with X25519/Ed25519 key pairs, metadata, and expiration tracking
  - Implement IdentityManager with create, list, activate, archive, and rotate operations
  - Add Keychain integration for private key storage with kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
  - Implement identity export/import with public key bundles
  - Add auto-archive functionality for key rotation policy
  - Create identity expiration warning UI for approaching key rotation deadlines
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 8.2_

- [ ] 6. Create contact management system
  - Implement Contact model with fingerprint, shortID (Base32), and SAS words
  - Create ContactManager with add, verify, block, and key rotation handling
  - Add trust level management (unverified, verified, revoked) with proper state transitions
  - Implement local database storage using Core Data (no iOS Contacts access)
  - Add contact search and public keybook export functionality
  - Implement "Key changed — re-verify" banner display when contact key rotation is detected
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [ ] 7. Implement security policy engine
  - Create PolicyManager with four configurable policies (contact-required, signature-required, auto-archive, biometric-gated)
  - Add policy validation for send operations with appropriate error throwing
  - Implement Contact-Required-to-Send enforcement where encryptToRawKey throws policyViolation(.rawKeyBlocked)
  - Add Require-Signature-for-Verified policy that mandates signatures for verified contacts
  - Create policy persistence storage using UserDefaults or Core Data for configuration management
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 8.7_

- [ ] 8. Build biometric authentication system
  - Create BiometricService with enrollSigningKey and sign(data:keyId:) methods (no raw key exposure)
  - Implement Keychain storage with kSecAttrAccessControl requiring biometryCurrentSet
  - Add Face ID/Touch ID authentication flow with proper error handling
  - Implement biometric policy enforcement for signing operations
  - Add graceful cancellation handling that returns policyViolation(.biometricRequired) when user cancels
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 8.3_

- [ ] 9. Create replay protection system
  - Implement ReplayProtector with atomic checkAndCommit operation that verifies uniqueness and commits in one step
  - Add freshness window validation (±48 hours) with timestamp checking
  - Create replay cache with 30-day retention and 10,000 entry limit
  - Implement periodic cleanup of expired entries with background task scheduling
  - Add Core Data integration for persistent replay protection storage
  - _Requirements: 7.2, 7.3, 7.4_

- [ ] 10. Build high-level encryption service
  - Create WhisperService with encrypt/decrypt methods and contact/raw key support
  - Implement signature attribution logic: Verified contacts show "From: Name (Verified, Signed)", Unverified show "From: Name (Unverified, Signed)", Unknown signers show "From: Unknown (Signed)"
  - Add "not-for-me" detection when rkid doesn't match any identity
  - Integrate all components: crypto, envelope, identity, contact, policy, biometric, replay
  - Add comprehensive error handling with generic user-facing messages
  - _Requirements: 9.3, 9.4, 9.5, 9.6, 7.3_

- [ ] 11. Implement message composition UI
  - Create compose view with active identity selection and contact picker
  - Add policy enforcement in UI (disable raw key option when contact-required is enabled)
  - Implement encryption flow with biometric authentication when required
  - Add iOS share sheet integration for encrypted message sharing
  - Create clipboard copy functionality with user feedback
  - _Requirements: 9.2, 5.1, 6.2, 11.1_

- [ ] 12. Build message decryption UI
  - Create decrypt banner that detects whisper1: prefixes in clipboard/share
  - Implement decryption flow with sender attribution display
  - Add replay detection and freshness validation with appropriate error messages
  - Create decrypted message display with sender trust status
  - Add error handling for invalid envelopes and policy violations
  - _Requirements: 9.1, 9.3, 7.2, 7.3_

- [ ] 13. Create contact management UI
  - Build contact list with trust badges (Verified, Unverified, Revoked, Blocked)
  - Implement add contact flow with QR scanning and manual entry
  - Create contact verification UI with fingerprint, shortID, and SAS word display
  - Add key rotation detection with re-verification prompts
  - Implement contact blocking/unblocking functionality
  - _Requirements: 4.3, 4.4, 4.5, 11.1, 11.2_

- [ ] 14. Build QR code integration
  - Implement QR code generation for public key bundles and encrypted messages
  - Add QR scanning functionality with format validation
  - Enforce QR size warning when envelope exceeds ~900 bytes maximum for reliable scanning
  - Implement contact preview before adding from scanned QR
  - Add proper error correction level M for QR code generation
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ] 15. Create settings and policy UI
  - Build settings screen with toggles for all four security policies
  - Add identity management UI (create, switch, archive, rotate, backup/restore)
  - Implement legal disclaimer screen with required acceptance on first launch
  - Create biometric settings with enrollment/unenrollment options
  - Add export/import functionality for identities and contacts
  - _Requirements: 9.4, 9.5, 3.6, 6.1_

- [ ] 16. Implement comprehensive security testing
  - Create unit tests for all cryptographic operations with test vectors
  - Add determinism test verifying same plaintext twice produces different envelopes due to random epk/salt/msgid
  - Implement nonce uniqueness soak test with 1M iterations to detect collisions
  - Create constant-time operation tests to detect timing leakage in padding validation
  - Add algorithm lock tests ensuring only v1.c20p is accepted
  - _Requirements: 12.3, 12.4, 12.5, 12.6_

- [ ] 17. Build integration and end-to-end tests
  - Create full encrypt/decrypt cycle tests with multiple identities
  - Add cross-identity communication tests
  - Implement policy matrix tests covering all 16 combinations of 4 policies (contact-required × signature-required × auto-archive × biometric-gated)
  - Create biometric authentication mock tests
  - Add replay protection and freshness validation tests
  - _Requirements: 7.2, 5.5, 6.4, 12.6_

- [ ] 18. Implement accessibility and localization
  - Add VoiceOver labels and hints for all UI elements including trust badges with accessible text alternatives
  - Implement Dynamic Type support for text scaling
  - Create localization files with all required string keys (sign.*, policy.*, contact.*, identity.*, encrypt.*, decrypt.*, qr.*, legal.*)
  - Add accessibility tests for color contrast and touch targets
  - Implement localization validation tests ensuring all keys resolve
  - _Requirements: 12.1, 12.2, 12.6_

- [ ] 19. Add performance optimization and monitoring
  - Implement lazy loading for identities and contacts
  - Add background processing for cryptographic operations
  - Create memory efficiency optimizations for crypto operations
  - Add performance benchmarks for encryption/decryption speed
  - Implement memory usage monitoring during operations
  - _Requirements: Performance considerations from design_

- [ ] 20. Final integration and validation
  - Integrate all components and test complete user workflows
  - Validate all security requirements with comprehensive test suite
  - Add build-time guard that fails compilation if networking APIs (URLSession, Network, sockets) are detected
  - Verify legal disclaimer acceptance requirement on first launch
  - Add final build configuration with Release/Debug variants
  - Create App Store compliance documentation (privacy labels, export compliance)
  - _Requirements: All requirements validation, 8.1, 9.5_
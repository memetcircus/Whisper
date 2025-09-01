# Requirements Document

## Introduction

Whisper is a fully client-side encryption/decryption iOS application (iOS 15+) that provides end-to-end encryption for messages shared over WhatsApp or any messaging platform. The app operates entirely offline with no networking capabilities, using only local storage and the device's Keychain for security. Messages are encrypted and shared as text or QR codes using the "whisper1:" envelope scheme.

## Requirements

### Requirement 1: Core Encryption System

**User Story:** As a user, I want to encrypt messages locally on my device so that I can share secure communications through any messaging platform without relying on external servers.

#### Acceptance Criteria

1. WHEN a user encrypts a message THEN the system SHALL use CryptoKit exclusively for all cryptographic operations
2. WHEN generating encryption keys THEN the system SHALL create fresh randomness and ephemeral X25519 keys for every message
3. WHEN performing key agreement THEN the system SHALL use X25519 ECDH followed by HKDF-SHA256 with 16-byte salt and info="whisper-v1"
4. WHEN deriving encryption materials THEN the system SHALL generate separate encKey(32) and nonce(12) using distinct HKDF labels ("key", "nonce")
5. WHEN encrypting plaintext THEN the system SHALL use ChaCha20-Poly1305 AEAD with AAD equal to canonical header
6. WHEN handling ephemeral keys THEN the system SHALL zeroize ephemeral private keys immediately after use

### Requirement 2: Envelope Format and Protocol

**User Story:** As a user, I want my encrypted messages to use a standardized format so that they can be reliably shared and decrypted across different instances of the app.

#### Acceptance Criteria

1. WHEN creating an envelope THEN the system SHALL use the format: whisper1:v1.c20p.<rkid>.<flags>.<epk>.<salt>.<msgid>.<ts>.<ct>[.sig]
2. WHEN encoding envelope fields THEN the system SHALL use Base64URL encoding without padding for each field
3. WHEN generating recipient key ID THEN the system SHALL use the lower 8 bytes of BLAKE2s hash of recipient X25519 public key, OR if BLAKE2s is unavailable in CryptoKit, fall back to SHA-256 and take the lower 8 bytes
4. WHEN setting flags THEN the system SHALL set bit0 to indicate signature presence
5. WHEN including timestamp THEN the system SHALL use Unix seconds for freshness validation within ±48 hour window
6. WHEN processing envelopes THEN the system SHALL only accept v1.c20p algorithm with strict algorithm lock and reject any downgrade attempts or crypto agility

### Requirement 3: Multiple Identity Management

**User Story:** As a user, I want to manage multiple cryptographic identities so that I can use different identities for different contexts or rotate keys for security.

#### Acceptance Criteria

1. WHEN creating an identity THEN the system SHALL generate X25519 keys for key agreement and optionally Ed25519 keys for signing
2. WHEN switching identities THEN the system SHALL allow users to select which identity to use for encryption
3. WHEN archiving an identity THEN the system SHALL make it decrypt-only while preventing new message encryption
4. WHEN rotating keys THEN the system SHALL create a new identity and optionally auto-archive the previous one based on policy
5. WHEN decrypting messages THEN the system SHALL auto-select the correct identity using the recipient key ID (rkid)
6. WHEN exporting identities THEN the system SHALL allow export of public key bundles and optional passphrase-protected backups

### Requirement 4: Trusted Contacts Management

**User Story:** As a user, I want to maintain a local address book of trusted contacts so that I can verify message authenticity and manage trust relationships without accessing system contacts.

#### Acceptance Criteria

1. WHEN storing contact data THEN the system SHALL use local database (Core Data/SQLite) and NOT access iOS Contacts
2. WHEN adding a contact THEN the system SHALL store UUID, displayName, x25519Pub, optional ed25519Pub, fingerprint, rkid, trust level, and metadata
3. WHEN verifying a contact THEN the system SHALL support trust levels: unverified, verified, and revoked
4. WHEN displaying contacts THEN the system SHALL show fingerprint (lower 32 bytes of hash), shortID (Base32 Crockford 12 chars), and SAS (6-word sequence) for verification
5. WHEN detecting key rotation THEN the system SHALL notify users of key changes and prompt for re-verification
6. WHEN managing contacts THEN the system SHALL support blocking/unblocking and export of public keybook

### Requirement 5: Security Policies

**User Story:** As a user, I want configurable security policies so that I can enforce security requirements based on my threat model and usage patterns.

#### Acceptance Criteria

1. WHEN Contact-Required policy is enabled THEN the system SHALL block sending to raw keys and require recipient selection from contacts
2. WHEN Require-Signature-for-Verified policy is enabled THEN the system SHALL mandate signatures for all messages to verified contacts
3. WHEN Auto-Archive-on-Rotation policy is enabled THEN the system SHALL automatically archive old identities after key rotation
4. WHEN Biometric-Gated-Signing policy is enabled THEN the system SHALL require Face ID/Touch ID for every signature operation
5. WHEN policies are violated THEN the system SHALL prevent message sending and display appropriate error messages

### Requirement 6: Biometric Authentication

**User Story:** As a user, I want biometric protection for signing operations so that my signing keys cannot be used without my physical presence.

#### Acceptance Criteria

1. WHEN biometric gating is enabled THEN the system SHALL store Ed25519 private keys with Keychain access control requiring user presence
2. WHEN signature is required THEN the system SHALL show pre-prompt and trigger iOS Face ID/Touch ID authentication
3. WHEN biometric authentication is cancelled THEN the system SHALL abort the send operation and display cancellation message
4. WHEN biometric authentication fails THEN the system SHALL display failure message and allow retry
5. WHEN biometric policy is disabled THEN the system SHALL allow signatures without biometric verification

### Requirement 7: Security Hardening

**User Story:** As a user, I want comprehensive security protections so that the app is resistant to various attack vectors and implementation vulnerabilities.

#### Acceptance Criteria

1. WHEN deriving keys THEN the system SHALL use separate HKDF labels and include ephemeral public key and message ID in KDF input
2. WHEN processing messages THEN the system SHALL enforce freshness window of ±48 hours using timestamp and maintain replay cache for 30 days (max 10k entries)
3. WHEN checking replay protection THEN the system SHALL use atomic checkAndCommit operation that verifies uniqueness and commits in one step
4. WHEN message is expired THEN the system SHALL NOT commit entry to replay cache
3. WHEN errors occur THEN the system SHALL display only generic user-facing messages ("Invalid envelope", "Replay detected", "Message expired", "Signature cancelled") with detailed errors only in debug logs
4. WHEN handling sensitive data THEN the system SHALL scrub ephemeral keys and buffers from memory
5. WHEN binding context THEN the system SHALL build AAD and HKDF info from canonical byte structure encoding {app_id="whisper", version="v1", sender_fingerprint(32), recipient_fingerprint(32), policy_flags(UInt32), rkid(8), epk(32), salt(16), msgid(16), ts(Int64)} using deterministic format (CBOR or length-prefixed)
6. WHEN processing envelopes THEN the system SHALL reconstruct and verify this context exactly

### Requirement 8: Network Isolation

**User Story:** As a user, I want complete assurance that no data leaves my device so that my communications remain private and cannot be intercepted or analyzed by third parties.

#### Acceptance Criteria

1. WHEN building the app THEN the system SHALL include unit tests that fail if networking symbols (URLSession, Network, sockets) are present
2. WHEN storing private keys THEN the system SHALL use Keychain with kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly attribute
3. WHEN storing biometric-protected keys THEN the system SHALL use kSecAttrAccessControl with biometryCurrentSet or userPresence
3. WHEN storing public data THEN the system SHALL use only local database storage
4. WHEN operating THEN the system SHALL NOT include analytics, crash reporters, remote configuration, or any network communication
5. WHEN generating randomness THEN the system SHALL use only CryptoKit secure RNG and SecRandomCopyBytes with no custom RNG implementations
6. WHEN logging THEN the system SHALL use local-only logs that are disabled in Release builds
7. WHEN encrypting to raw key THEN the system SHALL throw policyViolation(.rawKeyBlocked) if Contact-Required-to-Send policy is enabled

### Requirement 9: User Interface and Experience

**User Story:** As a user, I want an intuitive interface for encryption/decryption operations so that I can easily secure my communications without technical complexity.

#### Acceptance Criteria

1. WHEN detecting encrypted content THEN the system SHALL recognize whisper1: prefixes in clipboard/share and show decrypt banner
2. WHEN composing messages THEN the system SHALL provide identity selection, contact picker (policy-enforced), encryption, and sharing via iOS share sheet
3. WHEN decrypting messages THEN the system SHALL display sender attribution (Verified/Signed/Unknown) and enforce freshness/replay checks
4. WHEN recipient key ID does not match any identity THEN the system SHALL abort decryption with message "This message is not addressed to you"
5. WHEN signature is valid and matches contact THEN the system SHALL show "From: <Name> (Verified/Signed | Unverified/Signed)"
6. WHEN signature is valid but sender unknown THEN the system SHALL show "From: Unknown (Signed)"
7. WHEN Require-Signature-for-Verified policy is enabled and recipient is Verified THEN encrypt operation SHALL require signature or throw policyViolation(.signatureRequired)
4. WHEN accessing settings THEN the system SHALL provide toggles for all four security policies
5. WHEN first launching THEN the system SHALL require acceptance of legal disclaimers before app usage

### Requirement 10: Message Padding and Length Hiding

**User Story:** As a user, I want my message lengths to be hidden so that traffic analysis cannot reveal information about my communication patterns.

#### Acceptance Criteria

1. WHEN encrypting plaintext THEN the system SHALL pad messages using format: len(2-byte big-endian) | msg | pad(0x00) up to nearest bucket (256/512/1024 bytes)
2. WHEN decrypting messages THEN the system SHALL verify AEAD, then perform constant-time check of length/padding and reject on mismatch
3. WHEN processing padded content THEN the system SHALL ensure padding does not reveal original message length
4. WHEN validating padding THEN the system SHALL use constant-time comparison to prevent timing attacks

### Requirement 11: QR Code and Sharing Integration

**User Story:** As a user, I want to share encrypted messages and public keys via QR codes so that I can easily exchange secure information in person or through visual channels.

#### Acceptance Criteria

1. WHEN sharing public keys THEN the system SHALL generate QR codes containing public key bundles
2. WHEN scanning QR codes THEN the system SHALL parse and preview contact information before adding
3. WHEN sharing encrypted messages THEN the system SHALL support both text sharing and QR code generation with warnings if envelope exceeds safe QR size (400-900 bytes for QR version 11-15 with M error correction)
4. WHEN displaying QR codes THEN the system SHALL ensure readability and include appropriate error correction
5. WHEN processing scanned data THEN the system SHALL validate format and content before accepting

### Requirement 12: Localization and Accessibility

**User Story:** As a user, I want proper localization and accessibility support so that the app is usable regardless of my language preferences or accessibility needs.

#### Acceptance Criteria

1. WHEN displaying text THEN the system SHALL use localized strings with updated "Whisper" branding (replacing "Kiro Whisper")
2. WHEN building the app THEN the system SHALL include tests verifying all string keys resolve properly
3. WHEN testing determinism THEN the system SHALL verify same plaintext twice yields different envelopes due to random epk/salt/msgid
4. WHEN testing nonce uniqueness THEN the system SHALL perform soak test with 1M iterations
5. WHEN testing constant-time operations THEN the system SHALL verify no timing leakage
6. WHEN testing policies THEN the system SHALL cover all 16 combinations of 4 policies
3. WHEN providing UI elements THEN the system SHALL include appropriate accessibility labels and hints
4. WHEN displaying trust badges THEN the system SHALL provide accessible descriptions of trust status
5. WHEN showing interactive elements THEN the system SHALL ensure proper VoiceOver and accessibility support
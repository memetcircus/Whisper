# Signature Control Consolidation Requirements

## Introduction

Currently, the WhisperApp has two separate controls for the same cryptographic signature feature:
1. "Include Signature" toggle in Compose Message screen (per-message control)
2. "Require Signature for Verified" toggle in Settings (policy control)

This creates user confusion and inconsistent behavior. This feature consolidates signature control into a single, clear Settings-based approach that eliminates per-message decisions and provides consistent security behavior.

## Requirements

### Requirement 1: Remove Per-Message Signature Control

**User Story:** As a user, I want signature inclusion to be controlled by my Settings preferences rather than making decisions for each message, so that I have consistent security behavior without decision fatigue.

#### Acceptance Criteria

1. WHEN I open the Compose Message screen THEN I SHALL NOT see an "Include Signature" toggle
2. WHEN I compose a message THEN signatures SHALL be automatically included based on my Settings preferences
3. WHEN I send a message THEN the signature inclusion SHALL be determined by Settings policies without requiring per-message input

### Requirement 2: Single Settings-Based Signature Control

**User Story:** As a user, I want to control signature behavior through a single, clear Settings option, so that I can set my security preference once and have it consistently applied to all messages.

#### Acceptance Criteria

1. WHEN I open Settings THEN I SHALL see a "Message Security" section with signature control
2. WHEN I view Message Security THEN I SHALL see an "Always Include Signatures" toggle with default value ON
3. WHEN "Always Include Signatures" is ON THEN all messages SHALL include cryptographic signatures for all recipients
4. WHEN "Always Include Signatures" is OFF THEN messages SHALL be sent without signatures (anonymous mode)
5. WHEN I change the "Always Include Signatures" setting THEN it SHALL apply to all future messages regardless of recipient type

### Requirement 3: Simple and Clear Behavior

**User Story:** As a user, I want signature behavior to be straightforward and predictable, so that I always know whether my messages will include signatures.

#### Acceptance Criteria

1. WHEN I view the "Always Include Signatures" setting THEN the behavior SHALL be binary and clear (ON = all messages signed, OFF = no messages signed)
2. WHEN I view Settings THEN the help text SHALL clearly explain that this controls cryptographic signatures for message authenticity
3. WHEN the setting is changed THEN the new behavior SHALL apply immediately to all future messages
4. WHEN I compose messages THEN signature inclusion SHALL be determined solely by this one Settings preference

### Requirement 4: Security-First Defaults

**User Story:** As a security-conscious user, I want the app to default to secure options, so that I'm protected even if I don't customize settings.

#### Acceptance Criteria

1. WHEN the app is first installed THEN "Always Include Signatures" SHALL default to ON (enabled)
2. WHEN a user upgrades from a previous version THEN existing signature preferences SHALL be migrated to the new unified system
3. WHEN no explicit signature preference is set THEN the system SHALL default to including signatures (secure by default)

### Requirement 5: Compose UI Simplification

**User Story:** As a user, I want the Compose Message screen to be clean and focused on message content, so that I can efficiently compose messages without security decision overhead.

#### Acceptance Criteria

1. WHEN I open Compose Message THEN the interface SHALL NOT display signature-related toggles or controls
2. WHEN I compose a message THEN the UI SHALL focus on message content, recipient selection, and identity selection only
3. WHEN I send a message THEN any signature-related feedback SHALL be minimal and non-intrusive
4. WHEN I need to change signature behavior THEN I SHALL be directed to Settings rather than having per-message controls

### Requirement 6: Backward Compatibility

**User Story:** As an existing user, I want my current signature preferences to be preserved when the app updates, so that my security configuration remains intact.

#### Acceptance Criteria

1. WHEN I upgrade to the new version THEN my existing signature preferences SHALL be migrated to the new "Always Include Signatures" setting
2. WHEN I previously had "Require Signature for Verified" enabled THEN "Always Include Signatures" SHALL be set to ON to maintain security
3. WHEN the migration occurs THEN I SHALL NOT lose any security protections I previously had configured
4. WHEN the upgrade completes THEN the old "Require Signature for Verified" setting SHALL be removed from the UI

## Success Criteria

- Users no longer see signature controls in Compose Message screen
- All signature behavior is controlled through Settings with clear hierarchy
- Default configuration provides strong security (signatures enabled)
- Existing users maintain their security preferences through migration
- Settings UI clearly explains signature policy interactions
- Compose UI is simplified and focused on message creation
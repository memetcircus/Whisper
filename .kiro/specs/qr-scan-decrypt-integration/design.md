# Design Document

## Overview

This feature integrates QR code scanning capability into the existing decrypt message workflow. The design leverages the existing QR code infrastructure (QRCodeService, QRScannerView, QRCodeCoordinatorView) and extends the DecryptView to include a QR scan button that opens the camera scanner. When a valid encrypted message QR code is scanned, it automatically populates the decrypt input field.

The design maintains consistency with the existing app patterns, particularly following the compose view's approach to QR code integration while adapting it for the decrypt workflow.

## Architecture

### Component Integration

The solution integrates three main components:

1. **DecryptView Enhancement**: Add QR scan button and integrate with existing QR coordinator
2. **QR Code Flow Integration**: Leverage existing QRCodeCoordinatorView for scanning workflow
3. **DecryptViewModel Extension**: Add methods to handle QR scan results and validation

### Data Flow

```
User taps QR scan button → DecryptView presents QRCodeCoordinatorView → 
Camera scans QR code → QRCodeService validates content → 
Encrypted message returned to DecryptView → Input field populated → 
User can proceed with normal decrypt flow
```

## Components and Interfaces

### DecryptView Changes

**New UI Elements:**
- QR scan button positioned prominently near the manual input section
- Button styling consistent with existing app design patterns
- Accessibility labels and hints integrated into button implementation

**New State Management:**
- `@State private var showingQRScanner: Bool = false`
- Sheet presentation for QR scanner
- Integration with existing error handling

**Button Placement Strategy:**
- Position QR scan button in the manual input section header
- Use HStack to place it alongside the "Encrypted Message" title
- Maintain visual balance with existing UI elements

### DecryptViewModel Extensions

**New Methods:**
```swift
func handleQRScanResult(_ envelope: String)
func validateQRContent(_ content: String) -> Bool
```

**Integration Points:**
- Reuse existing `isValidWhisperMessage(text:)` method for validation
- Leverage existing error handling infrastructure
- Maintain consistency with manual input validation

### QR Code Integration Pattern

**Reuse Existing Infrastructure:**
- QRCodeCoordinatorView for camera management and scanning flow
- QRCodeService for content parsing and validation
- Existing camera permission handling

**Adaptation for Decrypt Flow:**
- Filter QR scan results to only accept encrypted messages
- Reject public key bundle QR codes with appropriate error messages
- Provide clear feedback for unsupported QR code types

## Data Models

### QR Scan Result Handling

The existing `QRCodeContent` enum already supports encrypted messages:
```swift
enum QRCodeContent {
    case publicKeyBundle(PublicKeyBundle)
    case encryptedMessage(String)  // This is what we need
}
```

**Validation Logic:**
- Accept only `.encryptedMessage(String)` results
- Validate envelope format using existing WhisperService.detect() method
- Provide specific error messages for different failure types

### Error Handling Extensions

**New Error Cases:**
- QR code contains public key bundle (not encrypted message)
- QR code format unsupported
- Camera permission denied
- Scanning failed

**Integration with Existing Errors:**
- Reuse existing WhisperError types where applicable
- Extend DecryptView's error alert system to handle QR-specific errors
- Maintain consistent error presentation patterns

## Error Handling

### QR Scan Error Categories

1. **Camera Permission Errors**
   - Leverage existing QRCodeCoordinatorView permission handling
   - Show system permission prompt when needed
   - Provide fallback message for denied permissions

2. **QR Content Errors**
   - Invalid QR code format
   - QR code contains contact info instead of encrypted message
   - Corrupted or unreadable QR code data

3. **Integration Errors**
   - Scanner fails to initialize
   - Camera hardware unavailable
   - Unexpected scanning errors

### Error Presentation Strategy

- Use existing DecryptView error alert system
- Provide actionable error messages with retry options
- Maintain consistency with existing error handling patterns
- Include accessibility-friendly error descriptions

## Testing Strategy

### Unit Tests

**DecryptViewModel Tests:**
- Test QR scan result handling with valid encrypted messages
- Test rejection of invalid QR content (public key bundles, malformed data)
- Test integration with existing validation methods
- Test error handling for various QR scan failure scenarios

**QR Integration Tests:**
- Test QRCodeService parsing of encrypted message QR codes
- Test camera permission handling integration
- Test QR scanner presentation and dismissal

### UI Tests

**User Flow Tests:**
- Test complete QR scan to decrypt workflow
- Test QR scan button accessibility
- Test error handling user experience
- Test integration with existing decrypt functionality

**Edge Case Tests:**
- Test behavior when camera is unavailable
- Test handling of multiple QR codes in view
- Test cancellation of QR scan process
- Test QR scan with clipboard content already present

### Integration Tests

**End-to-End Workflow:**
- Generate QR code in compose view → Scan in decrypt view → Decrypt message
- Test with various message sizes and encryption parameters
- Test with different identity and contact combinations

## Implementation Considerations

### Performance

- Reuse existing QR code infrastructure to minimize performance impact
- Leverage existing camera session management
- Maintain responsive UI during scanning operations

### Accessibility

- QR scan button includes appropriate accessibility labels and hints (implemented in tasks 2 and 5)
- Error messages are accessible through existing error handling system
- Integration maintains existing accessibility patterns

### Platform Compatibility

- Ensure camera permission handling works across iOS versions
- Test QR scanning performance on various device types
- Maintain compatibility with existing app architecture

### Security Considerations

- Validate all QR scan input using existing security measures
- Ensure QR scanning doesn't bypass existing encryption validation
- Maintain audit trail for QR scan operations
- Protect against malicious QR code content
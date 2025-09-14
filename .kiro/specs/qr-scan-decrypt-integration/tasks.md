# Implementation Plan

- [x] 1. Extend DecryptViewModel with QR scan support
  - Add QR scan result handling method to DecryptViewModel
  - Implement QR content validation using existing WhisperService.detect() method
  - Add state management for QR scanner presentation
  - _Requirements: 1.3, 2.1_

- [x] 2. Add QR scan button to DecryptView UI
  - Add QR scan button in the manual input section header
  - Position button alongside "Encrypted Message" title using HStack
  - Apply consistent styling with existing app buttons
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 3. Implement QR scanner sheet presentation
  - Add @State variable for QR scanner presentation
  - Implement sheet modifier with QRCodeCoordinatorView
  - Configure QR coordinator callbacks for decrypt workflow
  - _Requirements: 1.2, 2.3_

- [x] 4. Handle QR scan results and validation
  - Implement callback to receive scanned QR content
  - Filter results to accept only encrypted messages
  - Reject public key bundle QR codes with appropriate errors
  - Populate input field with valid encrypted message content
  - _Requirements: 1.3, 1.4, 2.1_

- [x] 5. Integrate QR scan error handling
  - Extend existing error alert system to handle QR-specific errors
  - Add error cases for unsupported QR content types
  - Implement camera permission error handling
  - Provide retry options for recoverable errors
  - _Requirements: 1.4, 1.5, 2.4_

- [x] 6. Implement visual feedback for QR scanning
  - Ensure proper button state management during scanning
  - Integrate with existing loading states and indicators
  - Provide clear visual confirmation when scan completes
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 7. Write unit tests for QR scan integration
  - Test DecryptViewModel QR scan result handling
  - Test validation of encrypted message QR content
  - Test rejection of invalid QR content types
  - Test error handling for various scan failure scenarios
  - _Requirements: 1.3, 1.4, 2.1_

- [x] 8. Write UI tests for QR scan workflow
  - Test complete QR scan to decrypt user flow
  - Test QR scan button accessibility and interaction
  - Test error handling user experience
  - Test integration with existing decrypt functionality
  - _Requirements: 1.1, 1.2, 2.2, 2.3_

- [ ] 9. Test end-to-end QR workflow integration
  - Test generating QR code in compose view and scanning in decrypt view
  - Verify encrypted message QR codes work correctly
  - Test with various message sizes and encryption parameters
  - Validate complete encrypt → QR → scan → decrypt workflow
  - _Requirements: 1.1, 1.3, 2.1, 2.2_
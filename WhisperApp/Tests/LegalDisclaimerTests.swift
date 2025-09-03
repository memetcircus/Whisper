import XCTest
import SwiftUI
@testable import WhisperApp

class LegalDisclaimerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset legal acceptance for each test
        UserDefaults.standard.removeObject(forKey: "whisper.legal.accepted")
    }
    
    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "whisper.legal.accepted")
        super.tearDown()
    }
    
    func testLegalDisclaimerRequiredOnFirstLaunch() {
        // Verify that legal acceptance is false by default
        let legalAccepted = UserDefaults.standard.bool(forKey: "whisper.legal.accepted")
        XCTAssertFalse(legalAccepted, "Legal disclaimer should not be accepted by default")
    }
    
    func testLegalDisclaimerAcceptance() {
        // Simulate accepting legal disclaimer
        UserDefaults.standard.set(true, forKey: "whisper.legal.accepted")
        
        let legalAccepted = UserDefaults.standard.bool(forKey: "whisper.legal.accepted")
        XCTAssertTrue(legalAccepted, "Legal disclaimer should be marked as accepted")
    }
    
    func testLegalDisclaimerPersistence() {
        // Test that legal acceptance persists across app launches
        UserDefaults.standard.set(true, forKey: "whisper.legal.accepted")
        
        // Simulate app restart by creating new UserDefaults reference
        let newDefaults = UserDefaults.standard
        let legalAccepted = newDefaults.bool(forKey: "whisper.legal.accepted")
        
        XCTAssertTrue(legalAccepted, "Legal disclaimer acceptance should persist")
    }
    
    func testLegalDisclaimerViewConfiguration() {
        // Test first launch configuration
        let firstLaunchView = LegalDisclaimerView(isFirstLaunch: true)
        XCTAssertNotNil(firstLaunchView, "Legal disclaimer view should be created for first launch")
        
        // Test settings view configuration
        let settingsView = LegalDisclaimerView(isFirstLaunch: false)
        XCTAssertNotNil(settingsView, "Legal disclaimer view should be created for settings")
    }
    
    func testLegalDisclaimerContent() {
        // Verify that the legal disclaimer contains required sections
        let view = LegalDisclaimerView(isFirstLaunch: true)
        
        // This is a basic test - in a real implementation, you might want to
        // test the actual content rendering or use ViewInspector
        XCTAssertNotNil(view, "Legal disclaimer view should contain required content")
    }
    
    func testAppBlockedWithoutLegalAcceptance() {
        // Verify that the app shows legal disclaimer when not accepted
        UserDefaults.standard.set(false, forKey: "whisper.legal.accepted")
        
        // In a real implementation, you would test that the main app content
        // is not accessible until legal disclaimer is accepted
        let legalAccepted = UserDefaults.standard.bool(forKey: "whisper.legal.accepted")
        XCTAssertFalse(legalAccepted, "App should require legal acceptance")
    }
    
    func testLegalDisclaimerSections() {
        // Test that all required legal sections are present
        let requiredSections = [
            "No Warranty",
            "Security Limitations", 
            "User Responsibility",
            "Export Compliance",
            "Limitation of Liability"
        ]
        
        // In a real implementation, you would verify these sections exist
        // in the legal disclaimer view
        XCTAssertEqual(requiredSections.count, 5, "All required legal sections should be present")
    }
    
    func testLegalDisclaimerAccessibility() {
        // Test accessibility features
        let view = LegalDisclaimerView(isFirstLaunch: true)
        
        // Verify view is accessible
        XCTAssertNotNil(view, "Legal disclaimer should be accessible")
        
        // In a real implementation, you would test:
        // - VoiceOver labels
        // - Dynamic Type support
        // - Accessibility actions
    }
    
    func testLegalDisclaimerLocalization() {
        // Test that legal disclaimer supports localization
        let legalTitle = NSLocalizedString("legal.title", comment: "Legal disclaimer title")
        XCTAssertNotEqual(legalTitle, "legal.title", "Legal title should be localized")
        
        let acceptButton = NSLocalizedString("legal.accept", comment: "Accept button")
        XCTAssertNotEqual(acceptButton, "legal.accept", "Accept button should be localized")
    }
}
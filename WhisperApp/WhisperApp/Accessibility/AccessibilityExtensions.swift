import SwiftUI

// MARK: - View Extensions for Accessibility

extension View {
    /// Adds accessibility label and hint with localized strings
    func accessibilityLabeled(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    /// Adds accessibility support for trust badges
    func trustBadgeAccessibility(for trustLevel: TrustLevel) -> some View {
        let label: String
        let hint = LocalizationHelper.Accessibility.hintTrustBadge
        
        switch trustLevel {
        case .verified:
            label = LocalizationHelper.Accessibility.trustBadgeVerified()
        case .unverified:
            label = LocalizationHelper.Accessibility.trustBadgeUnverified()
        case .revoked:
            label = LocalizationHelper.Accessibility.trustBadgeRevoked()
        }
        
        return self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds accessibility support for contact rows
    func contactRowAccessibility(for contact: Contact) -> some View {
        let label = "\(contact.displayName), \(contact.trustLevel.displayName)"
        let hint = LocalizationHelper.Accessibility.hintContactRow
        
        return self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds accessibility support for policy toggles
    func policyToggleAccessibility(_ policyName: String) -> some View {
        let label = LocalizationHelper.Accessibility.policyToggle(policyName)
        let hint = LocalizationHelper.Accessibility.hintPolicyToggle
        
        return self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
    }
    
    /// Adds accessibility support for buttons with dynamic type
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .font(.body) // Supports Dynamic Type
    }
    
    /// Adds accessibility support for text inputs
    func accessibleTextInput(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .font(.body) // Supports Dynamic Type
    }
    
    /// Adds accessibility support for images with descriptions
    func accessibleImage(description: String) -> some View {
        self
            .accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
    }
    
    /// Groups related accessibility elements
    func accessibilityGrouped(label: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label ?? "")
    }
    
    /// Adds accessibility support for navigation elements
    func accessibleNavigation(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
            .font(.headline) // Supports Dynamic Type
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Returns a font that scales with Dynamic Type
    static func scaledFont(_ style: Font.TextStyle, size: CGFloat? = nil) -> Font {
        if let size = size {
            return .custom("System", size: size, relativeTo: style)
        } else {
            return .system(style)
        }
    }
    
    /// Custom font sizes that scale with Dynamic Type
    static let scaledCaption = Font.scaledFont(.caption)
    static let scaledCaption2 = Font.scaledFont(.caption2)
    static let scaledFootnote = Font.scaledFont(.footnote)
    static let scaledCallout = Font.scaledFont(.callout)
    static let scaledBody = Font.scaledFont(.body)
    static let scaledHeadline = Font.scaledFont(.headline)
    static let scaledSubheadline = Font.scaledFont(.subheadline)
    static let scaledTitle = Font.scaledFont(.title)
    static let scaledTitle2 = Font.scaledFont(.title2)
    static let scaledTitle3 = Font.scaledFont(.title3)
    static let scaledLargeTitle = Font.scaledFont(.largeTitle)
}

// MARK: - Color Accessibility

extension Color {
    /// High contrast colors for accessibility
    static let accessiblePrimary = Color.primary
    static let accessibleSecondary = Color.secondary
    static let accessibleSuccess = Color.green
    static let accessibleWarning = Color.orange
    static let accessibleError = Color.red
    static let accessibleInfo = Color.blue
    
    /// Background colors with proper contrast
    static let accessibleBackground = Color(.systemBackground)
    static let accessibleSecondaryBackground = Color(.secondarySystemBackground)
    static let accessibleTertiaryBackground = Color(.tertiarySystemBackground)
    
    /// Trust level colors with accessibility support
    static func trustLevelColor(for level: TrustLevel) -> Color {
        switch level {
        case .verified:
            return .accessibleSuccess
        case .unverified:
            return .accessibleWarning
        case .revoked:
            return .accessibleError
        }
    }
}

// MARK: - Accessibility Constants

struct AccessibilityConstants {
    /// Minimum touch target size for accessibility (44x44 points)
    static let minimumTouchTarget: CGFloat = 44
    
    /// Recommended spacing for accessibility
    static let accessibleSpacing: CGFloat = 8
    
    /// Minimum contrast ratios
    static let minimumContrastRatio: Double = 4.5
    static let enhancedContrastRatio: Double = 7.0
    
    /// Animation durations that respect accessibility settings
    static let accessibleAnimationDuration: Double = 0.25
    static let reducedMotionDuration: Double = 0.1
}

// MARK: - Accessibility Environment

extension EnvironmentValues {
    /// Custom environment value for accessibility mode
    var isAccessibilityMode: Bool {
        accessibilityReduceMotion || accessibilityReduceTransparency || accessibilityDifferentiateWithoutColor
    }
    
    /// Custom environment value for high contrast mode
    var isHighContrastMode: Bool {
        accessibilityDifferentiateWithoutColor
    }
}

// MARK: - Accessibility Modifiers

struct AccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

extension View {
    func accessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        modifier(AccessibilityModifier(label: label, hint: hint, traits: traits))
    }
}

// MARK: - Dynamic Type Modifier

struct DynamicTypeModifier: ViewModifier {
    let style: Font.TextStyle
    let maxSize: CGFloat?
    
    func body(content: Content) -> some View {
        content
            .font(.system(style))
            .dynamicTypeSize(...(maxSize.map { DynamicTypeSize.accessibility1 } ?? .accessibility5))
    }
}

extension View {
    func dynamicTypeSupport(_ style: Font.TextStyle, maxSize: CGFloat? = nil) -> some View {
        modifier(DynamicTypeModifier(style: style, maxSize: maxSize))
    }
}

// MARK: - Accessibility Testing Helpers

#if DEBUG
struct AccessibilityTestingView: View {
    var body: some View {
        VStack(spacing: AccessibilityConstants.accessibleSpacing) {
            Text("Accessibility Test View")
                .accessibleNavigation(label: "Test Header")
            
            Button("Test Button") { }
                .accessibleButton(label: "Test button", hint: "Double tap to test")
                .frame(minWidth: AccessibilityConstants.minimumTouchTarget,
                       minHeight: AccessibilityConstants.minimumTouchTarget)
            
            TextField("Test Input", text: .constant(""))
                .accessibleTextInput(label: "Test input field", hint: "Enter test text")
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .accessibleImage(description: "Success checkmark")
                    .foregroundColor(.accessibleSuccess)
                
                Text("Success message")
                    .dynamicTypeSupport(.body)
            }
            .accessibilityGrouped(label: "Success status")
        }
        .padding()
        .background(Color.accessibleBackground)
    }
}

struct AccessibilityTestingView_Previews: PreviewProvider {
    static var previews: some View {
        AccessibilityTestingView()
            .previewDisplayName("Accessibility Test")
    }
}
#endif
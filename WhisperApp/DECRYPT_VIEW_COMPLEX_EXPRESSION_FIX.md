# DecryptView Complex Expression Build Fix

## Issue
The Swift compiler was unable to type-check the complex VStack expression in the `composeStyleMessageView` method within reasonable time, causing a build error:

```
The compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions
```

## Root Cause
The `composeStyleMessageView` method contained a single, very complex VStack with multiple nested view modifiers, making it too complex for the Swift compiler to efficiently type-check.

## Solution
Broke the complex VStack expression into smaller, more manageable functions:

### 1. Main Function Simplification
```swift
private func composeStyleMessageView(
    _ attribution: AttributionResult, timestamp: Date, plaintext: Data
) -> some View {
    let messageText = String(data: plaintext, encoding: .utf8) ?? "Unable to decode message"

    return VStack(alignment: .leading, spacing: 8) {
        attributionSection(attribution)
        messageContentSection(messageText)
        metadataSection(attribution: attribution, timestamp: timestamp)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
        "Message from \(getSenderName(from: attribution)) received \(DateFormatter.messageTimestamp.string(from: timestamp))"
    )
    .accessibilityValue(messageText)
}
```

### 2. Attribution Section
```swift
private func attributionSection(_ attribution: AttributionResult) -> some View {
    Text(getAttributionText(attribution))
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal)
}
```

### 3. Message Content Section
```swift
private func messageContentSection(_ messageText: String) -> some View {
    ScrollView {
        Text(messageText)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .padding(16)
    }
    .frame(minHeight: 240)
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.green.opacity(0.3), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    .contextMenu {
        Button(action: {
            UIPasteboard.general.string = messageText
            viewModel.showCopySuccess()
        }) {
            Label("Copy Message", systemImage: "doc.on.doc")
        }
    }
    .onTapGesture(count: 2) {
        UIPasteboard.general.string = messageText
        viewModel.showCopySuccess()
    }
}
```

### 4. Metadata Section
```swift
private func metadataSection(attribution: AttributionResult, timestamp: Date) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("From: \(getSenderName(from: attribution))")
            .font(.caption)
            .foregroundColor(.secondary)
        Text("Received: \(DateFormatter.localizedString(from: timestamp, dateStyle: .short, timeStyle: .short))")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding(.horizontal)
}
```

## Benefits

### 1. Build Performance
- ✅ Eliminates compiler timeout errors
- ✅ Faster compilation times
- ✅ More efficient type checking

### 2. Code Maintainability
- ✅ Smaller, focused functions
- ✅ Easier to understand and modify
- ✅ Better separation of concerns
- ✅ Improved readability

### 3. Functionality Preservation
- ✅ All copy functionality maintained (context menu, double-tap)
- ✅ Visual styling preserved (green border, shadows, corners)
- ✅ Accessibility features intact
- ✅ User interactions unchanged

## Testing
- ✅ Complex VStack broken into smaller functions
- ✅ Main function uses simplified sub-functions
- ✅ Copy functionality preserved
- ✅ Visual styling preserved
- ✅ Accessibility features maintained

## Result
The DecryptView now compiles successfully without the complex expression error, while maintaining all functionality and improving code organization.
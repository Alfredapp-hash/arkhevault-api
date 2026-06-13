# Integration Guide: Porting progress_report_extractor.py to Swift

## Overview

This document provides guidance on integrating patterns and architecture from the existing Python `progress_report_extractor.py` into the native macOS Arkhe Vault Client Manager application.

**Source File:** `/Users/purduelaw/Desktop/ArkheApps/StudentTracker/progress_report_extractor.py`

**Target Application:** `/Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVaultClientManager/`

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Key Patterns to Port](#key-patterns-to-port)
3. [Swift Implementation](#swift-implementation)
4. [Integration Points](#integration-points)
5. [Data Migration](#data-migration)
6. [Testing Strategy](#testing-strategy)

---

## Architecture Overview

### Python Architecture (progress_report_extractor.py)

```
┌─────────────────────────────────────┐
│  ProgressReportExtractor            │
├─────────────────────────────────────┤
│  • Field Extraction Patterns       │
│  • Regex Matching                  │
│  • Correction Feedback Loop         │
│  • Confidence Scoring              │
│  • Database Integration            │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  Tesseract OCR                     │
│  (Python-tesseract)                │
└─────────────────────────────────────┘
```

### Swift Architecture (Native macOS)

```
┌─────────────────────────────────────┐
│  DocumentExtractionService          │
├─────────────────────────────────────┤
│  • Field Extraction Patterns       │
│  • Regex Matching (NSRegularExpression) │
│  • Correction Feedback Loop         │
│  • Confidence Scoring              │
│  • Core Data Integration           │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  Vision Framework                   │
│  (VNRecognizeTextRequest)           │
└─────────────────────────────────────┘
```

---

## Key Patterns to Port

### 1. Field Extraction Patterns

**Python Implementation:**
```python
_FIELD_PATTERNS: Dict[str, List[str]] = {
    "student_name": [
        r"(?:student|name)[:\s]+([A-Za-z,\.\s'-]{4,40})",
        r"([A-Z][a-z]+,\s*[A-Z][a-z]+)",
    ],
    "student_id": [
        r"(?:student\s*id|id\s*#?|student\s*#)[:\s#]*([A-Z0-9\-]{4,20})",
    ],
    # ... more patterns
}
```

**Swift Implementation:**
```swift
struct FieldPattern {
    let fieldKey: String
    let patterns: [String]
}

let fieldPatterns: [FieldPattern] = [
    FieldPattern(
        fieldKey: "client_name",
        patterns: [
            "(?:client|name)[:\\s]+([A-Za-z,\\.\\s'-]{4,40})",
            "([A-Z][a-z]+,\\s*[A-Z][a-z]+)"
        ]
    ),
    FieldPattern(
        fieldKey: "client_id",
        patterns: [
            "(?:client\\s*id|id\\s*#?|client\\s*#)[:\\s#]*([A-Z0-9\\-]{4,20})"
        ]
    ),
    // ... more patterns
]
```

### 2. Extracted Field Data Structure

**Python Implementation:**
```python
@dataclass
class ExtractedField:
    field_key: str
    field_value: Optional[str]
    confidence: float
    source_text: Optional[str]
    bounding_box: Optional[Dict]
    reason: str
    needs_review: bool
    status: str
```

**Swift Implementation:**
```swift
struct ExtractedField: Codable, Identifiable {
    let id: UUID
    let fieldKey: String
    let fieldValue: String?
    let confidence: Double
    let sourceText: String?
    let boundingBox: BoundingBox?
    let reason: String
    let needsReview: Bool
    let status: ExtractionStatus
    
    enum ExtractionStatus: String, Codable {
        case extracted
        case notVisible
        case lowConfidence
    }
}

struct BoundingBox: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}
```

### 3. Correction Feedback Loop

**Python Implementation:**
```python
class ProgressReportExtractor:
    def __init__(self, db: DatabaseManager):
        self._correction_table: Dict[str, Dict[str, str]] = {}
        self.rebuild_correction_table()
    
    def rebuild_correction_table(self):
        # Load corrections from database
        # Build lookup table: field_key -> predicted_value -> corrected_value
        pass
```

**Swift Implementation:**
```swift
class DocumentExtractionService: ObservableObject {
    private var correctionTable: [String: [String: String]] = [:]
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        rebuildCorrectionTable()
    }
    
    func rebuildCorrectionTable() {
        let request = NSFetchRequest<FieldCorrection>(entityName: "FieldCorrection")
        
        do {
            let corrections = try context.fetch(request)
            var table: [String: [String: String]] = [:]
            
            for correction in corrections {
                if table[correction.fieldKey] == nil {
                    table[correction.fieldKey] = [:]
                }
                
                // Only apply if minimum votes threshold met
                if correction.voteCount >= 2 {
                    table[correction.fieldKey]?[correction.predictedValue] = correction.correctedValue
                }
            }
            
            correctionTable = table
        } catch {
            print("Error loading corrections: \(error)")
        }
    }
}
```

---

## Swift Implementation

### 1. Create DocumentExtractionService

**File:** `Core/Services/DocumentExtractionService.swift`

```swift
import SwiftUI
import Vision
import NaturalLanguage

class DocumentExtractionService: ObservableObject {
    @Published var extractedFields: [ExtractedField] = []
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    
    private let context: NSManagedObjectContext
    private var correctionTable: [String: [String: String]] = [:]
    
    private let minimumCorrectionVotes = 2
    
    // MARK: - Field Patterns
    
    private let fieldPatterns: [FieldPattern] = [
        // Client Information
        FieldPattern(fieldKey: "client_name", patterns: [
            "(?:client|name)[:\\s]+([A-Za-z,\\.\\s'-]{4,40})",
            "([A-Z][a-z]+,\\s*[A-Z][a-z]+)"
        ]),
        FieldPattern(fieldKey: "client_id", patterns: [
            "(?:client\\s*id|id\\s*#?|client\\s*#)[:\\s#]*([A-Z0-9\\-]{4,20})"
        ]),
        
        // Program Information
        FieldPattern(fieldKey: "program_name", patterns: [
            "(?:program|course|class)[:\\s]+([A-Za-z0-9 \\-&:]{4,60})",
            "([A-Z]{2,6}\\s*\\d{3,4}[A-Z]?\\b)"
        ]),
        
        // Status Information
        FieldPattern(fieldKey: "enrollment_status", patterns: [
            "\\b(current|active|enrolled|in progress)\\b",
            "\\b(completed|complete|finished|passed)\\b",
            "\\b(inactive|withdrawn|dropped|cancelled)\\b"
        ]),
        
        // Date Information
        FieldPattern(fieldKey: "enrollment_date", patterns: [
            "(?:enrollment\\s*date|started|begins?)[:\\s]+(\\d{1,2}[\\/\\-]\\d{1,2}[\\/\\-]\\d{2,4})",
            "(?:enrollment\\s*date|started)[:\\s]+([A-Za-z]+ \\d{1,2},?\\s*\\d{4})"
        ]),
        
        // Progress Information
        FieldPattern(fieldKey: "progress_percentage", patterns: [
            "(\\d{1,3})\\s*%\\s*(?:complete|progress|done|finished)",
            "(?:progress|completion)[:\\s]+(\\d{1,3})\\s*%"
        ]),
        
        // Flags
        FieldPattern(fieldKey: "safety_flag", patterns: [
            "\\b(safety\\s*concern|risk\\s*factor|danger|warning)\\b"
        ]),
        FieldPattern(fieldKey: "payment_flag", patterns: [
            "\\b(payment\\s*(?:due|required|overdue|hold))\\b",
            "\\b(financial\\s*hold|balance\\s*due|outstanding\\s*balance)\\b"
        ])
    ]
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
        rebuildCorrectionTable()
    }
    
    // MARK: - Correction Table
    
    func rebuildCorrectionTable() {
        // Load corrections from Core Data
        // Implementation similar to Python version
    }
    
    // MARK: - Document Processing
    
    func processDocument(image: NSImage) async throws {
        isProcessing = true
        processingProgress = 0
        
        do {
            // 1. Perform OCR using Vision framework
            let ocrText = try await performOCR(image: image)
            processingProgress = 0.3
            
            // 2. Extract fields using regex patterns
            extractedFields = extractFields(from: ocrText)
            processingProgress = 0.7
            
            // 3. Apply correction table
            applyCorrections()
            processingProgress = 1.0
            
            isProcessing = false
        } catch {
            isProcessing = false
            throw error
        }
    }
    
    // MARK: - OCR Processing
    
    private func performOCR(image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw DocumentExtractionError.invalidImage
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            // Store or return recognized text
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        return "" // Return actual recognized text
    }
    
    // MARK: - Field Extraction
    
    private func extractFields(from text: String) -> [ExtractedField] {
        var fields: [ExtractedField] = []
        
        for pattern in fieldPatterns {
            for regexString in pattern.patterns {
                guard let regex = try? NSRegularExpression(pattern: regexString) else {
                    continue
                }
                
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: range)
                
                if let match = matches.first {
                    let field = ExtractedField(
                        id: UUID(),
                        fieldKey: pattern.fieldKey,
                        fieldValue: extractValue(from: match, text: text),
                        confidence: 0.85,
                        sourceText: String(text[Range(match.range, in: text)!]),
                        boundingBox: nil,
                        reason: "Pattern matched with \(regexString)",
                        needsReview: false,
                        status: .extracted
                    )
                    
                    fields.append(field)
                    break // First match wins
                }
            }
        }
        
        return fields
    }
    
    private func extractValue(from match: NSTextCheckingResult, text: String) -> String? {
        guard match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        return String(text[range])
    }
    
    // MARK: - Corrections
    
    private func applyCorrections() {
        for index in extractedFields.indices {
            let field = extractedFields[index]
            
            if let correctedValue = correctionTable[field.fieldKey]?[field.fieldValue ?? ""] {
                extractedFields[index] = ExtractedField(
                    id: field.id,
                    fieldKey: field.fieldKey,
                    fieldValue: correctedValue,
                    confidence: 0.90,
                    sourceText: field.sourceText,
                    boundingBox: field.boundingBox,
                    reason: "Applied from correction memory",
                    needsReview: false,
                    status: .extracted
                )
            }
        }
    }
    
    // MARK: - Save Correction
    
    func saveCorrection(field: ExtractedField, correctedValue: String) {
        // Save correction to Core Data
        // Increment vote count
        // Rebuild correction table
    }
}

// MARK: - Supporting Types

struct FieldPattern {
    let fieldKey: String
    let patterns: [String]
}

enum DocumentExtractionError: Error {
    case invalidImage
    case ocrFailed
    case extractionFailed
}
```

### 2. Create DocumentExtractionView

**File:** `Features/DocumentManagement/Views/DocumentExtractionView.swift`

```swift
import SwiftUI

struct DocumentExtractionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var extractionService = DocumentExtractionService(context: CoreDataController.preview.container.viewContext)
    
    @State private var selectedImage: NSImage?
    @State private var isPickingImage = false
    @State private var isPickingImage = false
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Document Extraction")
            
            // Image Selection
            ArkheCard {
                HStack {
                    Button(action: {
                        isPickingImage = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.viewfinder")
                                .foregroundColor(.forgeTeal)
                            
                            Text(selectedImage?.name() ?? "Select Document")
                                .foregroundColor(.forgeTeal)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
            .fileImporter(isPresented: $isPickingImage, allowedContentTypes: [.image]) { result in
                switch result {
                case .success(let url):
                    if let image = NSImage(contentsOf: url) {
                        selectedImage = image
                    }
                case .failure(let error):
                    print("Image selection error: \(error)")
                }
            }
            
            // Process Button
            if let image = selectedImage {
                ArkheButton(
                    title: extractionService.isProcessing ? "Processing..." : "Extract Fields",
                    style: .primary,
                    isDisabled: extractionService.isProcessing,
                    isLoading: extractionService.isProcessing
                ) {
                    Task {
                        try? await extractionService.processDocument(image: image)
                    }
                }
                
                if extractionService.isProcessing {
                    ProgressView(value: extractionService.processingProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
            
            // Extracted Fields
            if !extractionService.extractedFields.isEmpty {
                SectionHeader(title: "Extracted Fields")
                
                VStack(spacing: 12) {
                    ForEach(extractionService.extractedFields) { field in
                        ExtractedFieldRow(field: field) {
                            // Edit field
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct ExtractedFieldRow: View {
    let field: ExtractedField
    let onEdit: () -> Void
    
    var body: some View {
        ArkheCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(field.fieldKey.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Text(field.fieldValue ?? "Not found")
                        .font(.brandBody)
                        .foregroundColor(field.fieldValue != nil ? .textPrimary : .textMuted)
                    
                    if let source = field.sourceText {
                        Text("Source: \(source)")
                            .font(.brandTiny)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(field.confidence * 100))%")
                        .font(.brandCaption)
                        .foregroundColor(field.confidence > 0.8 ? .successGreen : .warningGold)
                    
                    if field.needsReview {
                        Text("Needs Review")
                            .font(.brandTiny)
                            .foregroundColor(.dangerRed)
                    }
                }
                
                ArkheIconButton(systemImage: "pencil", style: .outline) {
                    onEdit()
                }
            }
        }
    }
}
```

---

## Integration Points

### 1. Document Upload Flow

**Current Implementation:**
- Documents tab allows file upload
- Files are stored with metadata

**Enhanced Flow:**
1. User uploads document
2. System offers "Extract Fields" option
3. OCR processing runs in background
4. Fields are extracted and displayed
5. User can review and correct fields
6. Corrections are saved for future learning

### 2. Intake System Enhancement

**Current Implementation:**
- Manual form filling
- Program routing based on form responses

**Enhanced Flow:**
1. User uploads intake document (PDF/image)
2. System extracts client information
3. Pre-populates intake form with extracted data
4. User reviews and corrects as needed
5. Corrections improve future extraction accuracy

### 3. Case Note Enhancement

**Current Implementation:**
- Manual note entry
- Voice-to-text available

**Enhanced Flow:**
1. User uploads relevant document (e.g., court order, medical report)
2. System extracts key information
3. AI generates note draft using extracted data
4. User reviews and edits

---

## Data Migration

### Core Data Model Extensions

Add the following entities to the data model:

#### FieldCorrection Entity
```swift
@NSManaged public var fieldKey: String
@NSManaged public var predictedValue: String
@NSManaged public var correctedValue: String
@NSManaged public var voteCount: Int32
@NSManaged public var createdAt: Date
```

#### DocumentExtraction Entity
```swift
@NSManaged public var id: UUID
@NSManaged public var documentURL: String
@NSManaged public var extractedFields: [ExtractedField]
@NSManaged public var createdAt: Date
@NSManaged public var createdBy: Staff
```

---

## Testing Strategy

### 1. Unit Tests

**Test Cases:**
- Regex pattern matching accuracy
- Correction table lookup
- Confidence scoring
- Field extraction logic

### 2. Integration Tests

**Test Cases:**
- OCR processing with various document types
- End-to-end extraction workflow
- Correction feedback loop
- Core Data persistence

### 3. UI Tests

**Test Cases:**
- Document upload flow
- Field review and correction
- Progress indication
- Error handling

---

## Migration Checklist

### Phase 1: Core Service
- [ ] Create DocumentExtractionService
- [ ] Implement Vision framework OCR
- [ ] Port regex patterns to Swift
- [ ] Implement correction table logic

### Phase 2: UI Components
- [ ] Create DocumentExtractionView
- [ ] Create ExtractedFieldRow component
- [ ] Implement field editing interface

### Phase 3: Integration
- [ ] Integrate with Documents tab
- [ ] Integrate with Intake system
- [ ] Integrate with Case notes

### Phase 4: Data Model
- [ ] Add FieldCorrection entity
- [ ] Add DocumentExtraction entity
- [ ] Create migrations

### Phase 5: Testing
- [ ] Unit tests for extraction logic
- [ ] Integration tests for OCR
- [ ] UI tests for extraction workflow

---

## Advantages of Native Implementation

### 1. Performance
- **Vision Framework:** Native macOS OCR, faster than Tesseract
- **Swift:** Compiled code, better performance than Python
- **Metal:** GPU acceleration for image processing

### 2. Integration
- **Core Data:** Native persistence, no external database needed
- **EventKit:** Seamless calendar integration
- **Speech Recognition:** Native voice-to-text

### 3. Security
- **Keychain:** Native credential storage
- **Sandboxing:** macOS app sandbox for security
- **Encryption:** Native CryptoKit for data encryption

### 4. User Experience
- **Native UI:** SwiftUI, consistent with macOS design
- **Offline Support:** Works without internet
- **Biometric Auth:** Face ID/Touch ID integration

---

## Conclusion

The progress_report_extractor.py provides valuable patterns for document extraction and field recognition that can be successfully ported to Swift. By leveraging native macOS frameworks (Vision, Core Data, SwiftUI), we can create a more performant, secure, and integrated solution.

**Key Benefits:**
- ✅ Improved OCR accuracy with Vision framework
- ✅ Better performance with compiled Swift code
- ✅ Native integration with macOS features
- ✅ Enhanced security with sandboxing
- ✅ Consistent user experience

**Next Steps:**
1. Implement DocumentExtractionService
2. Create UI components for extraction workflow
3. Integrate with existing document management
4. Test with real documents
5. Deploy and gather user feedback

---

**Document Version:** 1.0
**Last Updated:** 2024
**Status:** Integration Plan - Ready for Implementation
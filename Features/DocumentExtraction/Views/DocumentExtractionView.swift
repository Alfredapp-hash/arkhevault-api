import SwiftUI
import Vision

// MARK: - Document Extraction Service
class DocumentExtractionService: ObservableObject {
    @Published var extractedFields: [ExtractedField] = []
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    @Published var processingStatus: String = ""
    
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
    
    // MARK: - Document Processing
    func processDocument(image: NSImage) async throws {
        isProcessing = true
        processingProgress = 0
        processingStatus = "Initializing..."
        
        do {
            // 1. Perform OCR using Vision framework
            processingStatus = "Performing OCR..."
            let ocrText = try await performOCR(image: image)
            processingProgress = 0.3
            
            // 2. Extract fields using regex patterns
            processingStatus = "Extracting fields..."
            extractedFields = extractFields(from: ocrText)
            processingProgress = 0.7
            
            // 3. Apply correction table
            processingStatus = "Applying corrections..."
            applyCorrections()
            processingProgress = 0.9
            
            // 4. Save extraction record
            processingStatus = "Saving..."
            await saveExtractionRecord(image: image, text: ocrText)
            processingProgress = 1.0
            
            processingStatus = "Complete"
            isProcessing = false
        } catch {
            processingStatus = "Error: \(error.localizedDescription)"
            isProcessing = false
            throw error
        }
    }
    
    // MARK: - OCR Processing
    private func performOCR(image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw DocumentExtractionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
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
    private func rebuildCorrectionTable() {
        // Load corrections from Core Data
        let request = NSFetchRequest<FieldCorrection>(entityName: "FieldCorrection")
        
        do {
            let corrections = try context.fetch(request)
            var table: [String: [String: String]] = [:]
            
            for correction in corrections {
                if table[correction.fieldKey] == nil {
                    table[correction.fieldKey] = [:]
                }
                
                // Only apply if minimum votes threshold met
                if correction.voteCount >= minimumCorrectionVotes {
                    table[correction.fieldKey]?[correction.predictedValue] = correction.correctedValue
                }
            }
            
            correctionTable = table
        } catch {
            print("Error loading corrections: \(error)")
        }
    }
    
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
        let correction = FieldCorrection(context: context)
        correction.id = UUID()
        correction.fieldKey = field.fieldKey
        correction.predictedValue = field.fieldValue ?? ""
        correction.correctedValue = correctedValue
        correction.voteCount = 1
        correction.createdAt = Date()
        
        do {
            try context.save()
            rebuildCorrectionTable()
        } catch {
            print("Error saving correction: \(error)")
        }
    }
    
    // MARK: - Save Extraction Record
    private func saveExtractionRecord(image: NSImage, text: String) async {
        let extraction = DocumentExtraction(context: context)
        extraction.id = UUID()
        extraction.documentURL = "temp_image_\(UUID().uuidString).png"
        extraction.extractedText = text
        extraction.createdAt = Date()
        
        // Save extracted fields as JSON
        if let jsonData = try? JSONEncoder().encode(extractedFields) {
            extraction.extractedFieldsJSON = String(data: jsonData, encoding: .utf8)
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving extraction record: \(error)")
        }
    }
    
    // MARK: - Clear Results
    func clearResults() {
        extractedFields = []
        processingProgress = 0
        processingStatus = ""
    }
}

// MARK: - Supporting Types
struct FieldPattern {
    let fieldKey: String
    let patterns: [String]
}

struct ExtractedField: Identifiable, Codable {
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

enum DocumentExtractionError: Error {
    case invalidImage
    case ocrFailed
    case extractionFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .ocrFailed:
            return "OCR processing failed"
        case .extractionFailed:
            return "Field extraction failed"
        }
    }
}

// MARK: - Document Extraction View
struct DocumentExtractionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var extractionService = DocumentExtractionService(context: CoreDataController.preview.container.viewContext)
    @State private var selectedImage: NSImage?
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
                    
                    if let image = selectedImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(4)
                    }
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
                    VStack(spacing: 8) {
                        ProgressView(value: extractionService.processingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text(extractionService.processingStatus)
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
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

// MARK: - Extracted Field Row
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

// MARK: - Core Data Extensions (Add to model)
// These entities need to be added to the Core Data model:
// - FieldCorrection
// - DocumentExtraction

// MARK: - Preview
#Preview("Document Extraction") {
    DocumentExtractionView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
        .frame(width: 600, height: 800)
        .background(Color.deepCharcoal)
}
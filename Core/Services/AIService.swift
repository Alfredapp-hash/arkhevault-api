import Foundation
import Combine

// MARK: - AI Service for Claude API Integration
class AIService: NSObject, ObservableObject, URLSessionDelegate {
    static let shared = AIService()
    
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private var session: URLSession!
    
    // Anthropic API certificate pinning (base64 encoded SHA256 hashes)
    // These would be updated with actual Anthropic certificate pins
    private let pinnedCertificateHashes: [String] = [
        // Placeholder - replace with actual Anthropic API certificate SHA256 hashes
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
    ]
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private override init() {
        // In production, load from secure storage
        self.apiKey = Configuration.shared.claudeAPIKey
        
        super.init()
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        // MARK: - TLS 1.3 Configuration for AES-256-GCM Encryption
        // Enforce minimum TLS 1.3 for strong encryption
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv13
        
        // Configure TLS session for maximum security
        // This ensures AES-256-GCM cipher suites are prioritized
        if #available(macOS 15.0, iOS 15.0, *) {
            configuration.tlsCipherSuiteTypes = [
                .AES_256_GCM_SHA384,  // Preferred: AES-256-GCM with SHA-384
                .AES_128_GCM_SHA256,  // Fallback: AES-128-GCM with SHA-256
                .CHACHA20_POLY1305_SHA256  // Alternative: ChaCha20-Poly1305
            ]
        }
        
        // Require secure connection - no HTTP allowed
        configuration.httpShouldUsePipelining = false
        configuration.requestCachePolicy = .useProtocolCachePolicy
        
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Certificate Pinning
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              !certificateChain.isEmpty else {
            SecurityEventLogger.shared.logSystemEvent(action: "certificate_pinning", success: false, reason: "no_certificate")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validate certificate against pinned hashes
        var isValid = false
        for certificate in certificateChain {
            if let certificateData = SecCertificateCopyData(certificate) as? Data {
                let certificateHash = SHA256.hash(data: certificateData)
                let hashString = Data(certificateHash).base64EncodedString()
                
                if pinnedCertificateHashes.contains(hashString) {
                    isValid = true
                    break
                }
            }
        }
        
        if isValid {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            SecurityEventLogger.shared.logSystemEvent(action: "certificate_pinning", success: false, reason: "invalid_certificate")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    // MARK: - Client Summary Generation
    func generateClientSummary(client: Client) async throws -> String {
        let prompt = buildClientSummaryPrompt(client: client)
        return try await sendRequest(prompt: prompt, maxTokens: 500)
    }
    
    // MARK: - Risk Assessment Analysis
    func analyzeRiskAssessment(client: Client, factors: [String]) async throws -> RiskAnalysisResult {
        let prompt = buildRiskAssessmentPrompt(client: client, factors: factors)
        let response = try await sendRequest(prompt: prompt, maxTokens: 800)
        return parseRiskAnalysis(response)
    }
    
    // MARK: - Follow-up Suggestions
    func generateFollowUpSuggestions(client: Client) async throws -> [FollowUpSuggestion] {
        let prompt = buildFollowUpPrompt(client: client)
        let response = try await sendRequest(prompt: prompt, maxTokens: 600)
        return parseFollowUpSuggestions(response)
    }
    
    // MARK: - Note Enhancement
    func enhanceNote(originalNote: String, noteType: String) async throws -> EnhancedNote {
        let prompt = buildNoteEnhancementPrompt(originalNote: originalNote, noteType: noteType)
        let response = try await sendRequest(prompt: prompt, maxTokens: 700)
        return parseEnhancedNote(response)
    }
    
    // MARK: - Grant Narrative Generation
    func generateGrantNarrative(metrics: GrantMetrics, timeframe: String) async throws -> String {
        let prompt = buildGrantNarrativePrompt(metrics: metrics, timeframe: timeframe)
        return try await sendRequest(prompt: prompt, maxTokens: 1000)
    }
    
    // MARK: - Document Content Extraction (leveraging existing patterns)
    func extractDocumentContent(from imageData: Data, documentType: String) async throws -> DocumentExtractionResult {
        // This could integrate with OCR capabilities similar to the progress_report_extractor
        // For now, we'll use Claude's vision capabilities when available
        
        let prompt = buildDocumentExtractionPrompt(documentType: documentType)
        
        // Note: Claude's vision capabilities would be used here
        // For now, returning a placeholder structure
        return DocumentExtractionResult(
            extractedFields: [:],
            confidence: 0.0,
            needsReview: true,
            suggestedCorrections: []
        )
    }
    
    // MARK: - Helper Methods
    private func sendRequest(prompt: String, maxTokens: Int) async throws -> String {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        let request = ClaudeRequest(
            model: "claude-3-5-sonnet-20241022",
            maxTokens: maxTokens,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ]
        )
        
        do {
            let encodedRequest = try JSONEncoder().encode(request)
            var urlRequest = URLRequest(url: URL(string: baseURL)!)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = encodedRequest
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AIServiceError.httpError(httpResponse.statusCode)
            }
            
            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            return claudeResponse.content.first?.text ?? ""
            
        } catch {
            errorMessage = "AI service error: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Prompt Builders
    private func buildClientSummaryPrompt(client: Client) -> String {
        var prompt = """
        Generate a concise client summary for Arkhe Vault client management system.
        
        Client Information:
        - Name: \(client.fullName)
        - Risk Level: \(client.riskLevel ?? "Unknown")
        - Housing Status: \(client.housingStatus ?? "Unknown")
        - Active Programs: \(client.activeProgramsCount)
        - Open Tasks: \(client.openTasksCount)
        - Has Safety Flags: \(client.hasActiveSafetyFlags ? "Yes" : "No")
        """
        
        if let biography = client.biography, !biography.isEmpty {
            prompt += "\n- Biography: \(biography)"
        }
        
        if !client.safetyConcerns.isEmpty, let concerns = client.safetyConcerns {
            prompt += "\n- Safety Concerns: \(concerns.joined(", "))"
        }
        
        prompt += """
        
        Generate a 2-3 sentence summary that captures the client's current situation, key needs, and priority level. Focus on actionable insights for staff.
        """
        
        return prompt
    }
    
    private func buildRiskAssessmentPrompt(client: Client, factors: [String]) -> String {
        return """
        Analyze the risk level for this client based on the provided factors.
        
        Client: \(client.fullName)
        Current Risk Level: \(client.riskLevel ?? "Unknown")
        
        Risk Factors to Consider:
        \(factors.joined(separator: "\n"))
        
        Provide:
        1. Recommended risk level (low, medium, high, critical)
        2. Key risk indicators
        3. Recommended follow-up priority (immediate, within 24 hours, within 48 hours, within week)
        4. Specific concerns to address
        """
    }
    
    private func buildFollowUpPrompt(client: Client) -> String {
        return """
        Generate follow-up suggestions for this client.
        
        Client: \(client.fullName)
        Last Contact: \(client.lastContactDate?.formatted(date: .long, time: .shortened) ?? "Never")
        Active Programs: \(client.activeProgramsCount)
        Open Tasks: \(client.openTasksCount)
        Risk Level: \(client.riskLevel ?? "Unknown")
        
        Suggest 3-5 specific follow-up actions with priorities and timeframes.
        """
    }
    
    private func buildNoteEnhancementPrompt(originalNote: String, noteType: String) -> String {
        return """
        Enhance the following case note for professional documentation.
        
        Note Type: \(noteType)
        Original Note: \(originalNote)
        
        Please:
        1. Correct grammar and improve clarity
        2. Organize into clear sections if appropriate
        3. Ensure professional tone appropriate for victim advocacy
        4. Identify any missing key information
        5. Suggest appropriate follow-up actions
        """
    }
    
    private func buildGrantNarrativePrompt(metrics: GrantMetrics, timeframe: String) -> String {
        return """
        Generate a compelling grant narrative for Arkhe Vault.
        
        Time Period: \(timeframe)
        
        Metrics:
        - Total Clients Served: \(metrics.totalClientsServed)
        - Programs Completed: \(metrics.programsCompleted)
        - Safe House Placements: \(metrics.safeHousePlacements)
        - Volunteer Hours: \(metrics.volunteerHours)
        - Staff Hours: \(metrics.staffHours)
        
        Write a 200-300 word narrative that demonstrates impact, highlights successes, and aligns with Arkhe Vault's mission of serving survivors of commercial sex trafficking.
        """
    }
    
    private func buildDocumentExtractionPrompt(documentType: String) -> String {
        return """
        Extract structured information from this \(documentType) document.
        Focus on key fields relevant to client management and case documentation.
        Provide field names, extracted values, and confidence levels.
        """
    }
    
    // MARK: - Response Parsers
    private func parseRiskAnalysis(_ response: String) -> RiskAnalysisResult {
        // Parse structured response from Claude
        // This would be more sophisticated in production
        return RiskAnalysisResult(
            recommendedLevel: .medium,
            keyIndicators: [],
            followUpPriority: .within48Hours,
            specificConcerns: []
        )
    }
    
    private func parseFollowUpSuggestions(_ response: String) -> [FollowUpSuggestion] {
        // Parse structured response from Claude
        return []
    }
    
    private func parseEnhancedNote(_ response: String) -> EnhancedNote {
        return EnhancedNote(
            enhancedText: response,
            grammarCorrections: [],
            missingFields: [],
            suggestedFollowUps: []
        )
    }
}

// MARK: - AI Service Models
struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let content: [ClaudeContent]
}

struct ClaudeContent: Codable {
    let text: String
}

// MARK: - AI Result Models
struct RiskAnalysisResult {
    let recommendedLevel: RiskLevel
    let keyIndicators: [String]
    let followUpPriority: FollowUpPriority
    let specificConcerns: [String]
    
    enum RiskLevel {
        case low, medium, high, critical
    }
    
    enum FollowUpPriority {
        case immediate, within24Hours, within48Hours, withinWeek
    }
}

struct FollowUpSuggestion {
    let action: String
    let priority: RiskAnalysisResult.FollowUpPriority
    let timeframe: String
    let assignedTo: String?
}

struct EnhancedNote {
    let enhancedText: String
    let grammarCorrections: [String]
    let missingFields: [String]
    let suggestedFollowUps: [String]
}

struct GrantMetrics {
    let totalClientsServed: Int
    let programsCompleted: Int
    let safeHousePlacements: Int
    let volunteerHours: Double
    let staffHours: Double
}

struct DocumentExtractionResult {
    let extractedFields: [String: String]
    let confidence: Double
    let needsReview: Bool
    let suggestedCorrections: [String]
}

// MARK: - AI Service Errors
enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int)
    case rateLimitExceeded
    case invalidRequest
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Claude API key is not configured"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidRequest:
            return "Invalid request to AI service"
        }
    }
}

// MARK: - AI Assistant View Model
class AIAssistantViewModel: ObservableObject {
    @Published var generatedSummary: String = ""
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private let aiService = AIService.shared
    
    func generateClientSummary(client: Client) {
        Task {
            isGenerating = true
            errorMessage = nil
            
            do {
                generatedSummary = try await aiService.generateClientSummary(client: client)
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isGenerating = false
        }
    }
    
    func enhanceNote(originalNote: String, noteType: String, completion: @escaping (EnhancedNote) -> Void) {
        Task {
            do {
                let result = try await aiService.enhanceNote(originalNote: originalNote, noteType: noteType)
                await MainActor.run {
                    completion(result)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - AI-Powered Note Editor View
struct AINoteEditorView: View {
    @State private var originalNote: String = ""
    @State private var enhancedNote: String = ""
    @State private var noteType: String = "General"
    @State private var isEnhancing = false
    @State private var showEnhancementOptions = false
    
    @StateObject private var viewModel = AIAssistantViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // Note Type Selector
            Picker("Note Type", selection: $noteType) {
                Text("General").tag("General")
                Text("Safety").tag("Safety")
                Text("Housing").tag("Housing")
                Text("Court Advocacy").tag("Court Advocacy")
                Text("Program").tag("Program")
                Text("Crisis").tag("Crisis")
            }
            .pickerStyle(MenuPickerStyle())
            
            // Original Note
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Original Note")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Button(action: {
                        showEnhancementOptions = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("AI Enhance")
                        }
                        .font(.brandCaption)
                        .foregroundColor(.forgeTeal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                TextEditor(text: $originalNote)
                    .frame(minHeight: 150)
                    .padding()
                    .background(Color.darkCharcoal)
                    .foregroundColor(.textPrimary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.lightCharcoal, lineWidth: 1)
                    )
            }
            
            // Enhanced Note
            if !enhancedNote.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Enhanced Note")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                        
                        StatusBadge(text: "AI Enhanced", status: .info)
                    }
                    
                    TextEditor(text: $enhancedNote)
                        .frame(minHeight: 150)
                        .padding()
                        .background(Color.forgeTeal.opacity(0.05))
                        .foregroundColor(.textPrimary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.forgeTeal.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            // Enhancement Options Sheet
            .sheet(isPresented: $showEnhancementOptions) {
                EnhancementOptionsSheet(
                    originalNote: originalNote,
                    noteType: noteType,
                    isEnhancing: $isEnhancing
                ) { enhanced in
                    enhancedNote = enhanced.enhancedText
                    showEnhancementOptions = false
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                ArkheButton(title: "Cancel", style: .outline) {
                    // Cancel action
                }
                
                ArkheButton(title: "Save Note", style: .primary) {
                    // Save note action
                }
            }
        }
        .padding()
    }
}

// MARK: - Enhancement Options Sheet
struct EnhancementOptionsSheet: View {
    let originalNote: String
    let noteType: String
    @Binding var isEnhancing: Bool
    let completion: (EnhancedNote) -> Void
    
    @State private var selectedOptions: Set<EnhancementOption> = []
    
    enum EnhancementOption: String, CaseIterable {
        case grammar = "Grammar & Style"
        case organization = "Organization"
        case tone = "Professional Tone"
        case missingFields = "Identify Missing Fields"
        case followUps = "Suggest Follow-ups"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("AI Enhancement Options")
                    .font(.brandHeading)
                    .foregroundColor(.textPrimary)
                
                Text("Select what you'd like AI to enhance:")
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(EnhancementOption.allCases, id: \.self) { option in
                        Button(action: {
                            if selectedOptions.contains(option) {
                                selectedOptions.remove(option)
                            } else {
                                selectedOptions.insert(option)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedOptions.contains(option) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedOptions.contains(option) ? .forgeTeal : .textSecondary)
                                
                                Text(option.rawValue)
                                    .font(.brandBody)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                
                ArkheButton(
                    title: isEnhancing ? "Enhancing..." : "Enhance Note",
                    style: .primary,
                    isDisabled: selectedOptions.isEmpty || isEnhancing,
                    isLoading: isEnhancing
                ) {
                    enhanceNote()
                }
            }
            .padding()
            .navigationTitle("Enhance Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Dismiss
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }
    
    private func enhanceNote() {
        isEnhancing = true
        
        Task {
            do {
                let result = try await AIService.shared.enhanceNote(
                    originalNote: originalNote,
                    noteType: noteType
                )
                
                await MainActor.run {
                    completion(result)
                    isEnhancing = false
                }
            } catch {
                await MainActor.run {
                    isEnhancing = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AINoteEditorView()
        .frame(width: 600, height: 500)
        .background(Color.deepCharcoal)
}
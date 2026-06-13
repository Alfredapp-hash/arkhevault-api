import SwiftUI
import Speech

// MARK: - Client Notes Tab
struct ClientNotesTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    let client: Client
    
    @State private var showingNewNoteSheet = false
    @State private var selectedNote: CaseNote?
    @State private var notes: [CaseNote] = []
    @State private var filter: NoteFilter = .all
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                SectionHeader(title: "Case Notes", subtitle: "\(filteredNotes.count) notes")
                
                ArkheButton(title: "New Note", style: .primary) {
                    showingNewNoteSheet = true
                }
            }
            
            // Filters
            HStack(spacing: 12) {
                Picker("Filter", selection: $filter) {
                    ForEach(NoteFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
            }
            
            // Notes List
            if filteredNotes.isEmpty {
                ArkheCard {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.textMuted)
                        
                        Text("No case notes yet")
                            .font(.brandBody)
                            .foregroundColor(.textSecondary)
                        
                        Text("Create your first case note for this client")
                            .font(.brandCaption)
                            .foregroundColor(.textMuted)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredNotes, id: \.id) { note in
                            CaseNoteCard(note: note) {
                                selectedNote = note
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            NewCaseNoteSheet(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedNote) { note in
            CaseNoteDetailView(note: note)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            loadNotes()
        }
        .onChange(of: filter) { newValue in
            applyFilter()
        }
    }
    
    private var filteredNotes: [CaseNote] {
        switch filter {
        case .all:
            return notes
        case .standard:
            return notes.filter { $0.visibilityLevel == "standard" }
        case .confidential:
            return notes.filter { $0.visibilityLevel == "confidential" }
        case .requiresReview:
            return notes.filter { $0.supervisorReviewFlag }
        case .voiceGenerated:
            return notes.filter { $0.isVoiceGenerated }
        }
    }
    
    private func loadNotes() {
        if let notesSet = client.caseNotes, let notesArray = notesSet.allObjects as? [CaseNote] {
            notes = notesArray.sorted { ($0.createdAt as Date?) ?? Date.distantPast > ($1.createdAt as Date?) ?? Date.distantPast }
        }
    }
    
    private func applyFilter() {
        // Filter is computed property
    }
}

enum NoteFilter: String, CaseIterable {
    case all = "All Notes"
    case standard = "Standard"
    case confidential = "Confidential"
    case requiresReview = "Requires Review"
    case voiceGenerated = "Voice Generated"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Case Note Card
struct CaseNoteCard: View {
    let note: CaseNote
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ArkheCard(backgroundColor: backgroundColor) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.noteType?.capitalized ?? "Case Note")
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            if let staff = note.staff {
                                Text("By \(staff.fullName)")
                                    .font(.brandTiny)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            if note.isVoiceGenerated {
                                HStack(spacing: 4) {
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(.forgeTeal)
                                        .font(.brandTiny)
                                    
                                    Text("Voice")
                                        .font(.brandTiny)
                                        .foregroundColor(.forgeTeal)
                                }
                            }
                            
                            if note.supervisorReviewFlag {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.warningGold)
                                        .font(.brandTiny)
                                    
                                    Text("Review")
                                        .font(.brandTiny)
                                        .foregroundColor(.warningGold)
                                }
                            }
                            
                            StatusBadge(
                                text: note.visibilityLevel?.capitalized ?? "Standard",
                                status: note.visibilityLevel == "confidential" ? .warning : .neutral
                            )
                        }
                    }
                    
                    // Narrative Preview
                    if let narrative = note.narrative {
                        Text(narrative)
                            .font(.brandBody)
                            .foregroundColor(.textSecondary)
                            .lineLimit(3)
                    }
                    
                    // Metadata
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Created: \(note.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.brandTiny)
                                .foregroundColor(.textMuted)
                            
                            if let program = note.programEnrollment?.program {
                                Text("Program: \(program.name)")
                                    .font(.brandTiny)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        if let followUpDate = note.followUpDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.forgeTeal)
                                    .font(.brandTiny)
                                
                                Text("Follow-up: \(followUpDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.brandTiny)
                                    .foregroundColor(.forgeTeal)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if note.visibilityLevel == "confidential" {
            return Color.warningGold.opacity(0.1)
        } else if note.supervisorReviewFlag {
            return Color.dangerRed.opacity(0.1)
        } else {
            return Color.lightCharcoal
        }
    }
}

// MARK: - New Case Note Sheet
struct NewCaseNoteSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    
    @State private var noteType: NoteType = .general
    @State private var narrative = ""
    @State private var visibilityLevel: NoteVisibility = .standard
    @State private var requireReview = false
    @State private var followUpDate: Date?
    @State private var selectedProgram: ProgramEnrollment?
    @State private var isRecording = false
    @State private var transcription = ""
    @State private var showingAIEnhancer = false
    @State private var isLoading = false
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    Picker("Note Type", selection: $noteType) {
                        ForEach(NoteType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Picker("Visibility Level", selection: $visibilityLevel) {
                        ForEach(NoteVisibility.allCases, id: \.self) { visibility in
                            Text(visibility.displayName).tag(visibility)
                        }
                    }
                    
                    Toggle("Require Supervisor Review", isOn: $requireReview)
                    
                    if let enrollments = client.programEnrollments?.allObjects as? [ProgramEnrollment],
                       !enrollments.filter({ $0.isActive }).isEmpty {
                        Picker("Related Program", selection: $selectedProgram) {
                            Text("No program").tag(nil as ProgramEnrollment?)
                            ForEach(enrollments.filter { $0.isActive }, id: \.id) { enrollment in
                                Text(enrollment.program?.name ?? "Program").tag(enrollment as ProgramEnrollment?)
                            }
                        }
                    }
                    
                    DatePicker("Follow-up Date", selection: $followUpDate, displayedComponents: .date)
                }
                
                Section(header: Text("Note Content")) {
                    // Voice Recording
                    HStack {
                        Button(action: toggleRecording) {
                            HStack(spacing: 8) {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(isRecording ? .dangerRed : .forgeTeal)
                                
                                Text(isRecording ? "Stop Recording" : "Start Voice Recording")
                                    .font(.brandBody)
                                    .foregroundColor(isRecording ? .dangerRed : .forgeTeal)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        if speechRecognizer.isTranscribing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                    
                    if !transcription.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Voice Transcription")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                            
                            Text(transcription)
                                .font(.brandBody)
                                .foregroundColor(.textPrimary)
                                .padding()
                                .background(Color.forgeTeal.opacity(0.05))
                                .cornerRadius(8)
                            
                            Button("Use Transcription") {
                                narrative = transcription
                                transcription = ""
                            }
                            .font(.brandCaption)
                            .foregroundColor(.forgeTeal)
                        }
                    }
                    
                    // Text Editor
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Narrative")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAIEnhancer = true
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
                        
                        TextEditor(text: $narrative)
                            .frame(minHeight: 150)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                }
                
                Section(header: Text("AI Assistance")) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.forgeTeal)
                        
                        Text("AI enhancement can improve grammar, organize content, and suggest follow-up actions")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("New Case Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Save Note",
                        style: .primary,
                        isDisabled: narrative.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        saveNote()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .sheet(isPresented: $showingAIEnhancer) {
            AIEnhancementSheet(
                originalNote: narrative,
                noteType: noteType.displayName
            ) { enhanced in
                narrative = enhanced.enhancedText
                showingAIEnhancer = false
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopRecording()
            isRecording = false
        } else {
            speechRecognizer.startRecording()
            isRecording = true
        }
    }
    
    private func saveNote() {
        guard let currentUser = Staff.fetchAll(in: viewContext).first else { return }
        
        isLoading = true
        
        let note = CaseNote.create(
            in: viewContext,
            client: client,
            noteType: noteType.rawValue,
            narrative: narrative,
            staff: currentUser,
            programEnrollment: selectedProgram
        )
        
        note.visibilityLevel = visibilityLevel.rawValue
        note.supervisorReviewFlag = requireReview
        note.followUpDate = followUpDate
        note.isVoiceGenerated = !transcription.isEmpty
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error saving note: \(error)")
            isLoading = false
        }
    }
}

enum NoteType: String, CaseIterable {
    case general = "General"
    case intake = "Intake"
    case safety = "Safety Assessment"
    case housing = "Housing Update"
    case employment = "Employment Update"
    case legal = "Legal Update"
    case court = "Court Appearance"
    case counseling = "Counseling Session"
    case crisis = "Crisis Intervention"
    case followUp = "Follow-up Call"
    case referral = "Referral Made"
    case discharge = "Discharge Summary"
    
    var displayName: String {
        rawValue
    }
}

enum NoteVisibility: String, CaseIterable {
    case standard = "Standard"
    case confidential = "Confidential"
    case supervisor = "Supervisor Only"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Speech Recognizer
class SpeechRecognizer: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcription = ""
    
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine = AVAudioEngine()
    
    func startRecording() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer not available")
            return
        }
        
        isTranscribing = true
        transcription = ""
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcription = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                print("Recognition error: \(error)")
                self.stopRecording()
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }
}

// MARK: - AI Enhancement Sheet
struct AIEnhancementSheet: View {
    let originalNote: String
    let noteType: String
    @Environment(\.dismiss) private var dismiss
    let completion: (EnhancedNote) -> Void
    
    @State private var enhancedNote: EnhancedNote?
    @State private var isEnhancing = false
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
                
                if let enhanced = enhancedNote {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enhanced Note")
                            .font(.brandSubheading)
                            .foregroundColor(.textPrimary)
                        
                        TextEditor(text: .constant(enhanced.enhancedText))
                            .frame(minHeight: 150)
                            .background(Color.forgeTeal.opacity(0.05))
                            .cornerRadius(8)
                            .disabled(true)
                        
                        if !enhanced.grammarCorrections.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Grammar Corrections")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                ForEach(enhanced.grammarCorrections, id: \.self) { correction in
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.successGreen)
                                            .font(.brandTiny)
                                        Text(correction)
                                            .font(.brandTiny)
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                        }
                        
                        if !enhanced.suggestedFollowUps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Suggested Follow-ups")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                ForEach(enhanced.suggestedFollowUps, id: \.self) { followUp in
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(.forgeTeal)
                                            .font(.brandTiny)
                                        Text(followUp)
                                            .font(.brandTiny)
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                        }
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
                        dismiss()
                    }
                }
                
                if let enhanced = enhancedNote {
                    ToolbarItem(placement: .primaryAction) {
                        ArkheButton(title: "Use Enhanced", style: .primary) {
                            completion(enhanced)
                            dismiss()
                        }
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
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
                    enhancedNote = result
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

// MARK: - Case Note Detail View
struct CaseNoteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let note: CaseNote
    
    @State private var showingReviewDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.noteType?.capitalized ?? "Case Note")
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    if let client = note.client {
                        Text(client.fullName)
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if note.supervisorReviewFlag {
                    ArkheButton(title: "Mark as Reviewed", style: .secondary) {
                        showingReviewDialog = true
                    }
                }
            }
            .padding()
            .background(note.supervisorReviewFlag ? Color.warningGold.opacity(0.15) : Color.darkCharcoal)
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Note Details")
                    
                    ArkheCard {
                        VStack(spacing: 12) {
                            InfoRow(icon: "list.bullet", title: "Note Type", value: note.noteType?.displayName ?? "General")
                            InfoRow(icon: "eye.fill", title: "Visibility", value: note.visibilityLevel?.capitalized ?? "Standard")
                            
                            if note.isVoiceGenerated {
                                HStack(spacing: 8) {
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(.forgeTeal)
                                    Text("Voice-generated note")
                                        .font(.brandCaption)
                                        .foregroundColor(.forgeTeal)
                                }
                            }
                            
                            if let staff = note.staff {
                                InfoRow(icon: "person.fill", title: "Created By", value: staff.fullName)
                            }
                            
                            InfoRow(icon: "calendar", title: "Created", value: note.createdAt.formatted(date: .long, time: .shortened))
                            
                            if let reviewedAt = note.reviewedAt {
                                InfoRow(icon: "checkmark.circle.fill", title: "Reviewed", value: reviewedAt.formatted(date: .long, time: .shortened), iconColor: .successGreen)
                            }
                        }
                    }
                    
                    // Narrative
                    if let narrative = note.narrative {
                        SectionHeader(title: "Narrative")
                        
                        ArkheCard {
                            Text(narrative)
                                .font(.brandBody)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    
                    // Follow-up
                    if let followUpDate = note.followUpDate {
                        SectionHeader(title: "Follow-up")
                        
                        ArkheCard {
                            InfoRow(icon: "calendar.badge.exclamationmark", title: "Follow-up Date", value: followUpDate.formatted(date: .long, time: .omitted), iconColor: .forgeTeal)
                        }
                    }
                    
                    // Related Program
                    if let enrollment = note.programEnrollment {
                        SectionHeader(title: "Related Program")
                        
                        ArkheCard {
                            InfoRow(icon: "star.fill", title: "Program", value: enrollment.program?.name ?? "Unknown")
                        }
                    }
                    
                    // Timeline
                    SectionHeader(title: "Timeline")
                    
                    ArkheCard {
                        VStack(spacing: 16) {
                            TimelineItem(
                                icon: "plus.circle.fill",
                                title: "Note Created",
                                date: note.createdAt,
                                user: note.staff?.fullName ?? "System"
                            )
                            
                            if let reviewedAt = note.reviewedAt {
                                TimelineItem(
                                    icon: "checkmark.shield.fill",
                                    title: "Note Reviewed",
                                    date: reviewedAt,
                                    user: note.reviewedBy?.fullName ?? "System",
                                    color: .successGreen
                                )
                            }
                        }
                    }
                    
                    // Actions
                    HStack(spacing: 12) {
                        ArkheButton(title: "Edit Note", style: .primary) {
                            // Edit action
                        }
                        
                        ArkheButton(title: "Print", style: .secondary) {
                            // Print action
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.deepCharcoal)
        .alert("Mark as Reviewed", isPresented: $showingReviewDialog) {
            Alert(
                title: Text("Mark Note as Reviewed"),
                message: Text("This will mark the note as reviewed by a supervisor."),
                primaryButton: .default(Text("Mark Reviewed")) {
                    markAsReviewed()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func markAsReviewed() {
        guard let currentUser = Staff.fetchAll(in: viewContext).first else { return }
        note.markAsReviewed(reviewedBy: currentUser)
        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    ClientNotesTab(client: CoreDataController.preview.container.viewContext.fetch(Client.self).first!)
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}
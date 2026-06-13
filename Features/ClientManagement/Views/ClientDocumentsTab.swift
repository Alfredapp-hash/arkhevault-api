import SwiftUI
import UniformTypeIdentifiers

// MARK: - Client Documents Tab
struct ClientDocumentsTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    let client: Client
    
    @State private var showingUploadSheet = false
    @State private var selectedDocument: Document?
    @State private var documents: [Document] = []
    @State private var filter: DocumentFilter = .all
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                SectionHeader(title: "Documents", subtitle: "\(filteredDocuments.count) documents")
                
                ArkheButton(title: "Upload Document", style: .primary) {
                    showingUploadSheet = true
                }
            }
            
            // Search and Filters
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    
                    TextField("Search documents...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.lightCharcoal)
                .cornerRadius(8)
                
                Picker("Filter", selection: $filter) {
                    ForEach(DocumentFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
            }
            
            // Documents List
            if filteredDocuments.isEmpty {
                ArkheCard {
                    VStack(spacing: 12) {
                        Image(systemName: "doc")
                            .font(.system(size: 32))
                            .foregroundColor(.textMuted)
                        
                        Text("No documents yet")
                            .font(.brandBody)
                            .foregroundColor(.textSecondary)
                        
                        Text("Upload documents to this client's file")
                            .font(.brandCaption)
                            .foregroundColor(.textMuted)
                    }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredDocuments, id: \.id) { document in
                            DocumentCard(document: document) {
                                selectedDocument = document
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingUploadSheet) {
            UploadDocumentSheet(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedDocument) { document in
            DocumentDetailView(document: document)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            loadDocuments()
        }
        .onChange(of: filter) { newValue in
            applyFilter()
        }
        .onChange(of: searchText) { newValue in
            applyFilter()
        }
    }
    
    private var filteredDocuments: [Document] {
        var filtered = documents
        
        // Apply type filter
        switch filter {
        case .all:
            break
        case .legal:
            filtered = filtered.filter { $0.documentType?.contains("legal") == true }
        case .personal:
            filtered = filtered.filter { $0.documentType?.contains("personal") == true }
        case medical:
            filtered = filtered.filter { $0.documentType?.contains("medical") == true }
        case program:
            filtered = filtered.filter { $0.documentType?.contains("program") == true }
        case confidential:
            filtered = filtered.filter { $0.visibilityLevel == "confidential" }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { document in
                (document.documentName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (document.documentType?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered
    }
    
    private func loadDocuments() {
        if let documentsSet = client.documents, let documentsArray = documentsSet.allObjects as? [Document] {
            documents = documentsArray.sorted { ($0.uploadDate as Date?) ?? Date.distantPast > ($1.uploadDate as Date?) ?? Date.distantPast }
        }
    }
    
    private func applyFilter() {
        // Filter is computed property
    }
}

enum DocumentFilter: String, CaseIterable {
    case all = "All Documents"
    case legal = "Legal"
    case personal = "Personal"
    case medical = "Medical"
    case program = "Program"
    case confidential = "Confidential"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Document Card
struct DocumentCard: View {
    let document: Document
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ArkheCard(backgroundColor: backgroundColor) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.documentName ?? "Untitled")
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            
                            Text(document.documentType?.capitalized ?? "Document")
                                .font(.brandTiny)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            if document.signatureStatus == "signed" {
                                HStack(spacing: 4) {
                                    Image(systemName: "signature")
                                        .foregroundColor(.successGreen)
                                        .font(.brandTiny)
                                    
                                    Text("Signed")
                                        .font(.brandTiny)
                                        .foregroundColor(.successGreen)
                                }
                            }
                            
                            if document.visibilityLevel == "confidential" {
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.warningGold)
                                        .font(.brandTiny)
                                    
                                    Text("Confidential")
                                        .font(.brandTiny)
                                        .foregroundColor(.warningGold)
                                }
                            }
                        }
                    }
                    
                    // File Info
                    HStack {
                        Image(systemName: fileIcon)
                            .foregroundColor(.forgeTeal)
                            .font(.system(size: 32))
                            .frame(width: 40, height: 40)
                            .background(Color.forgeTeal.opacity(0.1))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatFileSize(document.fileSize))
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                            
                            if let uploadDate = document.uploadDate {
                                Text("Uploaded: \(uploadDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.brandTiny)
                                    .foregroundColor(.textMuted)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Actions
                    HStack(spacing: 8) {
                        ArkheButton(title: "View", style: .primary) {
                            onTap()
                        }
                        
                        ArkheIconButton(systemImage: "square.and.arrow.down", style: .secondary) {
                            // Download action
                        }
                        
                        ArkheIconButton(systemImage: "square.and.arrow.up", style: .outline) {
                            // Share action
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if document.visibilityLevel == "confidential" {
            return Color.warningGold.opacity(0.1)
        } else {
            return Color.lightCharcoal
        }
    }
    
    private var fileIcon: String {
        guard let type = document.documentType?.lowercased() else { return "doc" }
        
        if type.contains("pdf") {
            return "doc.richtext"
        } else if type.contains("image") {
            return "photo"
        } else if type.contains("word") {
            return "doc.text"
        } else if type.contains("excel") {
            return "tablecells"
        } else {
            return "doc"
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Upload Document Sheet
struct UploadDocumentSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    
    @State private var selectedFileURL: URL?
    @State private var documentName = ""
    @State private var documentType: DocumentType = .other
    @State private var visibilityLevel: DocumentVisibility = .standard
    @State private var requiresSignature = false
    @State private var expirationDate: Date?
    @State private var accessRestrictions: Set<String> = []
    @State private var notes = ""
    @State private var isUploading = false
    @State private var isPickingFile = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("File Selection")) {
                    HStack {
                        Button(action: {
                            isPickingFile = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.forgeTeal)
                                
                                Text(selectedFileURL?.lastPathComponent ?? "Choose File")
                                    .foregroundColor(.forgeTeal)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .fileImporter(
                        isPresented: $isPickingFile,
                        allowedContentTypes: [.pdf, .image, .plainText, .commaSeparatedText],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                selectedFileURL = url
                                documentName = url.lastPathComponent
                                documentType = inferDocumentType(from: url)
                            }
                        case .failure(let error):
                            print("File selection error: \(error)")
                        }
                    }
                }
                
                Section(header: Text("Document Details")) {
                    TextField("Document Name", text: $documentName)
                    
                    Picker("Document Type", selection: $documentType) {
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Picker("Visibility Level", selection: $visibilityLevel) {
                        ForEach(DocumentVisibility.allCases, id: \.self) { visibility in
                            Text(visibility.displayName).tag(visibility)
                        }
                    }
                    
                    Toggle("Requires Signature", isOn: $requiresSignature)
                    
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }
                
                Section(header: Text("Access Control")) {
                    Text("Configure who can access this document")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        AccessRestrictionRow(
                            restriction: "Assigned Advocate Only",
                            isEnabled: accessRestrictions.contains("advocate")
                        ) { isEnabled in
                            if isEnabled {
                                accessRestrictions.insert("advocate")
                            } else {
                                accessRestrictions.remove("advocate")
                            }
                        }
                        
                        AccessRestrictionRow(
                            restriction: "Program Staff Only",
                            isEnabled: accessRestrictions.contains("program")
                        ) { isEnabled in
                            if isEnabled {
                                accessRestrictions.insert("program")
                            } else {
                                accessRestrictions.remove("program")
                            }
                        }
                        
                        AccessRestrictionRow(
                            restriction: "Supervisor Only",
                            isEnabled: accessRestrictions.contains("supervisor")
                        ) { isEnabled in
                            if isEnabled {
                                accessRestrictions.insert("supervisor")
                            } else {
                                accessRestrictions.remove("supervisor")
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Security Notice")) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.warningGold)
                        
                        Text("All documents are encrypted and access is logged")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("Upload Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Upload",
                        style: .primary,
                        isDisabled: selectedFileURL == nil || documentName.isEmpty || isUploading,
                        isLoading: isUploading
                    ) {
                        uploadDocument()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func inferDocumentType(from url: URL) -> DocumentType {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "pdf":
            return .legal
        case "jpg", "jpeg", "png":
            return .personal
        case "doc", "docx":
            return .legal
        case "xls", "xlsx":
            return .program
        default:
            return .other
        }
    }
    
    private func uploadDocument() {
        guard let fileURL = selectedFileURL,
              let currentUser = Staff.fetchAll(in: viewContext).first else { return }
        
        isUploading = true
        
        // In production, this would securely upload the file
        // For now, we'll simulate the upload and create the document record
        
        let document = Document(context: viewContext)
        document.id = UUID()
        document.documentName = documentName
        document.documentType = documentType.rawValue
        document.filePath = fileURL.path
        document.fileSize = Int64(1024 * 1024) // Simulated file size
        document.mimeType = "application/pdf" // Simulated MIME type
        document.uploadDate = Date()
        document.visibilityLevel = visibilityLevel.rawValue
        document.signatureRequired = requiresSignature
        document.signatureStatus = requiresSignature ? "pending" : "not_required"
        document.reviewStatus = "pending"
        document.version = 1
        document.client = client
        document.uploadedBy = currentUser
        
        if !accessRestrictions.isEmpty {
            document.accessRestrictions = Array(accessRestrictions)
        }
        
        if !notes.isEmpty {
            document.setValue(notes, forKey: "notes")
        }
        
        do {
            try viewContext.save()
            isUploading = false
            dismiss()
        } catch {
            print("Error uploading document: \(error)")
            isUploading = false
        }
    }
}

enum DocumentType: String, CaseIterable {
    case legal = "Legal Document"
    case personal = "Personal Document"
    case medical = "Medical Record"
    case program = "Program Document"
    case identification = "Identification"
    case financial = "Financial Document"
    case housing = "Housing Document"
    case other = "Other"
    
    var displayName: String {
        rawValue
    }
}

enum DocumentVisibility: String, CaseIterable {
    case standard = "Standard"
    case confidential = "Confidential"
    case restricted = "Restricted"
    
    var displayName: String {
        rawValue
    }
}

struct AccessRestrictionRow: View {
    let restriction: String
    var isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            
            Text(restriction)
                .font(.brandCaption)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Document Detail View
struct DocumentDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let document: Document
    
    @State private var showingDeleteDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.documentName ?? "Untitled")
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text(document.documentType?.capitalized ?? "Document")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    ArkheIconButton(systemImage: "square.and.arrow.down", style: .primary) {
                        // Download action
                    }
                    
                    ArkheIconButton(systemImage: "square.and.arrow.up", style: .secondary) {
                        // Share action
                    }
                    
                    ArkheIconButton(systemImage: "pencil", style: .outline) {
                        // Edit action
                    }
                }
            }
            .padding()
            .background(document.visibilityLevel == "confidential" ? Color.warningGold.opacity(0.15) : Color.darkCharcoal)
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Document Details")
                    
                    ArkheCard {
                        VStack(spacing: 12) {
                            InfoRow(icon: "doc.fill", title: "Document Type", value: document.documentType?.capitalized ?? "Unknown")
                            InfoRow(icon: "eye.fill", title: "Visibility", value: document.visibilityLevel?.capitalized ?? "Standard")
                            InfoRow(icon: "info.circle", title: "Version", value: "\(document.version)")
                            InfoRow(icon: "ruler", title: "File Size", value: formatFileSize(document.fileSize))
                            
                            if let uploadDate = document.uploadDate {
                                InfoRow(icon: "calendar", title: "Uploaded", value: uploadDate.formatted(date: .long, time: .shortened))
                            }
                            
                            if let expirationDate = document.expirationDate {
                                InfoRow(icon: "calendar.badge.exclamationmark", title: "Expires", value: expirationDate.formatted(date: .long, time: .omitted), iconColor: .warningGold)
                            }
                        }
                    }
                    
                    // Signature Status
                    if document.signatureRequired {
                        SectionHeader(title: "Signature Status")
                        
                        ArkheCard {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: document.signatureStatus == "signed" ? "checkmark.circle.fill" : "clock.fill")
                                        .foregroundColor(document.signatureStatus == "signed" ? .successGreen : .warningGold)
                                        .font(.system(size: 32))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(document.signatureStatus?.capitalized ?? "Unknown")
                                            .font(.brandBodyBold)
                                            .foregroundColor(.textPrimary)
                                        
                                        Text(document.signatureRequired ? "Signature required for this document" : "Signature not required")
                                            .font(.brandCaption)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                                
                                if document.signatureStatus == "pending" {
                                    ArkheButton(title: "Request Signature", style: .primary) {
                                        // Request signature action
                                    }
                                }
                            }
                        }
                    }
                    
                    // Access Control
                    if let restrictions = document.accessRestrictions, !restrictions.isEmpty {
                        SectionHeader(title: "Access Restrictions")
                        
                        ArkheCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("This document is restricted to:")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                ForEach(restrictions, id: \.self) { restriction in
                                    HStack(spacing: 8) {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.warningGold)
                                            .font(.brandTiny)
                                        
                                        Text(restriction.capitalized)
                                            .font(.brandCaption)
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Review Status
                    SectionHeader(title: "Review Status")
                    
                    ArkheCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: document.reviewStatus == "approved" ? "checkmark.circle.fill" : "clock.fill")
                                    .foregroundColor(document.reviewStatus == "approved" ? .successGreen : .warningGold)
                                    .font(.system(size: 32))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.reviewStatus?.capitalized ?? "Unknown")
                                        .font(.brandBodyBold)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("Document review status")
                                        .font(.brandCaption)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                ArkheButton(title: "Approve", style: .primary) {
                                    // Approve action
                                }
                                
                                ArkheButton(title: "Request Changes", style: .secondary) {
                                    // Request changes action
                                }
                            }
                        }
                    }
                    
                    // Version History
                    SectionHeader(title: "Version History")
                    
                    ArkheCard {
                        VStack(spacing: 12) {
                            VersionHistoryRow(version: 1, date: document.uploadDate, uploadedBy: document.uploadedBy?.fullName ?? "System")
                        }
                    }
                    
                    // Actions
                    SectionHeader(title: "Actions")
                    
                    HStack(spacing: 12) {
                        ArkheButton(title: "Download", style: .primary) {
                            // Download action
                        }
                        
                        ArkheButton(title: "Print", style: .secondary) {
                            // Print action
                        }
                        
                        ArkheButton(title: "Delete", style: .danger) {
                            showingDeleteDialog = true
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.deepCharcoal)
        .alert("Delete Document", isPresented: $showingDeleteDialog) {
            Alert(
                title: Text("Delete Document?"),
                message: Text("This action cannot be undone. The document will be permanently deleted."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteDocument()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func deleteDocument() {
        viewContext.delete(document)
        try? viewContext.save()
        dismiss()
    }
}

struct VersionHistoryRow: View {
    let version: Int16
    let date: Date?
    let uploadedBy: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Version \(version)")
                    .font(.brandBodyBold)
                    .foregroundColor(.textPrimary)
                
                if let date = date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.brandTiny)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Text("Uploaded by \(uploadedBy)")
                .font(.brandCaption)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Preview
#Preview {
    ClientDocumentsTab(client: CoreDataController.preview.container.viewContext.fetch(Client.self).first!)
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}
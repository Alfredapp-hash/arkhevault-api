import CoreData
import Foundation

// MARK: - Client Entity Extension
extension Client {
    
    // Computed Properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var activeProgramsCount: Int {
        programEnrollments?.filter { ($0 as? ProgramEnrollment)?.status == "active" }.count ?? 0
    }
    
    var openTasksCount: Int {
        tasks?.filter { ($0 as? Task)?.status == "pending" || ($0 as? Task)?.status == "in_progress" }.count ?? 0
    }
    
    var hasActiveSafetyFlags: Bool {
        safetyFlags?.contains { ($0 as? SafetyFlag)?.isActive == true } ?? false
    }
    
    var activeSafetyFlags: [SafetyFlag] {
        (safetyFlags?.allObjects as? [SafetyFlag])?.filter { $0.isActive } ?? []
    }
    
    var riskLevelEnum: RiskLevelIndicator.RiskLevel {
        RiskLevelIndicator.RiskLevel(rawValue: riskLevel ?? "low") ?? .low
    }
    
    // Helper Methods
    func updateTimestamp() {
        updatedAt = Date()
    }
}

// MARK: - Client CRUD Operations
extension Client {
    
    static func create(in context: NSManagedObjectContext,
                       firstName: String,
                       lastName: String,
                       email: String? = nil,
                       phone: String? = nil) -> Client {
        let client = Client(context: context)
        client.id = UUID()
        client.firstName = firstName
        client.lastName = lastName
        client.contactEmail = email
        client.contactPhone = phone
        client.riskLevel = "low"
        client.veteranStatus = false
        client.confidentialAddress = false
        client.status = "active"
        client.createdAt = Date()
        client.updatedAt = Date()
        
        return client
    }
    
    static func fetchAll(in context: NSManagedObjectContext) -> [Client] {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            #if DEBUG
            print("Error fetching clients: \(error)")
            #endif
            return []
        }
    }
    
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> Client? {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            #if DEBUG
            print("Error fetching client by ID: \(error)")
            #endif
            return nil
        }
    }
    
    static func search(query: String, in context: NSManagedObjectContext) -> [Client] {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.predicate = NSPredicate(
            format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@ OR contactEmail CONTAINS[cd] %@",
            query, query, query
        )
        request.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            #if DEBUG
            print("Error searching clients: \(error)")
            #endif
            return []
        }
    }
}

// MARK: - SafetyFlag Entity Extension
extension SafetyFlag {
    
    static func create(in context: NSManagedObjectContext,
                       client: Client,
                       flagType: String,
                       description: String,
                       severity: String,
                       createdBy: Staff) -> SafetyFlag {
        let flag = SafetyFlag(context: context)
        flag.id = UUID()
        flag.client = client
        flag.flagType = flagType
        flag.descriptionText = description
        flag.severity = severity
        flag.isActive = true
        flag.createdAt = Date()
        flag.createdBy = createdBy
        
        return flag
    }
    
    func resolve(resolvedBy: Staff) {
        isActive = false
        self.resolvedBy = resolvedBy
        resolvedAt = Date()
    }
}

// MARK: - Program Entity Extension
extension Program {
    
    var availableCapacity: Int16 {
        max(0, capacity - currentEnrollment)
    }
    
    var isFull: Bool {
        currentEnrollment >= capacity
    }
    
    static func create(in context: NSManagedObjectContext,
                       name: String,
                       programType: String,
                       capacity: Int16 = 50) -> Program {
        let program = Program(context: context)
        program.id = UUID()
        program.name = name
        program.programType = programType
        program.capacity = capacity
        program.currentEnrollment = 0
        program.status = "active"
        program.createdAt = Date()
        
        return program
    }
    
    static func fetchAll(in context: NSManagedObjectContext) -> [Program] {
        let request: NSFetchRequest<Program> = Program.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            #if DEBUG
            print("Error fetching programs: \(error)")
            #endif
            return []
        }
    }
}

// MARK: - ProgramEnrollment Entity Extension
extension ProgramEnrollment {
    
    var isActive: Bool {
        status == "active"
    }
    
    var isCompleted: Bool {
        status == "completed"
    }
    
    static func create(in context: NSManagedObjectContext,
                       client: Client,
                       program: Program,
                       assignedStaff: Staff,
                       createdBy: Staff) -> ProgramEnrollment {
        let enrollment = ProgramEnrollment(context: context)
        enrollment.id = UUID()
        enrollment.client = client
        enrollment.program = program
        enrollment.assignedStaff = assignedStaff
        enrollment.enrollmentDate = Date()
        enrollment.status = "active"
        enrollment.createdAt = Date()
        enrollment.createdBy = createdBy
        
        // Update program enrollment count
        program.currentEnrollment += 1
        
        return enrollment
    }
    
    func complete(completionDate: Date = Date()) {
        status = "completed"
        actualCompletionDate = completionDate
        
        // Update program enrollment count
        if let program = program {
            program.currentEnrollment = max(0, program.currentEnrollment - 1)
        }
    }
}

// MARK: - CaseNote Entity Extension
extension CaseNote {
    
    static func create(in context: NSManagedObjectContext,
                       client: Client,
                       noteType: String,
                       narrative: String,
                       staff: Staff,
                       programEnrollment: ProgramEnrollment? = nil) -> CaseNote {
        let note = CaseNote(context: context)
        note.id = UUID()
        note.client = client
        note.noteType = noteType
        note.narrative = narrative
        note.staff = staff
        note.programEnrollment = programEnrollment
        note.visibilityLevel = "standard"
        note.supervisorReviewFlag = false
        note.isVoiceGenerated = false
        note.createdAt = Date()
        
        return note
    }
    
    func markAsReviewed(reviewedBy: Staff) {
        supervisorReviewFlag = true
        self.reviewedBy = reviewedBy
        reviewedAt = Date()
    }
}

// MARK: - Task Entity Extension
extension Task {
    
    var isOverdue: Bool {
        if let dueDate = dueDate, status != "completed" {
            return dueDate < Date()
        }
        return false
    }
    
    var priorityEnum: TaskPriority {
        TaskPriority(rawValue: priority ?? "medium") ?? .medium
    }
    
    enum TaskPriority: String {
        case low, medium, high, urgent
    }
    
    static func create(in context: NSManagedObjectContext,
                       taskName: String,
                       client: Client,
                       assignedStaff: Staff,
                       dueDate: Date? = nil,
                       priority: String = "medium",
                       createdBy: Staff) -> Task {
        let task = Task(context: context)
        task.id = UUID()
        task.taskName = taskName
        task.client = client
        task.assignedStaff = assignedStaff
        task.dueDate = dueDate
        task.priority = priority
        task.status = "pending"
        task.autoCreated = false
        task.createdAt = Date()
        task.createdBy = createdBy
        
        return task
    }
    
    func complete(completionDate: Date = Date()) {
        status = "completed"
        self.completionDate = completionDate
    }
    
    static func createAutoTask(in context: NSManagedObjectContext,
                               taskName: String,
                               client: Client,
                               assignedStaff: Staff,
                               triggerEvent: String,
                               dueDate: Date? = nil,
                               priority: String = "medium") -> Task {
        let task = Task(context: context)
        task.id = UUID()
        task.taskName = taskName
        task.client = client
        task.assignedStaff = assignedStaff
        task.dueDate = dueDate
        task.priority = priority
        task.status = "pending"
        task.autoCreated = true
        task.autoTriggerEvent = triggerEvent
        task.createdAt = Date()
        
        return task
    }
}

// MARK: - Staff Entity Extension
extension Staff {
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var isAdmin: Bool {
        role == "super_admin" || role == "executive_director"
    }
    
    static func create(in context: NSManagedObjectContext,
                       email: String,
                       firstName: String,
                       lastName: String,
                       role: String = "case_manager") -> Staff {
        let staff = Staff(context: context)
        staff.id = UUID()
        staff.email = email
        staff.firstName = firstName
        staff.lastName = lastName
        staff.role = role
        staff.status = "active"
        staff.mfaEnabled = false
        
        return staff
    }
    
    static func fetchAll(in context: NSManagedObjectContext) -> [Staff] {
        let request: NSFetchRequest<Staff> = Staff.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            #if DEBUG
            print("Error fetching staff: \(error)")
            #endif
            return []
        }
    }
    
    static func authenticate(email: String, in context: NSManagedObjectContext) -> Staff? {
        let request: NSFetchRequest<Staff> = Staff.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            #if DEBUG
            print("Error authenticating staff: \(error)")
            #endif
            return nil
        }
    }
}
import CoreData
import CloudKit

class CoreDataController: ObservableObject {
    static let shared = CoreDataController()
    
    @Published var container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "ForgedInFireDataModel")
        
        // Configure CloudKit sync (optional - can be disabled)
        // container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        // container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Save context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                #if DEBUG
                print("Failed to save Core Data context: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    // Background context for heavy operations
    func backgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}

// MARK: - Preview Helper for SwiftUI Previews
extension CoreDataController {
    static var preview: CoreDataController = {
        let controller = CoreDataController()
        
        // Add sample data for previews
        let context = controller.container.viewContext
        
        // Sample client
        let client = Client(context: context)
        client.id = UUID()
        client.firstName = "Jane"
        client.lastName = "Doe"
        client.contactEmail = "jane.doe@example.com"
        client.contactPhone = "(555) 123-4567"
        client.riskLevel = "medium"
        client.housingStatus = "Stable"
        client.createdAt = Date()
        client.status = "active"
        
        // Sample program
        let program = Program(context: context)
        program.id = UUID()
        program.name = "Victim Advocacy"
        program.programType = "victim_advocacy"
        program.capacity = 50
        program.currentEnrollment = 25
        program.status = "active"
        program.createdAt = Date()
        
        try? context.save()
        
        return controller
    }()
}
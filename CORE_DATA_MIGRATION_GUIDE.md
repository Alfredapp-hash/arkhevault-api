# Core Data Migration Strategy

## Overview

This document provides a comprehensive strategy for managing Core Data schema migrations in the Arkhe Vault Client Manager macOS application, ensuring smooth transitions between app versions without data loss.

**Project Location:** `/Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVaultClientClientManager/`

---

## Table of Contents

1. [Migration Philosophy](#migration-philosophy)
2. [Current Data Model Overview](#current-data-model-overview)
3. [Migration Types](#migration-types)
4. [Migration Planning](#migration-planning)
5. [Migration Implementation](#migration-implementation)
6. [Testing Strategy](#testing-strategy)
7. [Rollback Procedures](#rollback-procedures)
8. [Best Practices](#best-practices)

---

## Migration Philosophy

### Core Principles

1. **Data Integrity First**
   - Never lose user data
   - Validate data before migration
   - Provide rollback capability

2. **Backward Compatibility**
   - Support at least one previous major version
   - Allow users to upgrade at their own pace
   - Don't force immediate migration

3. **Transparent Communication**
   - Inform users before migration
   - Explain what changes will occur
   - Provide migration progress feedback

4. **Performance Considerations**
   - Minimize migration time
   - Perform migrations in background
   - Don't block user interaction

---

## Current Data Model Overview

### Current Schema Version: Version 1

**Core Entities (15+):**
- Staff (Users)
- Client
- Program
- ProgramEnrollment
- SafetyFlag
- Task
- Appointment
- CaseNote
- Document
- Referral
- SafeHouse
- SafeHousePlacement
- Communication
- Volunteer (uses Staff entity with role)

### Key Relationships

```
Client (1) → (many) ProgramEnrollment → (1) Program
Client (1) → (many) SafetyFlag
Client (1) → (many) Task
Client (1) → (many) Appointment
Client (1) → (many) CaseNote
Client (1) → (many) Document
Client (1) (many) Referral
Client (1) → (many) SafeHousePlacement
Client (1) → (many) Communication
```

---

## Migration Types

### Type 1: Lightweight Migrations (Non-Destructive)

**Examples:**
- Adding new attributes to existing entities
- Adding new entities
- Adding new relationships
- Changing default values
- Adding indexes

**Risk Level:** Low
**Rollback:** Easy (just revert to previous schema)
**User Impact:** Minimal

### Type 2: Heavy Migrations (Destructive)

**Examples:**
- Deleting entities
- Renaming entities
- Changing relationship cardinality
- Changing attribute types
- Merging entities

**Risk Level:** High
**Rollback:** Complex (requires data restoration)
**User Impact:** Significant

### Type 3: Data Migrations

**Examples:**
- Data transformation
- Data validation
- Data deduplication
- Data format changes

**Risk Level:** Medium
**Rollback:** Medium (requires data backup)
**User Impact:** Moderate

---

## Migration Planning

### Step 1: Version Your Data Model

1. **Current Version:** Version 1
2. **Next Version:** Version 2
3. **Increment major version for breaking changes**

### Step 2: Create Migration Plan

For each migration, document:

```markdown
## Migration Plan - Version 2

### Changes
- Add `VolunteerHours` entity
- Add `FieldCorrection` entity
- Add `DocumentExtraction` entity
- Add `Notification` entity
- Add `AnalyticsEvent` entity

### Migration Type
- Lightweight (non-destructive)

### Data Impact
- No data loss
- New entities start empty
- Existing data preserved

### Estimated Time
- Migration execution: < 1 second
- User downtime: None

### Rollback Strategy
- Revert to Version 1 schema
- Delete new entities (empty)
```

### Step 3: Test Migration Locally

1. **Create Test Data**
   - Use sample data to test migration
   - Include edge cases (empty database, large datasets)

2. **Run Migration**
   - Test migration on development machine
   - Verify data integrity
   - Check performance

3. **Validate Results**
   - Verify all data is preserved
   - Check for any data corruption
   - Test all features with migrated data

---

## Migration Implementation

### Core Data Migration Manager

Create a migration manager to handle schema evolution:

```swift
import CoreData
import CloudKit

// MARK: - Migration Manager
class MigrationManager {
    static let shared = MigrationManager()
    
    private init() {}
    
    /// Perform migration if needed
    func performMigrationIfNeeded(context: NSManagedObjectContext) throws {
        let currentModelVersion = getCurrentModelVersion()
        let targetModelVersion = 2 // Increment this for new versions
        
        guard currentModelVersion < targetModelVersion else {
            print("Data model is already at version \(currentModelVersion)")
            return
        }
        
        print("Migrating from version \(currentModelVersion) to \(targetModelVersion)")
        
        for version in currentModelVersion..<targetModelVersion {
            try performMigration(from: version, to: version + 1, context: context)
        }
    }
    
    /// Get current model version
    private func getCurrentModelVersion() -> Int {
        // In production, read from UserDefaults
        return UserDefaults.standard.integer(forKey: "CoreDataModelVersion")
    }
    
    /// Set model version after successful migration
    private func setModelVersion(_ version: Int) {
        UserDefaults.standard.set(version, forKey: "CoreDataModelVersion")
    }
    
    /// Perform specific migration
    private func performMigration(from: Int, to: Int, context: NSManagedObjectContext) throws {
        switch (from, to) {
        case (1, 2):
            try migrateV1ToV2(context: context)
        case (2, 3):
            try migrateV2ToV3(context: context)
        default:
            fatalError("Unsupported migration from \(from) to \(to)")
        }
        
        setModelVersion(to)
    }
    
    /// Migration from Version 1 to Version 2
    private func migrateV1ToV2(context: NSManagedObjectContext) throws {
        // Add new entities
        createVolunteerHoursEntity(context: context)
        createFieldCorrectionEntity(context: context)
        createDocumentExtractionEntity(context: context)
        createNotificationEntity(context: context)
        createAnalyticsEventEntity(context: context)
        
        // Add new attributes to existing entities
        addNewAttributesToExistingEntities(context: context)
        
        // Save changes
        try context.save()
        
        print("Migration V1→V2 completed successfully")
    }
    
    /// Migration from Version 2 to Version 3 (example)
    private func migrateV2ToV3(context: NSManagedObjectContext) throws {
        // Future migration logic
        print("Migration V2→V3 - no changes needed")
    }
    
    // MARK: - Entity Creation Helpers
    
    private func createVolunteerHoursEntity(context: NSManagedObjectContext) {
        let entityDescription = NSEntityDescription()
        entityDescription.name = "VolunteerHours"
        entityDescription.managedObjectClassName = "VolunteerHours"
        
        // Add attributes
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false
        entityDescription.properties = ["id": idAttribute]
        
        // Add to model
        let model = context.persistentStoreCoordinator?.managedObjectModel
        model?.entities.append(entityDescription)
    }
    
    // ... similar methods for other entities
}
```

### Lightweight Migration Example

```swift
// MARK: - Lightweight Migration Policy
class LightweightMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        
        // Set default values for new attributes
        if let destinationInstance = mapping.destinationInstances.first as? NSManagedObject {
            destinationInstance.setValue(false, forKey: "syncWithCalendar")
            destinationInstance.setValue(Date(), forKey: "createdAt")
        }
    }
}
```

---

## Testing Strategy

### Unit Testing Migrations

```swift
import XCTest
import CoreData

class MigrationTests: XCTestCase {
    var mockPersistentContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        mockPersistentContainer = NSPersistentContainer(name: "TestModel")
        let description = mockPersistentContainer.persistentStoreDescriptions.first
        description?.url = URL(fileURLWithPath: NSTemporaryDirectoryDirectory().appendingPathComponent("TestModel.sqlite"))
    }
    
    func testMigrationV1ToV2() throws {
        // Create V1 model
        let v1Model = NSManagedObjectModel(contentsOf: loadV1Model())
        
        // Create V2 model
        let v2Model = NSManagedObjectModel(contentsOf: loadV2Model())
        
        // Perform migration
        let mappingModel = NSMappingModel(from: v1Model, to: v2Model)
        let migration = LightweightMigrationPolicy()
        migration.createDestinationInstances(
            forSource: testClient,
            in: mappingModel,
            manager: migrationManager
        )
        
        // Verify migration
        XCTAssertNotNil(testClient.value(forKey: "syncWithCalendar"))
    }
}
```

### Integration Testing

1. **Test with Real Data**
   - Use production database copy
   - Perform migration
   - Verify all data is preserved
   - Check for data corruption

2. **Test on Different macOS Versions**
   - Test on macOS 14, 15, 16
   - Verify Core Data compatibility
   - Check for API differences

3. **Performance Testing**
   - Time migration with large datasets
   - Measure memory usage during migration
   - Verify no UI blocking

---

## Rollback Procedures

### Automatic Rollback

If migration fails, automatically:

1. Delete new Core Data store
2. Restore from backup
3. Revert to previous schema version
4. Notify user of failure

### Manual Rollback

If automatic rollback fails:

1. **Stop the App**
   - Quit the application
   - Prevent further access to prevent corruption

2. **Restore from Backup**
   - Restore database from Time Machine or cloud backup
   - Verify backup integrity

3. **Revert Schema**
   - Revert to previous Xcode Data Model version
   - Clean build folder
   - Rebuild app

4. **Notify Users**
   - Inform users of rollback
   - Explain what happened
   - Provide timeline for fix

---

## Best Practices

### Data Backup Before Migration

1. **Automatic Backup**
   - Back up database before migration
   - Store in multiple locations (local + cloud)
   - Verify backup integrity

2. **User Notification**
   - Warn users before migration
   - Provide estimated time
   - Allow cancellation

3. **Backup Verification**
   - Verify backup was created successfully
   - Check backup file size
   - Test backup restoration

### Migration Execution

1. **Background Execution**
   - Perform migrations in background
   - Show progress indicator
   - Don't block user interface

2. **Progress Feedback**
   - Show migration progress percentage
   - Display current step
   - Estimated time remaining

3. **Error Handling**
   - Catch migration errors gracefully
   - Provide clear error messages
   - Offer retry option

### Post-Migration Validation

1. **Data Integrity Checks**
   - Verify all entities exist
   - Check relationships are intact
   - Validate data types

2. **Feature Testing**
   - Test all features with migrated data
   - Verify CRUD operations work
   - Check for performance issues

3. **User Acceptance**
   - Ask users to validate their data
   - Collect feedback
   - Address any issues

---

## Version Control Strategy

### Model Versioning

1. **Current Model:** `ArkheVaultDataModel.xcdatamodeld`
2. **Versioning:** Xcode automatically versions when you make changes
3. **Naming Convention:** Keep the same name, let Xcode handle versioning

### Migration File Naming

When creating migration policies, use descriptive names:
- `V1ToV2MigrationPolicy.swift`
- `V2ToV3MigrationPolicy.swift`
- `V3ToV4MigrationPolicy.swift`

---

## Common Migration Scenarios

### Scenario 1: Adding a New Attribute

**Example:** Add `syncWithCalendar` boolean to Client entity

```swift
// In V2ToV3 migration
func addSyncWithCalendarToClient(context: NSManagedObjectContext) {
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Client")
    
    let clients = try? context.fetch(fetchRequest)
    for client in clients ?? [] {
        client.setValue(false, forKey: "syncWithCalendar")
    }
}
```

### Scenario 2: Adding a New Entity

**Example:** Add `Notification` entity

```swift
// Create entity in migration
func createNotificationEntity(context: NSManagedObjectModel) {
    let notificationEntity = NSEntityDescription()
    notificationEntity.name = "Notification"
    notificationEntity.managedObjectClassName = "Notification"
    
    // Add attributes
    notificationEntity.properties = [
        "id": NSAttributeDescription(name: "id", attributeType: .UUIDAttributeType, isOptional: false),
        "title": NSAttributeDescription(name: "title", attributeType: .stringAttributeType, isOptional: false),
        "message": NSAttributeDescription(name: "message", attributeType: .stringAttributeType, isOptional: false),
        "type": NSAttributeDescription(name: "type", attributeType: .stringAttributeType, isOptional: false),
        "createdAt": NSAttributeDescription(name: "createdAt", attributeType: .dateAttributeType, isOptional: false),
        "isRead": NSAttributeDescription(name: "isRead", attributeType: .booleanAttributeType, isOptional: false)
    ]
    
    // Add to model
    context.persistentStoreCoordinator?.managedObjectModel?.entities.append(notificationEntity)
}
```

### Scenario 3: Changing Attribute Type

**Example:** Change `phoneNumber` from String to specialized Phone Number type

**Approach:**
- Keep as String for simplicity
- Add validation on save
- Format for display only

**Reasoning:** String is more flexible and avoids data loss

---

## Migration Checklist

### Pre-Migration

- [ ] Document migration plan
- [ ] Create migration policy
- [ ] Test migration with sample data
- [ ] Create database backup
- [ ] Notify users of upcoming migration
- [ ] Schedule maintenance window

### During Migration

- [ ] Verify backup completed
- [ ] Execute migration in background
- [ ] Show progress to users
- [ ] Monitor for errors
- [ ] Validate data integrity

### Post-Migration

- [ ] Verify all data preserved
- [ ] Test all features
- [ Check for performance issues
- [ ] Collect user feedback
- [ ] Document any issues
- [ ] Update documentation

---

## Rollback Checklist

### If Migration Fails

- [ ] Stop the application
- [ ] Restore from backup
- [ ] Revert schema version
- [ ] Rebuild application
- [ ] Notify users
- [ ] Document failure
- [ ] Fix issue
- - Plan retry

---

## Monitoring

### Migration Metrics

Track the following metrics for each migration:

- **Success Rate:** Percentage of successful migrations
- **Failure Rate:** Percentage of failed migrations
- **Rollback Rate:** Percentage of migrations that required rollback
- **Time Taken:** Average migration time
- **User Satisfaction:** User feedback on migration experience

### Alerts

Set up alerts for:
- Migration failures
- High rollback rates
- Long migration times
- Data integrity issues

---

## Advanced Topics

### CloudKit Integration

If you plan to add iCloud sync in the future:

1. Use CloudKit with Core Data
2. Implement schema mapping
3. Handle conflicts
4. Test cloud migrations separately

### Migration Testing

1. **Unit Tests**
   - Test each migration policy
   - Test edge cases
   - Verify data transformation

2. **Integration Tests**
   - Test migration with real data
   - Test on different macOS versions
   - Test with large datasets

3. UI Tests
   - Test migration UI flow
   - Test user notifications
   - Test progress indicators

---

## Troubleshooting

### Common Issues

#### Issue: Migration fails with "Migration failed"

**Solutions:**
1. Check model version numbers
2. Verify migration policy is registered
3. Check for naming conflicts
4. Review Core Data error logs

#### Issue: Data loss after migration

**Solutions:**
1. Immediately stop the app
2. Restore from backup
3. Investigate migration code
4. Fix and retry

#### Issue: Performance degradation after migration

**Solutions:1. Check for unnecessary data loading
2. Add indexes if needed
3. Optimize fetch requests
4. Review migration code for inefficiencies

---

## Documentation

### Update Documentation After Each Migration

1. **Update IMPLEMENTATION_SUMMARY.md**
   - Add migration entry
   - Document what changed
   - Note version number

2. **Update DEPLOYMENT_GUIDE.md**
   - Add migration instructions
   - Update testing checklist
   - Document rollback procedures

3. **Create Migration Release Notes**
   - Document what changed
   - Explain impact on users
   - Provide upgrade instructions

---

## Conclusion

The Arkhe Vault Client Manager uses Core Data with a well-structured schema. By following this migration strategy, you can:

- ✅ Safely evolve the data model over time
- ✅ Maintain data integrity
- ✅ Provide rollback capability
- ✅ Minimize user disruption
- ✅ Track migration success

**Current Status:** Ready for Version 2 migration (when needed)

**Migration Risk:** Low - Current schema is stable and well-designed

---

**Document Version:** 1.0
**Last Updated:** 2024
**Status:** Migration Strategy Defined
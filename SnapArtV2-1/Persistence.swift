import Foundation
import CoreData

// This is a compatibility file to satisfy project references
// It should be removed from the project file in Xcode

// Compatibility layer for old PersistenceController references
struct PersistenceController {
    static let shared = PersistenceController()
    
    @MainActor
    static let preview: PersistenceController = {
        return PersistenceController(inMemory: true)
    }()
    
    var container: NSPersistentContainer {
        return CoreDataManager.shared.persistentContainer
    }
    
    init(inMemory: Bool = false) {
        // Use CoreDataManager instead
    }
}

// Placeholder for Item entity - only used for compilation
class Item: NSManagedObject {
    @NSManaged var timestamp: Date?
    
    static func create(in context: NSManagedObjectContext) -> Item {
        let entity = NSEntityDescription.entity(forEntityName: "User", in: context)!
        let item = NSManagedObject(entity: entity, insertInto: nil) as! Item
        item.timestamp = Date()
        return item
    }
} 
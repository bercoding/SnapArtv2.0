import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    // Add a preview instance for SwiftUI previews
    @MainActor
    static let preview: CoreDataManager = {
        let instance = CoreDataManager(inMemory: true)
        // Add sample data here if needed
        return instance
    }()
    
    private init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "SnapArtV2-0")
        
        if inMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        persistentContainer.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    let persistentContainer: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving support
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    // Create
    func create<T: NSManagedObject>(_ object: T.Type) -> T {
        let entityName = String(describing: object)
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        return T(entity: entity, insertInto: context)
    }
    
    // Read
    func fetch<T: NSManagedObject>(_ object: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [T] {
        let entityName = String(describing: object)
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching \(entityName): \(error)")
            return []
        }
    }
    
    // Read single object
    func fetchOne<T: NSManagedObject>(_ object: T.Type, predicate: NSPredicate) -> T? {
        let entityName = String(describing: object)
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching single \(entityName): \(error)")
            return nil
        }
    }
    
    // Update happens automatically when you modify an object and save context
    
    // Delete
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        saveContext()
    }
    
    // Delete all entities of a specific type
    func deleteAll<T: NSManagedObject>(_ object: T.Type) {
        let entityName = String(describing: object)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: context)
            saveContext()
        } catch {
            print("Error deleting all \(entityName): \(error)")
        }
    }
    
    // Check if object exists
    func exists<T: NSManagedObject>(_ object: T.Type, predicate: NSPredicate) -> Bool {
        let entityName = String(describing: object)
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking if \(entityName) exists: \(error)")
            return false
        }
    }
    
    // MARK: - SavedImage Operations
    
    // Fetch all saved images
    func fetchSavedImages() throws -> [SavedImage] {
        let context = persistentContainer.viewContext // Sử dụng viewContext cho tính nhất quán UI
        var results: [SavedImage] = []
        var fetchError: Error? = nil
        
        context.performAndWait { // Perform on context's thread
            do {
                let fetchRequest: NSFetchRequest<SavedImage> = SavedImage.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                results = try context.fetch(fetchRequest)
                print("ℹ️ CoreDataManager: fetchSavedImages() tìm thấy \(results.count) ảnh.")
            } catch {
                fetchError = error
            }
        }
        
        if let error = fetchError {
            throw error
        }
        return results
    }
    
    // Fetch a single saved image by ID
    func fetchSavedImage(withId id: UUID) throws -> SavedImage? {
        let context = persistentContainer.newBackgroundContext()
        var result: SavedImage? = nil
        var fetchError: Error? = nil
        
        context.performAndWait {
            do {
                let predicate = NSPredicate(format: "id == %@", id as CVarArg)
                let fetchRequest: NSFetchRequest<SavedImage> = SavedImage.fetchRequest()
                fetchRequest.predicate = predicate
                fetchRequest.fetchLimit = 1
                result = try context.fetch(fetchRequest).first
            } catch {
                fetchError = error
            }
        }
        
        if let error = fetchError {
            throw error
        }
        return result
    }
    
    // Save a new image with custom ID and createdAt (for Firebase sync and new local)
    func saveSavedImage(imageData: Data, id: UUID, createdAt: Date, metadata: Data? = nil) throws -> SavedImage {
        let context = persistentContainer.newBackgroundContext() // Use a new background context
        var savedImage: SavedImage! = nil
        var saveError: Error? = nil
        
        context.performAndWait { // Perform operations on the context's private queue
            do {
                let predicate = NSPredicate(format: "id == %@", id as CVarArg)
                if let existingImage = self.fetchOne(SavedImage.self, predicate: predicate, in: context) { // Pass context to fetchOne
                    // Nếu đã tồn tại, cập nhật
                    existingImage.imageData = imageData
                    existingImage.metadata = metadata
                    existingImage.createdAt = createdAt
                    try context.save()
                    savedImage = existingImage
                    print("✅ CoreDataManager: Đã cập nhật ảnh SavedImage ID: \(savedImage.id!) trong context. Số lượng đối tượng trong context: \(context.registeredObjects.count).")
                } else {
                    // Nếu chưa tồn tại, tạo mới
                    let newImage = SavedImage(context: context)
                    newImage.id = id
                    newImage.imageData = imageData
                    newImage.createdAt = createdAt
                    newImage.metadata = metadata
                    try context.save()
                    savedImage = newImage
                    print("✅ CoreDataManager: Đã lưu ảnh SavedImage ID: \(savedImage.id!) mới vào context. Số lượng đối tượng trong context: \(context.registeredObjects.count).")
                }
            } catch {
                saveError = error
            }
        }
        
        if let error = saveError {
            throw error
        }
        return savedImage
    }
    
    // Delete a saved image by ID
    func deleteSavedImage(withId id: UUID) throws {
        let context = persistentContainer.newBackgroundContext()
        var deleteError: Error? = nil
        
        context.performAndWait { // Perform on context's thread
            do {
                let predicate = NSPredicate(format: "id == %@", id as CVarArg)
                if let savedImage = self.fetchOne(SavedImage.self, predicate: predicate, in: context) { // Pass context to fetchOne
                    context.delete(savedImage)
                    try context.save()
                } else {
                    deleteError = NSError(domain: "CoreDataManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy ảnh với ID đã cho"])
                }
            } catch {
                deleteError = error
            }
        }
        
        if let error = deleteError {
            throw error
        }
    }
    
    // Delete all saved images
    func deleteAllSavedImages() throws {
        let context = persistentContainer.newBackgroundContext()
        var deleteError: Error? = nil
        
        context.performAndWait { // Perform on context's thread
            do {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SavedImage.fetchRequest()
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                batchDeleteRequest.resultType = .resultTypeObjectIDs // Get ObjectIDs for merging
                
                let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    // Merge changes back to the main context to update UI
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [persistentContainer.viewContext])
                }
                // No need to call context.save() for batch delete
            } catch {
                deleteError = error
            }
        }
        
        if let error = deleteError {
            throw error
        }
    }
    
    // Helper for fetching a single object with a specific context
    private func fetchOne<T: NSManagedObject>(_ object: T.Type, predicate: NSPredicate, in context: NSManagedObjectContext) -> T? {
        let entityName = String(describing: object)
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching single \(entityName) in private context: \(error)")
            return nil
        }
    }
} 
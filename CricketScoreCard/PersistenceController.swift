import CoreData

/// Core Data stack (SQLite on disk + in‑memory helper for previews)
enum PersistenceController {
    
    /// disk‑backed container used by the running app
    static let shared: NSPersistentContainer = {
        let model = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let container = NSPersistentContainer(name: "CricketScorecard", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Store load error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    /// in‑memory context for SwiftUI previews
    static let previewContext: NSManagedObjectContext = {
        let model = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let container = NSPersistentContainer(name: "Preview", managedObjectModel: model)
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Preview store error: \(error)") }
        }
        return container.viewContext
    }()
}

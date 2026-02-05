//
//  PreviewHelpers.swift
//  CricketScorecard
//

import CoreData

enum PreviewHelpers {
    /// single in‑memory context for all previews
    static var previewContext: NSManagedObjectContext = {
        let model = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let container = NSPersistentContainer(name: "Preview", managedObjectModel: model)
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Preview store error: \(error)") }
        }
        return container.viewContext
    }()
    
    /// generates a minimal sample match (with teams) for preview
    static func sampleMatch(in ctx: NSManagedObjectContext, completed: Bool) -> Match {
        let match = Match(context: ctx)
        match.matchID = UUID()
        match.dateStarted = Date()
        match.isCompleted = completed
        match.tossResult = "Team A"
        
        let teamA = Team(context: ctx)
        teamA.teamName = "Team A"
        teamA.match = match
        
        let teamB = Team(context: ctx)
        teamB.teamName = "Team B"
        teamB.match = match
        
        match.teams = [teamA, teamB] as NSSet
        try? ctx.save()
        return match
    }
}

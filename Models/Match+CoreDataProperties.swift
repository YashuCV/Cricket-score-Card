//
//  Match+CoreDataProperties.swift
//  CricketScoreCard
//
//  Created by Roopa Pachipulusu on 07/03/25.
//
//

import Foundation
import CoreData


extension Match {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Match> {
        return NSFetchRequest<Match>(entityName: "Match")
    }

    @NSManaged public var dateStarted: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var matchID: UUID?
    @NSManaged public var tossResult: String?
    @NSManaged public var overs: NSSet?
    @NSManaged public var teams: NSSet?
    @NSManaged public var user: User?

}

// MARK: Generated accessors for overs
extension Match {

    @objc(addOversObject:)
    @NSManaged public func addToOvers(_ value: Over)

    @objc(removeOversObject:)
    @NSManaged public func removeFromOvers(_ value: Over)

    @objc(addOvers:)
    @NSManaged public func addToOvers(_ values: NSSet)

    @objc(removeOvers:)
    @NSManaged public func removeFromOvers(_ values: NSSet)

}

// MARK: Generated accessors for teams
extension Match {

    @objc(addTeamsObject:)
    @NSManaged public func addToTeams(_ value: Team)

    @objc(removeTeamsObject:)
    @NSManaged public func removeFromTeams(_ value: Team)

    @objc(addTeams:)
    @NSManaged public func addToTeams(_ values: NSSet)

    @objc(removeTeams:)
    @NSManaged public func removeFromTeams(_ values: NSSet)

}

extension Match : Identifiable {

}

//
//  Team+CoreDataProperties.swift
//  CricketScoreCard
//
//  Created by Roopa Pachipulusu on 07/03/25.
//
//

import Foundation
import CoreData


extension Team {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Team> {
        return NSFetchRequest<Team>(entityName: "Team")
    }

    @NSManaged public var teamID: UUID?
    @NSManaged public var teamName: String?
    @NSManaged public var match: Match?
    @NSManaged public var players: NSSet?

}

// MARK: Generated accessors for players
extension Team {

    @objc(addPlayersObject:)
    @NSManaged public func addToPlayers(_ value: Player)

    @objc(removePlayersObject:)
    @NSManaged public func removeFromPlayers(_ value: Player)

    @objc(addPlayers:)
    @NSManaged public func addToPlayers(_ values: NSSet)

    @objc(removePlayers:)
    @NSManaged public func removeFromPlayers(_ values: NSSet)

}

extension Team : Identifiable {

}

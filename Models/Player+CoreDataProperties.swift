//
//  Player+CoreDataProperties.swift
//  CricketScoreCard
//
//  Created by Roopa Pachipulusu on 07/03/25.
//
//

import Foundation
import CoreData


extension Player {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Player> {
        return NSFetchRequest<Player>(entityName: "Player")
    }

    @NSManaged public var playerID: UUID?
    @NSManaged public var playerName: String?
    @NSManaged public var team: Team?

}

extension Player : Identifiable {

}

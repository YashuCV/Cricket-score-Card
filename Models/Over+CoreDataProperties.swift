//
//  Over+CoreDataProperties.swift
//  CricketScoreCard
//
//  Created by Roopa Pachipulusu on 07/03/25.
//
//

import Foundation
import CoreData


extension Over {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Over> {
        return NSFetchRequest<Over>(entityName: "Over")
    }

    @NSManaged public var endDate: Date?
    @NSManaged public var inningsNumber: Int16
    @NSManaged public var isComplete: Bool
    @NSManaged public var overID: UUID?
    @NSManaged public var overNumber: Int16
    @NSManaged public var scoreAtOverEnd: Int16
    @NSManaged public var startTime: Date?
    @NSManaged public var ballEvents: NSSet?
    @NSManaged public var bowler: Player?
    @NSManaged public var match: Match?

}

// MARK: Generated accessors for ballEvents
extension Over {

    @objc(addBallEventsObject:)
    @NSManaged public func addToBallEvents(_ value: BallEvent)

    @objc(removeBallEventsObject:)
    @NSManaged public func removeFromBallEvents(_ value: BallEvent)

    @objc(addBallEvents:)
    @NSManaged public func addToBallEvents(_ values: NSSet)

    @objc(removeBallEvents:)
    @NSManaged public func removeFromBallEvents(_ values: NSSet)

}

extension Over : Identifiable {

}

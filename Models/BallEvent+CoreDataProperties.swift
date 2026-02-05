//
//  BallEvent+CoreDataProperties.swift
//  CricketScoreCard
//
//  Created by Roopa Pachipulusu on 07/03/25.
//
//

import Foundation
import CoreData


extension BallEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BallEvent> {
        return NSFetchRequest<BallEvent>(entityName: "BallEvent")
    }

    @NSManaged public var ballID: UUID?
    @NSManaged public var ballNumber: Int16
    @NSManaged public var isNoBall: Bool
    @NSManaged public var isWicket: Bool
    @NSManaged public var isWide: Bool
    @NSManaged public var runs: Int16
    @NSManaged public var timestamp: Date?
    @NSManaged public var bowler: Player?
    @NSManaged public var over: Over?
    @NSManaged public var striker: Player?

}

extension BallEvent : Identifiable {

}

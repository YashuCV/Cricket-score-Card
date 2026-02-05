//
//  User+CoreDataProperties.swift
//  CricketScoreCard
//
//  Created by Roopa Pachipulusu on 07/03/25.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var password: String?
    @NSManaged public var userID: UUID?
    @NSManaged public var username: String?
    @NSManaged public var matches: NSSet?

}

// MARK: Generated accessors for matches
extension User {

    @objc(addMatchesObject:)
    @NSManaged public func addToMatches(_ value: Match)

    @objc(removeMatchesObject:)
    @NSManaged public func removeFromMatches(_ value: Match)

    @objc(addMatches:)
    @NSManaged public func addToMatches(_ values: NSSet)

    @objc(removeMatches:)
    @NSManaged public func removeFromMatches(_ values: NSSet)

}

extension User : Identifiable {

}

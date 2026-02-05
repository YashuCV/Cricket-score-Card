//
//  CricketDataRepository.swift
//  CricketScorecard
//

import CoreData
import Foundation

/// Global façade for all Core Data operations used by the app.
/// Call `useContext(_:)` ONCE (e.g. right after your persistent‑store loads) to give the
/// repository its live `NSManagedObjectContext`.
final class CricketDataRepository {
    
    // MARK: – Singleton
    
    
    static let shared = CricketDataRepository()
    private init() {}
    
    // MARK: – Context injection
    
    private static var _ctx: NSManagedObjectContext?
    
    /// Provide the app’s `NSPersistentContainer.viewContext`.
    func useContext(_ ctx: NSManagedObjectContext) {
        CricketDataRepository._ctx = ctx
    }
    
    /// All repo calls crash fast if the context hasn’t been supplied.
    private var context: NSManagedObjectContext {
        guard let c = CricketDataRepository._ctx else {
            fatalError("CricketDataRepository: call useContext(_:) with a viewContext before use")
        }
        return c
    }
    

    var viewContext: NSManagedObjectContext { context }

    // MARK: – User
    
    @discardableResult
    func createUser(username: String, password: String) -> User {
        let u = User(context: context)
        u.userID   = UUID()
        u.username = username
        u.password = password
        saveContext()
        return u
    }
    
    // MARK: – Match / teams / players
    
    @discardableResult
    func createMatch(for user: User, tossResult: String? = nil) -> Match {
        let m = Match(context: context)
        m.matchID     = UUID()
        m.dateStarted = Date()
        m.isCompleted = false
        m.tossResult  = tossResult
        m.user        = user
        saveContext()
        return m
    }
    
    @discardableResult
    func createTeam(match: Match, teamName: String) -> Team {
        let t = Team(context: context)
        t.teamID   = UUID()
        t.teamName = teamName
        t.match    = match
        match.addToTeams(t)
        saveContext()
        return t
    }
    
    @discardableResult
    func createPlayer(team: Team, name: String) -> Player {
        let p = Player(context: context)
        p.playerID   = UUID()
        p.playerName = name
        p.team       = team
        team.addToPlayers(p)
        saveContext()
        return p
    }
    
    // MARK: – Overs & balls
    
    @discardableResult
    func createOver(match: Match,
                    overNumber: Int16,
                    inningsNumber: Int16,
                    bowler: Player? = nil,
                    startTime: Date = Date()) -> Over {
        let o = Over(context: context)
        o.overID        = UUID()
        o.overNumber    = overNumber
        o.inningsNumber = inningsNumber
        o.isComplete    = false
        o.scoreAtOverEnd = 0
        o.startTime      = startTime
        o.match          = match
        o.bowler         = bowler
        saveContext()
        return o
    }
    
    @discardableResult
    func recordBall(in over: Over,
                    ballNumber: Int16,
                    striker: Player?,
                    bowler: Player?,
                    runs: Int16,
                    isWide: Bool,
                    isNoBall: Bool,
                    isWicket: Bool) -> BallEvent {
        let b = BallEvent(context: context)
        b.ballID    = UUID()
        b.ballNumber = ballNumber
        b.runs      = runs
        b.isWide    = isWide
        b.isNoBall  = isNoBall
        b.isWicket  = isWicket
        b.timestamp = Date()
        b.over      = over
        b.striker   = striker
        b.bowler    = bowler
        saveContext()
        return b
    }
    
    func completeOver(_ over: Over, scoreAtOverEnd: Int16, endDate: Date = Date()) {
        over.isComplete    = true
        over.scoreAtOverEnd = scoreAtOverEnd
        over.endDate        = endDate
        saveContext()
    }
    
    func completeMatch(_ match: Match) {
        match.isCompleted = true
        saveContext()
    }
    
    // MARK: – Queries / stats
    
    func fetchOvers(for match: Match, innings: Int) -> [Over] {
        let req: NSFetchRequest<Over> = Over.fetchRequest()
        req.predicate = NSPredicate(format: "match == %@ AND inningsNumber == %d", match, innings)
        req.sortDescriptors = [NSSortDescriptor(key: "overNumber", ascending: true)]
        return (try? context.fetch(req)) ?? []
    }
    
    func fetchBalls(for over: Over) -> [BallEvent] {
        let req: NSFetchRequest<BallEvent> = BallEvent.fetchRequest()
        req.predicate = NSPredicate(format: "over == %@", over)
        req.sortDescriptors = [NSSortDescriptor(key: "ballNumber", ascending: true)]
        return (try? context.fetch(req)) ?? []
    }
    
    func fetchRunsFor(player: Player, in match: Match, innings: Int? = nil) -> Int {
        var total = 0
        let overs = oversFor(match: match, innings: innings)
        for o in overs {
            for b in fetchBalls(for: o) where b.striker == player {
                if b.isWide || b.isNoBall { total += 1 }
                total += Int(b.runs)
            }
        }
        return total
    }
    
    func fetchWicketsFor(bowler: Player, in match: Match, innings: Int? = nil) -> Int {
        var wickets = 0
        let overs = oversFor(match: match, innings: innings)
        for o in overs {
            for b in fetchBalls(for: o) where b.isWicket && b.bowler == bowler {
                wickets += 1
            }
        }
        return wickets
    }
    
    func fetchTotalExtras(in match: Match, innings: Int? = nil) -> Int {
        var extras = 0
        let overs = oversFor(match: match, innings: innings)
        for o in overs {
            for b in fetchBalls(for: o) where b.isWide || b.isNoBall {
                extras += 1
            }
        }
        return extras
    }
    
    func calculateScore(in match: Match, innings: Int? = nil) -> Int {
        var score = 0
        let overs = oversFor(match: match, innings: innings)
        for o in overs {
            for b in fetchBalls(for: o) {
                if b.isWide || b.isNoBall { score += 1 }
                score += Int(b.runs)
            }
        }
        return score
    }
    
    func fetchTopBatsman(in match: Match, innings: Int? = nil) -> Player? {
        let players = allPlayers(in: match)
        return players.max { fetchRunsFor(player: $0, in: match, innings: innings)
                           < fetchRunsFor(player: $1, in: match, innings: innings) }
    }
    
    func fetchTopBowler(in match: Match, innings: Int? = nil) -> Player? {
        let players = allPlayers(in: match)
        return players.max { fetchWicketsFor(bowler: $0, in: match, innings: innings)
                           < fetchWicketsFor(bowler: $1, in: match, innings: innings) }
    }
    
    // MARK: – Demo / reset helpers
    
    /// Clears **all** matches (cascade deletes teams, players, balls) and seeds three random demos.
    @discardableResult
    func resetAndSeedDemoData() -> [Match] {
        // delete existing
        let fetch: NSFetchRequest<NSFetchRequestResult> = Match.fetchRequest()
        _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: fetch))
        saveContext()
        
        // ensure demo user
        let demoUser: User = {
            let r: NSFetchRequest<User> = User.fetchRequest()
            if let u = try? context.fetch(r).first { return u }
            return createUser(username: "demo", password: "demo")
        }()
        
        var seeded: [Match] = []
        for idx in 1...3 {
            let m = createMatch(for: demoUser, tossResult: idx % 2 == 0 ? "Team B" : "Team A")
            let teamA = createTeam(match: m, teamName: "Team A")
            let teamB = createTeam(match: m, teamName: "Team B")
            (1...11).forEach { _ = createPlayer(team: teamA, name: "A‑P\($0)") }
            (1...11).forEach { _ = createPlayer(team: teamB, name: "B‑P\($0)") }
            
            for innings in 1...2 {
                for o in 1...3 {
                    let over = createOver(match: m,
                                          overNumber: Int16(o),
                                          inningsNumber: Int16(innings))
                    for b in 1...6 {
                        let r = Int16(Int.random(in: 0...4))
                        _ = recordBall(in: over,
                                       ballNumber: Int16(b),
                                       striker: nil,
                                       bowler: nil,
                                       runs: r,
                                       isWide: false,
                                       isNoBall: false,
                                       isWicket: Bool.random() && r == 0)
                    }
                    completeOver(over, scoreAtOverEnd: Int16(calculateScore(in: m, innings: innings)))
                }
            }
            completeMatch(m)
            seeded.append(m)
        }
        saveContext()
        return seeded
    }
    
    // MARK: – Private helpers
    
    private func oversFor(match: Match, innings: Int?) -> [Over] {
        let req: NSFetchRequest<Over> = Over.fetchRequest()
        if let i = innings {
            req.predicate = NSPredicate(format: "match == %@ AND inningsNumber == %d", match, i)
        } else {
            req.predicate = NSPredicate(format: "match == %@", match)
        }
        return (try? context.fetch(req)) ?? []
    }
    
    private func allPlayers(in match: Match) -> [Player] {
        let req: NSFetchRequest<Player> = Player.fetchRequest()
        req.predicate = NSPredicate(format: "team.match == %@", match)
        return (try? context.fetch(req)) ?? []
    }
    
    private func saveContext() {
        do { try context.save() }
        catch { context.rollback() }
    }
    
    // MARK: – Delete
    
    /// Removes a completed match and (because of cascade rules) its teams, players, overs, balls, etc.
    func deleteMatch(_ match: Match) {
        context.delete(match)
        saveContext()
    }
    
    // MARK: – Auth helpers
    func fetchUser(username: String) -> User? {
        let req: NSFetchRequest<User> = User.fetchRequest()
        req.predicate = NSPredicate(format: "username == %@", username)
        return (try? context.fetch(req).first)
    }

    /// true if a row exists whose username **and** password match (plain-text for now)
    func validateUser(username: String, password: String) -> Bool {
        guard let u = fetchUser(username: username) else { return false }
        return u.password == password
    }

    /// Number of completed matches for the given user.
    func completedMatchesCount(for user: User) -> Int {
        let req: NSFetchRequest<Match> = Match.fetchRequest()
        req.predicate = NSPredicate(format: "user == %@ AND isCompleted == YES", user)
        return (try? context.count(for: req)) ?? 0
    }
    

}

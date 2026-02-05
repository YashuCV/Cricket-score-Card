func sampleUsage() {
    let user = CricketDataRepository.shared.createUser(username: "demoUser", password: "123")
    let match = CricketDataRepository.shared.createMatch(for: user, tossResult: "Team A won toss and chose to bat")
    
    let teamA = CricketDataRepository.shared.createTeam(match: match, teamName: "Team A")
    let teamB = CricketDataRepository.shared.createTeam(match: match, teamName: "Team B")
    
    var teamAPlayers: [Player] = []
    var teamBPlayers: [Player] = []
    for i in 1...6 {
        teamAPlayers.append(CricketDataRepository.shared.createPlayer(team: teamA, name: "A\(i)"))
        teamBPlayers.append(CricketDataRepository.shared.createPlayer(team: teamB, name: "B\(i)"))
    }
    
    let over1 = CricketDataRepository.shared.createOver(match: match, overNumber: 1, inningsNumber: 1, bowler: teamBPlayers[0])
    _ = CricketDataRepository.shared.recordBall(in: over1, ballNumber: 1, striker: teamAPlayers[0], bowler: teamBPlayers[0], runs: 4, isWide: false, isNoBall: false, isWicket: false)
    _ = CricketDataRepository.shared.recordBall(in: over1, ballNumber: 2, striker: teamAPlayers[0], bowler: teamBPlayers[0], runs: 0, isWide: true, isNoBall: false, isWicket: false)
    _ = CricketDataRepository.shared.recordBall(in: over1, ballNumber: 2, striker: teamAPlayers[0], bowler: teamBPlayers[0], runs: 6, isWide: false, isNoBall: false, isWicket: false)
    CricketDataRepository.shared.completeOver(over1, scoreAtOverEnd: Int16(CricketDataRepository.shared.calculateScore(in: match, innings: 1)))
    
    CricketDataRepository.shared.completeMatch(match)
    
    let teamAScore = CricketDataRepository.shared.calculateScore(in: match, innings: 1)
    let topBatsman = CricketDataRepository.shared.fetchTopBatsman(in: match, innings: 1)
    print("Team A Score:", teamAScore)
    if let top = topBatsman {
        print("Top Batsman:", top.playerName, CricketDataRepository.shared.fetchRunsFor(player: top, in: match, innings: 1))
    }
}

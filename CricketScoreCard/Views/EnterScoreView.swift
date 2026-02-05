import SwiftUI
import CoreData

// MARK: – Parameters passed from the previous view
struct EnterScoreParams: Hashable {
    let match: Match
    let battingTeam: Team
    let bowlingTeam: Team
    let battingPlayers: [Player]
    let bowlingPlayers: [Player]
    let striker: Player
    let nonStriker: Player
    let currentBowler: Player
    let maxOvers: Int
    let target: Int?          // nil in first innings
    let inningsNumber: Int    // 1 or 2
}

// MARK: – Mini stat structs
fileprivate struct Bat {
    var r = 0, b = 0, f = 0, sx = 0
    var sr: Int { b == 0 ? 0 : Int(round(Double(r) * 100 / Double(b))) }
}
fileprivate struct Bowl {
    var bl = 0, ru = 0, wk = 0
    var ov: String { "\(bl / 6).\(bl % 6)" }
    var eco: Double { let o = Double(bl) / 6; return o == 0 ? 0 : Double(ru) / o }
}
fileprivate struct Snap {
    var runs: Int
    var wk: Int
    var bl: Int
    var ov: [String]
    var striker: Player
    var nonStriker: Player
    var bat: [NSManagedObjectID: Bat]
    var bowl: [NSManagedObjectID: Bowl]
    var out: [NSManagedObjectID]
    var over: Over?
}

// MARK: – Main view
struct EnterScoreView: View {
    let p: EnterScoreParams
    private let repo = CricketDataRepository.shared
    
    // live actors
    @State private var striker: Player
    @State private var nonStriker: Player
    @State private var bowler: Player
    
    // live score
    @State private var runs = 0
    @State private var wkts = 0
    @State private var legalBalls = 0
    @State private var overBalls: [String] = []
    
    // stat maps
    @State private var batMap: [NSManagedObjectID: Bat] = [:]
    @State private var bowlMap: [NSManagedObjectID: Bowl] = [:]
    @State private var outSet: Set<NSManagedObjectID> = []
    
    // modal controls
    @State private var pickBatsman = false
    @State private var pickBowler = false
    
    // navigation
    @State private var nextParams: EnterScoreParams?
    @State private var showWinner = false
    
    // undo stack
    @State private var hist: [Snap] = []
    
    // current over for persistence
    @State private var currentOver: Over?
    
    init(params: EnterScoreParams) {
        self.p = params
        _striker = State(initialValue: params.striker)
        _nonStriker = State(initialValue: params.nonStriker)
        _bowler    = State(initialValue: params.currentBowler)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusBadge
                    scoreCard
                    batsmenCard
                    bowlerCard
                    overBallsStrip
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                keypad
                    .disabled(pickBatsman || pickBowler || showWinner)
            }
            .sheet(isPresented: $pickBatsman) { batsmanSheet.interactiveDismissDisabled(true) }
            .sheet(isPresented: $pickBowler) { bowlerSheet.interactiveDismissDisabled(true) }
            .onAppear {
                initStatMaps()
                ensureOver()
            }
            .navigationTitle(p.inningsNumber == 1 ? "1st innings" : "2nd innings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showWinner) {
                WinnerView(match: p.match, winner: winnerName, total: runs, wickets: wkts)
            }
            .navigationDestination(item: $nextParams) { EnterScoreView(params: $0) }
        }
    }

    private var statusBadge: some View {
        Text(statusLine)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
    }

    private var scoreCard: some View {
        VStack(spacing: 8) {
            Text("\(p.battingTeam.teamName ?? "") vs \(p.bowlingTeam.teamName ?? "")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(p.battingTeam.teamName ?? "")  \(runs)/\(wkts)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("(\(legalBalls / 6).\(legalBalls % 6) overs)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var batsmenCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Batting").font(.subheadline.weight(.semibold))
                Spacer()
                Text("R   B   4   6   SR").font(.caption).foregroundStyle(.secondary)
            }
            batsmanRow(striker, onStrike: true)
            batsmanRow(nonStriker, onStrike: false)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var bowlerCard: some View {
        let bs = bowlMap[bowler.objectID, default: .init()]
        return HStack {
            Text("Bowler").font(.subheadline.weight(.semibold))
            Spacer()
            Text(bowler.playerName ?? "")
            Spacer()
            Text("\(bs.ov) ov • \(bs.ru) r • \(bs.wk) w")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", bs.eco))
                .font(.caption.weight(.medium))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var overBallsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(overBalls, id: \.self) { v in
                    Text(v)
                        .font(.caption.weight(.medium))
                        .frame(minWidth: 28, minHeight: 28)
                        .background(Circle().stroke(Color.accentColor.opacity(0.5), lineWidth: 1.5))
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: UI building blocks
    private func batsmanRow(_ p: Player, onStrike: Bool) -> some View {
        let s = batMap[p.objectID, default: .init()]
        return HStack {
            Text("\(p.playerName ?? "")\(onStrike ? " *" : "")")
                .font(.subheadline)
            Spacer()
            Text("\(s.r)  \(s.b)   \(s.f)   \(s.sx)   \(s.sr)")
                .font(.caption.monospacedDigit())
        }
    }
    
    private var keypad: some View {
        let grid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return VStack(spacing: 12) {
            LazyVGrid(columns: grid, spacing: 10) {
                Button { addRuns(0) } label: { keypadLabel("•", sub: "Dot") }
                    .keyButtonStyle(.secondary)
                ForEach([1, 2, 3, 4], id: \.self) { v in
                    Button { addRuns(v) } label: { keypadLabel("\(v)", sub: nil) }
                        .keyButtonStyle(.runs)
                }
                Button { addRuns(6) } label: { keypadLabel("6", sub: "Six") }
                    .keyButtonStyle(.runs)
                Button { addExtra() } label: { keypadLabel("Wd", sub: "Wide") }
                    .keyButtonStyle(.extras)
                Button { addNoBall() } label: { keypadLabel("Nb", sub: "No-ball") }
                    .keyButtonStyle(.extras)
            }
            HStack(spacing: 10) {
                Button { recordWicket() } label: {
                    HStack { Image(systemName: "xmark.circle.fill"); Text("Wicket") }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .keyButtonStyle(.wicket)
                Button { undo() } label: {
                    HStack { Image(systemName: "arrow.uturn.backward"); Text("Undo") }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .keyButtonStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func keypadLabel(_ main: String, sub: String?) -> some View {
        VStack(spacing: 2) {
            Text(main)
                .font(.title2.weight(.bold))
            if let s = sub {
                Text(s)
                    .font(.caption2)
                    .opacity(0.9)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    // MARK: scoring helpers
    private func addRuns(_ r: Int) {
        guard ready else { return }
        pushSnapshot()
        updateBat(r)
        updateBowl(r, legal: true, wicket: false)
        runs += r
        writeBall(runs: r, isWide: false, isNo: false, isWicket: false)
        finishBall(desc: "\(r)", runs: r, legal: true)
    }
    
    private func addExtra() {
        guard ready else { return }
        pushSnapshot()
        updateBowl(1, legal: false, wicket: false)
        runs += 1
        writeBall(runs: 0, isWide: true, isNo: false, isWicket: false)
        overBalls.append("Ex")
        if targetMet { concludeInnings() }
    }

    private func addNoBall() {
        guard ready else { return }
        pushSnapshot()
        updateBat(1)
        updateBowl(1, legal: false, wicket: false)
        runs += 1
        writeBall(runs: 1, isWide: false, isNo: true, isWicket: false)
        finishBall(desc: "Nb", runs: 1, legal: false)
    }
    
    private func recordWicket() {
        guard ready else { return }
        pushSnapshot()
        updateBowl(0, legal: true, wicket: true)
        wkts += 1
        outSet.insert(striker.objectID)
        writeBall(runs: 0, isWide: false, isNo: false, isWicket: true)
        finishBall(desc: "W", runs: 0, legal: true)
        if wkts < 10 { pickBatsman = true }   // no popup after 10th wicket
    }
    
    private func undo() {
        guard let snap = hist.popLast(), ready else { return }
        restore(from: snap)
    }
    
    // MARK: stat updates
    private func updateBat(_ r: Int) {
        var s = batMap[striker.objectID, default: .init()]
        s.r += r; s.b += 1
        if r == 4 { s.f += 1 }
        if r == 6 { s.sx += 1 }
        batMap[striker.objectID] = s
    }
    private func updateBowl(_ r: Int, legal: Bool, wicket: Bool) {
        var b = bowlMap[bowler.objectID, default: .init()]
        if legal { b.bl += 1 }
        b.ru += r
        if wicket { b.wk += 1 }
        bowlMap[bowler.objectID] = b
    }
    
    // MARK: over / ball persistence
    private func ensureOver() {
        guard currentOver == nil else { return }
        let num = Int16(legalBalls / 6 + 1)
        currentOver = repo.createOver(match: p.match,
                                      overNumber: num,
                                      inningsNumber: Int16(p.inningsNumber),
                                      bowler: bowler)
    }
    private func writeBall(runs: Int, isWide: Bool, isNo: Bool, isWicket: Bool) {
        ensureOver()
        let ballNum = Int16(legalBalls % 6 + 1)
        _ = repo.recordBall(in: currentOver!,
                            ballNumber: ballNum,
                            striker: striker,
                            bowler: bowler,
                            runs: Int16(runs),
                            isWide: isWide,
                            isNoBall: isNo,
                            isWicket: isWicket)
    }
    private func closeOver() {
        if let o = currentOver {
            repo.completeOver(o, scoreAtOverEnd: Int16(runs))
            currentOver = nil
        }
    }
    
    // MARK: ball end
    private func finishBall(desc: String, runs r: Int, legal: Bool) {
        if legal { legalBalls += 1 }
        overBalls.append(desc)
        if r % 2 == 1 { swap(&striker, &nonStriker) }
        
        if inningsDone || targetMet {
            concludeInnings()
            return
        }
        
        let legalDeliveries = overBalls.filter { $0 != "Ex" && !$0.hasPrefix("Nb") }
        if legal && legalDeliveries.count == 6 {
            overBalls.removeAll()
            closeOver()
            swap(&striker, &nonStriker)
            pickBowler = true
        }
    }
    
    // MARK: innings/game conclusion
    private var inningsDone: Bool { legalBalls == p.maxOvers * 6 || wkts == 10 }
    private var targetMet: Bool  { p.target != nil && runs >= p.target! }
    private var ready: Bool      { !pickBatsman && !pickBowler && !showWinner }
    
    private func concludeInnings() {
        closeOver()
        if p.target == nil {
            // build second innings params
            let bats = p.bowlingPlayers
            let bowls = p.battingPlayers
            guard bats.count >= 2 else { showWinner = true; return }
            nextParams = EnterScoreParams(
                match: p.match,
                battingTeam: p.bowlingTeam,
                bowlingTeam: p.battingTeam,
                battingPlayers: bats,
                bowlingPlayers: bowls,
                striker: bats[0],
                nonStriker: bats[1],
                currentBowler: bowls[0],
                maxOvers: p.maxOvers,
                target: runs + 1,
                inningsNumber: 2
            )
        } else {
            showWinner = true
        }
    }
    
    // MARK: undo helpers
    private func pushSnapshot() {
        hist.append(
            Snap(runs: runs, wk: wkts, bl: legalBalls, ov: overBalls,
                 striker: striker, nonStriker: nonStriker,
                 bat: batMap, bowl: bowlMap, out: Array(outSet),
                 over: currentOver)
        )
    }
    private func restore(from s: Snap) {
        runs = s.runs; wkts = s.wk; legalBalls = s.bl; overBalls = s.ov
        striker = s.striker; nonStriker = s.nonStriker
        batMap = s.bat; bowlMap = s.bowl; outSet = Set(s.out)
        currentOver = s.over
    }
    
    // MARK: status & winner
    private var statusLine: String {
        let ballsLeft = max(0, p.maxOvers * 6 - legalBalls)
        if let t = p.target {
            let runsLeft = max(0, t - runs)
            return runsLeft == 0 ? "target reached" : "\(ballsLeft) balls • \(runsLeft) runs to win"
        }
        return "\(ballsLeft) balls left"
    }
    private var winnerName: String {
        if let t = p.target {
            return runs >= t ? p.battingTeam.teamName ?? "team"
                             : p.bowlingTeam.teamName ?? "team"
        }
        return p.battingTeam.teamName ?? "team"
    }
    
    private func initStatMaps() {
        batMap[striker.objectID] = .init()
        batMap[nonStriker.objectID] = .init()
        bowlMap[bowler.objectID]   = .init()
    }
    
    // MARK: sheets
    private var batsmanSheet: some View {
        NavigationStack {
            List(p.battingPlayers) { pl in
                if !outSet.contains(pl.objectID) && pl.objectID != striker.objectID && pl.objectID != nonStriker.objectID {
                    Button(pl.playerName ?? "") {
                        striker = pl
                        batMap[pl.objectID] = batMap[pl.objectID] ?? .init()
                        pickBatsman = false
                    }
                }
            }
            .navigationTitle("select batsman")
        }
    }
    
    private var bowlerSheet: some View {
        NavigationStack {
            List(p.bowlingPlayers) { pl in
                Button(pl.playerName ?? "") {
                    bowler = pl
                    bowlMap[pl.objectID] = bowlMap[pl.objectID] ?? .init()
                    pickBowler = false
                }
            }
            .navigationTitle("select bowler")
        }
    }
}

// MARK: – View extension for keypad buttons
fileprivate enum KeypadStyle {
    case runs, extras, wicket, secondary
}

fileprivate extension View {
    func keyButtonStyle(_ style: KeypadStyle) -> some View {
        let (bg, fg): (Color, Color) = {
            switch style {
            case .runs: return (Color.accentColor.opacity(0.2), Color.accentColor)
            case .extras: return (Color.orange.opacity(0.2), Color.orange)
            case .wicket: return (Color.red.opacity(0.2), Color.red)
            case .secondary: return (Color(.tertiarySystemFill), Color(.secondaryLabel))
            }
        }()
        return self
            .foregroundColor(fg)
            .frame(maxWidth: .infinity)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .buttonStyle(.plain)
    }
}


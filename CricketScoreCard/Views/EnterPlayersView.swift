import SwiftUI
import CoreData

struct EnterPlayersView: View {
    @EnvironmentObject private var appState: AppState
    @State private var teamAName = ""
    @State private var teamBName = ""
    @State private var teamAPlayers = Array(repeating: "", count: 11)
    @State private var teamBPlayers = Array(repeating: "", count: 11)
    @State private var battingFirst = 0
    @State private var oversValue: Double = 2
    @State private var scoreParams: EnterScoreParams?
    @State private var nav = false

    private var userForMatch: User {
        if let u = appState.currentUser { return u }
        let ctx = CricketDataRepository.shared.viewContext
        return (try? ctx.fetch(User.fetchRequest()).first) ?? CricketDataRepository.shared.createUser(username: "default", password: "pw")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Match Setup")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(.primary)
                        
                        Text("Enter team details and match parameters")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical)
                    
                    // Team Sections
                    teamSection(label: "Team A", team: $teamAName, players: $teamAPlayers, teamColor: .blue)
                    
                    teamSection(label: "Team B", team: $teamBName, players: $teamBPlayers, teamColor: .red)
                    
                    // Match Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Match Settings")
                            .font(.title3)
                            .bold()
                            .padding(.bottom, 4)
                        
                        // Batting First Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Batting First")
                                .font(.headline)
                            
                            Picker("Batting Team", selection: $battingFirst) {
                                Text(teamAName.isEmpty ? "Team A" : teamAName).tag(0)
                                Text(teamBName.isEmpty ? "Team B" : teamBName).tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.vertical, 4)
                        }
                        
                        // Overs Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Overs")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(Int(oversValue))")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.accentColor)
                            }
                            
                            Slider(value: $oversValue, in: 1...50, step: 1)
                                .tint(.accentColor)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Start Match Button
                    Button(action: startMatch) {
                        HStack {
                            Spacer()
                            Text("Start Match")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(formValid ? Color.accentColor : Color.gray)
                        .cornerRadius(10)
                        .shadow(color: formValid ? Color.accentColor.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
                    }
                    .disabled(!formValid)
                    .padding(.vertical)
                    .animation(.easeInOut, value: formValid)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Match")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $nav) {
                if let p = scoreParams {
                    EnterScoreView(params: p)
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    @ViewBuilder
    private func teamSection(label: String, team: Binding<String>, players: Binding<[String]>, teamColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(label)
                    .font(.title2)
                    .bold()
                    .foregroundColor(teamColor)
                
                Spacer()
                
                Circle()
                    .fill(teamColor)
                    .frame(width: 12, height: 12)
            }
            
            TextField("Team name", text: team)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.headline)
                .submitLabel(.next)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<11, id: \.self) { i in
                    TextField("Player \(i + 1)", text: players[i])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(i == 10 ? .done : .next)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var formValid: Bool {
        !teamAName.isEmpty &&
        !teamBName.isEmpty &&
        !teamAPlayers.contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }) &&
        !teamBPlayers.contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty })
    }
    
    private func startMatch() {
        let repo = CricketDataRepository.shared
        let match = repo.createMatch(for: userForMatch,
                                   tossResult: battingFirst == 0 ? teamAName : teamBName)
        let teamA = repo.createTeam(match: match, teamName: teamAName)
        let teamB = repo.createTeam(match: match, teamName: teamBName)
        let teamAObjs = teamAPlayers.map { repo.createPlayer(team: teamA, name: $0) }
        let teamBObjs = teamBPlayers.map { repo.createPlayer(team: teamB, name: $0) }
        let battingTeam = battingFirst == 0 ? teamA : teamB
        let bowlingTeam = battingFirst == 0 ? teamB : teamA
        let battingList = battingFirst == 0 ? teamAObjs : teamBObjs
        let bowlingList = battingFirst == 0 ? teamBObjs : teamAObjs
        guard battingList.count >= 2, bowlingList.count >= 1 else { return }
        scoreParams = EnterScoreParams(
            match: match,
            battingTeam: battingTeam,
            bowlingTeam: bowlingTeam,
            battingPlayers: battingList,
            bowlingPlayers: bowlingList,
            striker: battingList[0],
            nonStriker: battingList[1],
            currentBowler: bowlingList[0],
            maxOvers: Int(oversValue),
            target: nil,
            inningsNumber: 1
        )
        nav = true
    }
}

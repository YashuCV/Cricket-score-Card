import SwiftUI
import CoreData

struct MatchResultsView: View {
    let match: Match
    private let repo = CricketDataRepository.shared
    
    private var teams: [Team] {
        (match.teams as? Set<Team>)?
            .sorted { ($0.teamName ?? "") < ($1.teamName ?? "") } ?? []
    }
    
    private var teamAName: String {
        teams.first?.teamName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        ? teams.first!.teamName! : "Team A"
    }
    
    private var teamBName: String {
        teams.dropFirst().first?.teamName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        ? teams.dropFirst().first!.teamName! : "Team B"
    }
    
    // Match statistics
    private var runsA: Int { repo.calculateScore(in: match, innings: 1) }
    private var runsB: Int { repo.calculateScore(in: match, innings: 2) }
    private var oversA: Int { repo.fetchOvers(for: match, innings: 1).count }
    private var oversB: Int { repo.fetchOvers(for: match, innings: 2).count }
    private var runRateA: Double { oversA == 0 ? 0 : Double(runsA) / Double(oversA) }
    private var runRateB: Double { oversB == 0 ? 0 : Double(runsB) / Double(oversB) }
    private var extrasA: Int { repo.fetchTotalExtras(in: match, innings: 1) }
    private var extrasB: Int { repo.fetchTotalExtras(in: match, innings: 2) }
    
    private var topBatsmanName: String {
        if let p = repo.fetchTopBatsman(in: match) {
            let r = repo.fetchRunsFor(player: p, in: match)
            return "\(p.playerName ?? "Unknown") (\(r) runs)"
        }
        return "N/A"
    }
    
    private var topBowlerName: String {
        if let p = repo.fetchTopBowler(in: match) {
            let w = repo.fetchWicketsFor(bowler: p, in: match)
            return "\(p.playerName ?? "Unknown") (\(w) wickets)"
        }
        return "N/A"
    }
    
    private var winnerName: String {
        if runsA == runsB { return "Match Tied" }
        return runsA > runsB ? teamAName : teamBName
    }
    
    private var matchDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: match.dateStarted ?? Date())
    }
    
    private var winnerColor: Color {
        runsA == runsB ? .orange : (runsA > runsB ? .blue : .red)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header section
                headerSection
                
                // Match summary card
                matchSummaryCard
                
                // Team performance cards
                teamPerformanceSection
                
                // Player highlights
                playerHighlightsSection
                
                // Match details
                matchDetailsSection
            }
            .padding()
        }
        .navigationTitle("Match Results")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("\(teamAName) vs \(teamBName)")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(matchDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(winnerColor)
                
                Text(winnerName)
                    .font(.title3)
                    .bold()
                    .foregroundColor(winnerColor)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(winnerColor.opacity(0.1))
            .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }
    
    private var matchSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Match Summary")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(teamAName)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.blue)
                    
                    Text("\(runsA)/\(extrasA)")
                        .font(.title)
                        .bold()
                    
                    Text("\(oversA) overs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Text("vs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    Text(teamBName)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.red)
                    
                    Text("\(runsB)/\(extrasB)")
                        .font(.title)
                        .bold()
                    
                    Text("\(oversB) overs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private var teamPerformanceSection: some View {
        HStack(spacing: 16) {
            teamPerformanceCard(teamName: teamAName, runs: runsA, overs: oversA, extras: extrasA, runRate: runRateA, color: .blue)
            
            teamPerformanceCard(teamName: teamBName, runs: runsB, overs: oversB, extras: extrasB, runRate: runRateB, color: .red)
        }
    }
    
    private func teamPerformanceCard(teamName: String, runs: Int, overs: Int, extras: Int, runRate: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(teamName)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
            
            Divider()
            
            InfoRow(label: "Runs", value: "\(runs)")
            InfoRow(label: "Overs", value: "\(overs)")
            InfoRow(label: "Extras", value: "\(extras)")
            InfoRow(label: "Run Rate", value: String(format: "%.2f", runRate))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private var playerHighlightsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Player Highlights")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 16) {
                playerHighlightCard(title: "Top Batsman", value: topBatsmanName, icon: "bat", color: .green)
                
                playerHighlightCard(title: "Top Bowler", value: topBowlerName, icon: "ball", color: .purple)
            }
        }
    }
    
    private func playerHighlightCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon == "bat" ? "cricket.ball.fill" : "figure.cricket")
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.primary)
            }
            
            Divider()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private var matchDetailsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Match Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 8) {
                InfoRow(label: "Toss", value: match.tossResult ?? "Unknown")
                InfoRow(label: "Match Date", value: matchDate)
                InfoRow(label: "Match ID", value: match.matchID?.uuidString ?? "N/A")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - InfoRow Component

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

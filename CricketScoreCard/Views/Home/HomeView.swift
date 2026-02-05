import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showEnterPlayers = false
    private let repo = CricketDataRepository.shared

    private var currentUser: User? { appState.currentUser }
    private var username: String { currentUser?.username ?? "User" }
    private var matchCount: Int {
        guard let user = currentUser else { return 0 }
        return repo.completedMatchesCount(for: user)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    headerSection
                    actionButtons
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            appState.logout()
                        } label: {
                            Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationDestination(isPresented: $showEnterPlayers) {
                EnterPlayersView()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "cricket.ball.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)

            Text("Cricket Scorecard")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Hello, \(username)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if matchCount > 0 {
                Text("\(matchCount) match\(matchCount == 1 ? "" : "es") completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 32)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: { showEnterPlayers = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Start New Match")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            NavigationLink {
                PreviousMatchesView()
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Match History")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .foregroundColor(.accentColor)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.accentColor.opacity(0.6), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let ctx = PreviewHelpers.previewContext
        CricketDataRepository.shared.useContext(ctx)
        CricketDataRepository.shared.resetAndSeedDemoData()
        let user = (try? ctx.fetch(User.fetchRequest()).first) ?? CricketDataRepository.shared.createUser(username: "demo", password: "demo")
        let appState = AppState()
        appState.currentUser = user

        return HomeView()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(appState)
    }
}
#endif

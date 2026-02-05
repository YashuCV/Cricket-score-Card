import SwiftUI
import CoreData

@main
struct CricketScoreCardApp: App {
    @StateObject private var appState = AppState()
    private let container = PersistenceController.shared

    init() {
        CricketDataRepository.shared.useContext(container.viewContext)
        if (try? container.viewContext.count(for: Match.fetchRequest())) == 0 {
            CricketDataRepository.shared.resetAndSeedDemoData()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, container.viewContext)
                .environmentObject(appState)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.currentUser != nil {
                HomeView()
            } else if appState.showLogin {
                LoginView()
            } else {
                SplashScreen()
            }
        }
    }
}

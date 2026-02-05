import SwiftUI
import CoreData

final class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var showLogin = false

    func logout() {
        currentUser = nil
        showLogin = true
    }
}

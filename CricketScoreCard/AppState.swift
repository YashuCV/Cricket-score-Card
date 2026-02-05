//
//  AppState.swift
//  CricketScoreCard
//

import SwiftUI
import CoreData

/// Global app state: current user (nil = not logged in) and whether to show login after splash.
final class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var showLogin = false

    func logout() {
        currentUser = nil
        showLogin = true
    }
}

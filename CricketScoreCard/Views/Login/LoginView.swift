import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showAlert = false
    @State private var alertMsg = ""
    @State private var showSignUp = false

    private let repo = CricketDataRepository.shared

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    cardSection
                    signUpPrompt
                }
                .padding(.horizontal, 24)
                .padding(.top, 48)
            }
        }
        .onAppear {
            username = ""
            password = ""
            showAlert = false
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .alert("Login failed", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMsg)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "cricket.ball.fill")
                .font(.system(size: 50))
                .foregroundStyle(.tint)
            Text("Welcome back")
                .font(.title)
                .fontWeight(.bold)
            Text("Sign in to manage your matches")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var cardSection: some View {
        VStack(spacing: 20) {
            TextField("Username", text: $username)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .autocapitalization(.none)
                .textInputAutocapitalization(.never)

            HStack {
                if showPassword {
                    TextField("Password", text: $password)
                        .textFieldStyle(.plain)
                } else {
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                }
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            Button(action: submit) {
                HStack {
                    Text("Sign In")
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var signUpPrompt: some View {
        Button {
            showSignUp = true
        } label: {
            HStack {
                Text("Don't have an account?")
                    .foregroundStyle(.secondary)
                Text("Create account")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
            .font(.subheadline)
        }
        .padding(.top, 8)
    }

    private func submit() {
        let user = username.trimmingCharacters(in: .whitespaces)
        guard !user.isEmpty, !password.isEmpty else {
            alertMsg = "Please enter username and password."
            showAlert = true
            return
        }
        guard repo.validateUser(username: user, password: password) else {
            alertMsg = repo.fetchUser(username: user) == nil
                ? "Username not found."
                : "Incorrect password."
            showAlert = true
            return
        }
        if let loggedInUser = repo.fetchUser(username: user) {
            appState.currentUser = loggedInUser
        }
    }
}


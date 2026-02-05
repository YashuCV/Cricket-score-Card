import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var showPassword = false
    @State private var showAlert = false
    @State private var alertMsg = ""

    private let repo = CricketDataRepository.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
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

                            SecureField("Confirm Password", text: $confirm)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)

                            Button(action: submit) {
                                HStack {
                                    Text("Create account")
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green)
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
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Create account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Sign-up error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMsg)
            }
        }
    }

    private func submit() {
        let user = username.trimmingCharacters(in: .whitespaces)
        guard !user.isEmpty, !password.isEmpty else {
            alertMsg = "Username and password are required."
            showAlert = true
            return
        }
        guard password == confirm else {
            alertMsg = "Passwords do not match."
            showAlert = true
            return
        }
        guard repo.fetchUser(username: user) == nil else {
            alertMsg = "Username already exists."
            showAlert = true
            return
        }
        _ = repo.createUser(username: user, password: password)
        dismiss()
    }
}

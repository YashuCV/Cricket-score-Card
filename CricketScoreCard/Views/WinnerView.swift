import SwiftUI

struct WinnerView: View {
    let match: Match
    let winner: String
    let total: Int
    let wickets: Int
    
    @Environment(\.dismiss) private var dismiss
    private let repo = CricketDataRepository.shared
    @State private var goHome = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            // Content
            VStack(spacing: 24) {
                Spacer()
                
                // Trophy icon with celebration effect
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 5, x: 0, y: 2)
                }
                .scaleEffect(showConfetti ? 1.1 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.5), value: showConfetti)
                
                // Winner announcement
                VStack(spacing: 8) {
                    Text("Match Over!")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text(winner)
                        .font(.title)
                        .bold()
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.1))
                        )
                    
                    Text("won by \(total)/\(wickets)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action button
                Button(action: {
                    goHome = true
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Return to Home")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            
            // Confetti effect
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !match.isCompleted {
                repo.completeMatch(match)
            }
            
            // Trigger confetti animation after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showConfetti = true
                }
            }
        }
        .navigationDestination(isPresented: $goHome) {
            HomeView()
        }
    }
}

// Confetti effect view
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                ConfettiPiece()
                    .offset(x: CGFloat.random(in: -200...200),
                            y: animate ? UIScreen.main.bounds.height : -100)
                    .animation(
                        Animation.linear(duration: Double.random(in: 3...5))
                        .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
        .allowsHitTesting(false)
    }
}

// Single confetti piece
struct ConfettiPiece: View {
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple]
    let shapes: [AnyView] = [
        AnyView(Circle().frame(width: 10, height: 10)),
        AnyView(Rectangle().frame(width: 10, height: 10)),
        AnyView(RoundedRectangle(cornerRadius: 2).frame(width: 12, height: 6))
    ]
    
    var body: some View {
        shapes.randomElement()!
            .foregroundColor(colors.randomElement()!)
            .rotationEffect(.degrees(Double.random(in: 0...360)))
            .opacity(0.8)
    }
}

import SwiftUI

struct Product: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let imageName: String
}

extension UIImpactFeedbackGenerator {
    static func generateFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

struct WalletView: View {
    @EnvironmentObject var authManager: AuthManager

    @Binding var selectedCard: UserCard?
    var onTapCard: (UserCard) -> Void
    @State private var showSheet = false

    @ViewBuilder
    private func deleteButton(for userCard: UserCard) -> some View {
        if selectedCard == userCard {
            Button(action: {
                showSheet = true
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.white, .red)
                    .font(.title)
            }
            .transition(.opacity)
            .offset(x: 10, y: -10)
            .buttonStyle(NoOpacityButtonStyle())
            .confirmationDialog(
                "",
                isPresented: $showSheet,
                titleVisibility: .hidden
            ) {
                Button("Remove Card", role: .destructive) {
                    Task {
                        let success = await authManager.deleteUserCard(cardID: userCard.id)
                        if success {
                            withAnimation {
                                authManager.userCards.removeAll { $0.id == userCard.id }
                                selectedCard = nil
                            }
                        }
                    }
                }

                Button("Cancel", role: .cancel) {
                    withAnimation {
                        selectedCard = nil
                    }
                }
            }
        }
    }

    private func longPressGesture(for userCard: UserCard) -> some Gesture {
        LongPressGesture()
            .onEnded { _ in
                UIImpactFeedbackGenerator.generateFeedback(style: .light)
                withAnimation {
                    selectedCard = userCard
                }
            }
    }

    var body: some View {
        ZStack {
            if authManager.userCards.count > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(authManager.userCards) { userCard in
                            ZStack(alignment: .topTrailing) {
                                CreditCardView(height: 150, width: 250, issuer: userCard.card_model.issuer.name, card_name: userCard.card_model.name, showInfo: true)
                                    .onTapGesture{
                                        UIImpactFeedbackGenerator.generateFeedback(style: .light)
                                        onTapCard(userCard)
                                    }
                                    .gesture(
                                        LongPressGesture()
                                            .onEnded { _ in
                                                UIImpactFeedbackGenerator.generateFeedback(style: .light)
                                                withAnimation {
                                                    selectedCard = userCard
                                                }
                                            }
                                    )

                                deleteButton(for: userCard)
                            }
                            .padding(.top)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }
}

struct NoOpacityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // No opacity change when pressed
    }
}

//#Preview {
//    WalletView()
//}

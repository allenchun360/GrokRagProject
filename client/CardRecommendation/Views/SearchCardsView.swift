import SwiftUI

struct Institution: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
}

struct SearchCardsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCards: Set<String> = []
    @State private var searchText: String = ""

    var isDisabled: Bool {
        selectedCards.count < 1
    }

    var allCards: [CardBrand] {
        authManager.allCards
    }

    var filteredCards: [CardBrand] {
        if searchText.isEmpty {
            return allCards
        } else {
            return allCards.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 24) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Add cards to your wallet!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .padding(.horizontal)

                    SearchBar(text: $searchText, placeholder: "Search cards")
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCards) { cardBrand in
                            AccountRow(
                                cardBrand: cardBrand,
                                isSelected: selectedCards.contains(cardBrand.id),
                                toggleSelection: {
                                    if selectedCards.contains(cardBrand.id) {
                                        selectedCards.remove(cardBrand.id)
                                    } else {
                                        selectedCards.insert(cardBrand.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .ignoresSafeArea(.keyboard)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if authManager.isLoading {
                    ProgressView()
                } else {
                    Button("Add") {
                        Task {
                            if await authManager.createUserCards(cardIDs: Array(selectedCards)) {
                                if !authManager.completed {
                                    authManager.completed = true
                                } else {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .foregroundColor(isDisabled ? .gray: .blue)
                    .disabled(isDisabled)
                }
            }
        }
    }
}

struct AccountRow: View {
    let cardBrand: CardBrand
    let isSelected: Bool
    let toggleSelection: () -> Void

    var body: some View {
        Button(action: toggleSelection) {
            HStack {
                Image(systemName: "creditcard")
                    .frame(height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(cardBrand.name)
                    .foregroundColor(.primary)
                    .font(.body)

                Spacer()

                Image(systemName: isSelected ? "minus.circle" : "plus.circle")
                    .foregroundColor(.primary)
            }
            .padding()
            .background(
                isSelected ? Color.green.opacity(0.2) : Color(.systemGray5)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview {
    SearchCardsView()
}

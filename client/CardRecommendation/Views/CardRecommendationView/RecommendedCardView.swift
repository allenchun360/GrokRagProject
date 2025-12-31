import SwiftUI

struct RecommendedCardView: View {
    let card: RewardRecommendation
    @Binding var spendingInput: String
    @Binding var spending: Double
    @FocusState.Binding var isInputActive: Bool

    var saving: Double {
        spending * card.value
    }

    var message: String {
        if card.reward_type == "points" {
            let pointValue = card.value / card.reward_amount
            return "You earn \(Int(card.reward_amount))x points for \(card.category) purchases.\n1 point is worth $\(String(format: "%.2f", pointValue))."
        } else {
            return "You earn \(Int(card.reward_amount * 100))% cashback for \(card.category) purchases."
        }
    }

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Spend")
                        .font(.title)
                    TextField("$0", text: $spendingInput)
                        .keyboardType(.decimalPad)
                        .font(.system(.largeTitle, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .onChange(of: spendingInput) { oldValue, newValue in
                            formatSpendingInput(newValue, oldValue: oldValue, spendingInput: &spendingInput, spending: &spending)
                        }
                        .focused($isInputActive)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .padding(.leading)

                VStack {
                    Text("Save")
                        .font(.title)
                    TextField("", text: .constant(String(format: "$%.2f", saving)))
                        .font(.system(.largeTitle, design: .monospaced))
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .disabled(true)
                }
                .frame(maxWidth: .infinity)
                .padding(.trailing)
                .padding(.vertical)
            }
            .frame(maxHeight: .infinity)

            CreditCardView(height: 200, issuer: card.issuer, card_name: card.card_name)
                .padding()

            Label(message, systemImage: "info.circle")
                .foregroundColor(.gray)
                .font(.subheadline)
                .frame(height: 100, alignment: .topLeading)
        }
        // .padding(.bottom, 100)
        .transition(.opacity)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ViewHeightKey.self, value: geometry.size.height)
            }
        )
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

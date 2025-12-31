import SwiftUI

struct GPTAnalysisCardView: View {
    let analysis: GPTAnalysisResult
    @Binding var spendingInput: String
    @Binding var spending: Double
    @FocusState.Binding var isInputActive: Bool
    var rank: Int? = nil

    var saving: Double {
        guard let value = analysis.value else { return 0 }
        return spending * value
    }

    var message: String {
        if analysis.reward_type == "points" {
            guard let rewardAmount = analysis.reward_amount else {
                return "Points reward information not available."
            }
            let pointValue = analysis.value ?? 0 / rewardAmount
            return "You earn \(Int(rewardAmount))x points for \(analysis.category) purchases.\n1 point is worth $\(String(format: "%.2f", pointValue))."
        } else {
            guard let rewardAmount = analysis.reward_amount else {
                return "Cashback information not available."
            }
            return "You earn \(Int(rewardAmount * 100))% cashback for \(analysis.category) purchases."
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Spending Input Section
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

            // Credit Card View
            CreditCardView(height: 200, issuer: analysis.issuer, card_name: analysis.card_name, rank: rank)
                .padding()

            // Basic Info
            // VStack(alignment: .leading, spacing: 8) {
            //     Label(message, systemImage: "info.circle")
            //         .foregroundColor(.gray)
            //         .font(.subheadline)
            // }
            // .frame(maxWidth: .infinity, alignment: .leading)
            // .padding(.horizontal)

            // Detailed Analysis
            VStack(alignment: .leading, spacing: 12) {
                    // Explanation
                    if !analysis.explanation.isEmpty || analysis.isStreaming {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Analysis")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(analysis.explanation)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Estimated Value
                    if !analysis.estimated_value.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Estimated Value")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(analysis.estimated_value)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Benefits
                    if !analysis.benefits.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Benefits")
                                .font(.headline)
                                .foregroundColor(.white)
                            ForEach(analysis.benefits, id: \.self) { benefit in
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(benefit)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    // Limitations
                    if !analysis.limitations.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Limitations")
                                .font(.headline)
                                .foregroundColor(.white)
                            ForEach(analysis.limitations, id: \.self) { limitation in
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text(limitation)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            Spacer()
            Spacer()
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ViewHeightKey.self, value: geometry.size.height)
            }
        )
    }
}

#Preview {
    @FocusState var previewFocus: Bool
    
    return GPTAnalysisCardView(
        analysis: GPTAnalysisResult(
            card_id: "00000000-0000-0000-0000-000000000001",
            card_name: "Chase Sapphire Preferred",
            issuer: "Chase",
            value: 0.025,
            reward_type: "cashback",
            reward_amount: 0.025,
            category: "dining",
            benefits: ["2.5% cashback on dining", "No annual fee", "Travel benefits"],
            explanation: "This card offers excellent value for dining purchases with 2.5% cashback and additional travel benefits.",
            limitations: ["Limited to dining purchases", "Higher APR"],
            estimated_value: "2.5% cashback"
        ),
        spendingInput: .constant("$100"),
        spending: .constant(100),
        isInputActive: $previewFocus
    )
    .preferredColorScheme(.dark)
}

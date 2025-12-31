// CardRecommendation/Views/Components/SavingsCardView.swift
import SwiftUI

struct SavingsCardView: View {
    let amount: String
    let increase: String

    var body: some View {
        // VStack(alignment: .leading, spacing: 12) {
        //     Text("Savings")
        //         .font(.largeTitle)
        //     Text(amount)
        //         .font(.system(size: 40))
        //         .foregroundColor(.blue)
        //     Text("You saved \(increase) more than last month!")
        //         .font(.subheadline)
        // }
        // .frame(maxWidth: .infinity, alignment: .leading)
        // .padding()
        // .background(Color(.tertiarySystemBackground))
        // .cornerRadius(16)
        // .shadow(radius: 2)
        DisclosureGroup("Wallet") {
            Text(amount)
                .font(.system(size: 40))
                .foregroundColor(.blue)
            Text("You saved \(increase) more than last month!")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

#Preview {
    SavingsCardView(amount: "$1,000.00", increase: "$20")
}

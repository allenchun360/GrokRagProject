import SwiftUI

struct CardInfoView: View {
    var userCard: UserCard
    @Environment(\.dismiss) private var dismiss
    @State private var safeAreaInsets = EdgeInsets()
    @StateObject private var viewModel = CardInfoViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CreditCardView(height: 200, issuer: userCard.card_model.issuer.name, card_name: userCard.card_model.name)
                    .padding()

                // Card Details Content
                if let data = viewModel.cardDetailsData,
                   data.rewards_summary != nil ||
                   !(data.key_benefits?.isEmpty ?? true) ||
                   !(data.additional_benefits?.isEmpty ?? true) ||
                   data.network != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        if let rewardsSummary = data.rewards_summary {
                            DetailItem(title: "Rewards Summary", value: rewardsSummary)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if let keyBenefits = data.key_benefits, !keyBenefits.isEmpty {
                            DetailListItem(title: "Key Benefits", items: keyBenefits)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if let additionalBenefits = data.additional_benefits, !additionalBenefits.isEmpty {
                            DetailListItem(title: "Additional Benefits", items: additionalBenefits)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if let network = data.network {
                            DetailItem(title: "Network", value: network)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.safeAreaInsets) { oldValue, newValue in
                        safeAreaInsets = newValue
                    }
            }
        )
        .overlay(alignment: .top) {
            Color.black
                .frame(height: safeAreaInsets.top)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea()
        }
        .toolbarBackground(Color(.black), for: .navigationBar)
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
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchCardDetails(cardId: userCard.card_model.id)
            }
        }
    }
}

// MARK: - Detail Components

struct DetailItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DetailListItem: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NestedDetailSection: View {
    let title: String
    let items: [[String: Any]]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(item.keys.sorted()), id: \.self) { key in
                        if let value = item[key] {
                            HStack(alignment: .top, spacing: 8) {
                                Text(formatKey(key))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(formatValue(value))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)

                if index < items.count - 1 {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func formatKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private func formatValue(_ value: Any) -> String {
        if let stringValue = value as? String {
            return stringValue
        } else if let numberValue = value as? NSNumber {
            return "\(numberValue)"
        }
        return ""
    }
}

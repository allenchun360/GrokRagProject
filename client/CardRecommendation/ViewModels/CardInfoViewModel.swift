import SwiftUI
import Foundation
import Combine

class CardInfoViewModel: ObservableObject {
    @Published var cardDetailsData: CardDetailsData?
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let apiService = APIService()
    private var streamingContent = ""

    @MainActor
    func fetchCardDetails(cardId: String) async {
        isLoading = true
        error = nil
        streamingContent = ""
        cardDetailsData = nil

        await apiService.getCardDetailsStreaming(
            cardId: cardId,
            onChunkReceived: { [weak self] chunk in
                guard let self = self else { return }
                self.streamingContent += chunk
                self.updateCardDetailsFromStreamingContent()
            },
            onComplete: { [weak self] fullResponse in
                guard let self = self else { return }
                self.streamingContent = fullResponse
                self.updateCardDetailsFromStreamingContent()
                self.isLoading = false
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.error = error.localizedDescription
                self.isLoading = false
            }
        )
    }

    @MainActor
    private func updateCardDetailsFromStreamingContent() {
        // Try to parse complete JSON first
        if let data = streamingContent.data(using: .utf8),
           let json = try? JSONDecoder().decode(CardDetailsData.self, from: data) {
            withAnimation(.easeInOut(duration: 0.3)) {
                cardDetailsData = json
            }
            return
        }

        // If JSON is incomplete, extract partial data using regex
        extractPartialCardDetails()
    }

    @MainActor
    private func extractPartialCardDetails() {
        var data = cardDetailsData ?? CardDetailsData(
            card_id: "",
            card_name: "",
            issuer: "",
            rewards_summary: nil,
            key_benefits: nil,
            reward_categories: nil,
            additional_benefits: nil,
            network: nil
        )

        // Extract string fields
        data.card_id = extractStringField(key: "card_id") ?? data.card_id
        data.card_name = extractStringField(key: "card_name") ?? data.card_name
        data.issuer = extractStringField(key: "issuer") ?? data.issuer
        data.rewards_summary = extractStringField(key: "rewards_summary") ?? data.rewards_summary
        data.network = extractStringField(key: "network") ?? data.network

        // Extract array fields
        data.key_benefits = extractArrayField(key: "key_benefits") ?? data.key_benefits
        data.additional_benefits = extractArrayField(key: "additional_benefits") ?? data.additional_benefits

        withAnimation(.easeInOut(duration: 0.3)) {
            cardDetailsData = data
        }
    }

    private func extractStringField(key: String) -> String? {
        let pattern = "\"\(key)\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }

        let range = NSRange(streamingContent.startIndex..., in: streamingContent)
        if let match = regex.firstMatch(in: streamingContent, range: range),
           match.numberOfRanges > 1,
           let valueRange = Range(match.range(at: 1), in: streamingContent) {
            var value = String(streamingContent[valueRange])
            value = value.replacingOccurrences(of: "\\n", with: "\n")
            value = value.replacingOccurrences(of: "\\\"", with: "\"")
            value = value.replacingOccurrences(of: "\\\\", with: "\\")
            return value
        }
        return nil
    }

    private func extractArrayField(key: String) -> [String]? {
        let pattern = "\"\(key)\"\\s*:\\s*\\[((?:[^\\]]|\\](?!\\s*[,}]))*)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }

        let range = NSRange(streamingContent.startIndex..., in: streamingContent)
        if let match = regex.firstMatch(in: streamingContent, range: range),
           match.numberOfRanges > 1,
           let arrayRange = Range(match.range(at: 1), in: streamingContent) {
            let arrayContent = String(streamingContent[arrayRange])

            // Extract array items
            let itemPattern = "\"((?:[^\"\\\\]|\\\\.)*)\""
            guard let itemRegex = try? NSRegularExpression(pattern: itemPattern, options: []) else {
                return nil
            }

            let itemRange = NSRange(arrayContent.startIndex..., in: arrayContent)
            let itemMatches = itemRegex.matches(in: arrayContent, range: itemRange)

            var items: [String] = []
            for itemMatch in itemMatches {
                if itemMatch.numberOfRanges > 1,
                   let itemValueRange = Range(itemMatch.range(at: 1), in: arrayContent) {
                    var item = String(arrayContent[itemValueRange])
                    item = item.replacingOccurrences(of: "\\n", with: "\n")
                    item = item.replacingOccurrences(of: "\\\"", with: "\"")
                    item = item.replacingOccurrences(of: "\\\\", with: "\\")
                    items.append(item)
                }
            }

            return items.isEmpty ? nil : items
        }
        return nil
    }
}

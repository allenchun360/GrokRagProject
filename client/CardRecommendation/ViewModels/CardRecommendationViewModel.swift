import SwiftUI
import Foundation
import Combine

class CardRecommendationViewModel: ObservableObject {
    @Published var recommendations: [RewardRecommendation] = []
    @Published var gptAnalysis: [GPTAnalysisResult] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let apiService = APIService()
    private var streamingContent = ""

    var isStreaming: Bool {
        gptAnalysis.contains { $0.isStreaming }
    }

    @MainActor
    func fetchRecommendations(for types: [String], storeName: String, storeAddress: String, showLoading: Bool = true) async {
        isLoading = true
        error = nil
        streamingContent = ""

        await apiService.analyzeCardsWithGPTStreaming(
            forTypes: types,
            storeName: storeName,
            storeAddress: storeAddress,
            onRankingReceived: { [weak self] ranking in
                guard let self = self else { return }
                print("📊 Ranking received: \(ranking.count) cards")

                // Create initial GPT analysis placeholders based on ranking
                self.recommendations = ranking
                self.gptAnalysis = ranking.map { rec in
                    GPTAnalysisResult(
                        card_id: rec.card_id,
                        card_name: rec.card_name,
                        issuer: rec.issuer,
                        value: rec.value,
                        reward_type: rec.reward_type,
                        reward_amount: rec.reward_amount,
                        category: rec.category,
                        benefits: [],
                        explanation: "",
                        limitations: [],
                        estimated_value: "",
                        isStreaming: true
                    )
                }

                // Hide loading indicator once we have the ranking
                self.isLoading = false
            },
            onChunkReceived: { [weak self] chunk in
                guard let self = self else { return }
                self.streamingContent += chunk
                self.updateAnalysisFromStreamingContent()
            },
            onComplete: { [weak self] fullResponse in
                guard let self = self else { return }
                print("✅ Streaming complete")
                self.streamingContent = fullResponse
                self.updateAnalysisFromStreamingContent()

                // Mark all analyses as no longer streaming
                for i in 0..<self.gptAnalysis.count {
                    self.gptAnalysis[i].isStreaming = false
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.error = error.localizedDescription
                self.isLoading = false
            }
        )
    }

    @MainActor
    private func updateAnalysisFromStreamingContent() {
        print("📝 Attempting to parse streaming content (\(streamingContent.count) chars)")

        // First, try to extract and show partial text content even if JSON is incomplete
        extractAndShowPartialContent()

        // Also try to parse as complete JSON if possible
        guard let data = streamingContent.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let analysisArray = json["analysis"] as? [[String: Any]] else {
            print("⚠️ Cannot parse as complete JSON yet - showing partial content")
            return
        }

        print("✅ Successfully parsed complete JSON")
        print("📊 Found analysis array with \(analysisArray.count) items")

        // Update each card's analysis as data becomes available
        for (index, analysisDict) in analysisArray.enumerated() {
            guard index < gptAnalysis.count else {
                print("⚠️ Analysis index \(index) exceeds gptAnalysis count \(gptAnalysis.count)")
                continue
            }

            var updated = false

            // Update the explanation if available
            if let explanation = analysisDict["explanation"] as? String, !explanation.isEmpty {
                gptAnalysis[index].explanation = explanation
                updated = true
                print("📝 Updated explanation for card \(index): \(explanation.prefix(50))...")
            }

            // Update benefits if available
            if let benefits = analysisDict["benefits"] as? [String], !benefits.isEmpty {
                gptAnalysis[index].benefits = benefits
                updated = true
                print("✅ Updated benefits for card \(index): \(benefits.count) items")
            }

            // Update limitations if available
            if let limitations = analysisDict["limitations"] as? [String], !limitations.isEmpty {
                gptAnalysis[index].limitations = limitations
                updated = true
                print("⚠️ Updated limitations for card \(index): \(limitations.count) items")
            }

            // Update estimated value if available
            if let estimatedValue = analysisDict["estimated_value"] as? String, !estimatedValue.isEmpty {
                gptAnalysis[index].estimated_value = estimatedValue
                updated = true
                print("💰 Updated estimated_value for card \(index): \(estimatedValue)")
            }

            if updated {
                print("🔄 Card \(index) (\(gptAnalysis[index].card_name)) updated")
            }
        }
    }

    @MainActor
    private func extractAndShowPartialContent() {
        // Extract partial content even from incomplete JSON
        extractField(pattern: "\"explanation\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"?",
                    fieldName: "explanation",
                    updateHandler: { index, value in
                        if self.gptAnalysis[index].explanation != value {
                            self.gptAnalysis[index].explanation = value
                            print("🔄 Partial explanation update for card \(index): \(value.prefix(50))...")
                        }
                    })

        extractField(pattern: "\"estimated_value\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"?",
                    fieldName: "estimated_value",
                    updateHandler: { index, value in
                        if self.gptAnalysis[index].estimated_value != value {
                            self.gptAnalysis[index].estimated_value = value
                            print("💰 Partial estimated_value update for card \(index): \(value)")
                        }
                    })

        // Extract benefits array
        extractArrayField(pattern: "\"benefits\"\\s*:\\s*\\[((?:[^\\]]|\\](?!\\s*[,}]))*)\\]?",
                         fieldName: "benefits",
                         updateHandler: { index, values in
                             if self.gptAnalysis[index].benefits != values {
                                 self.gptAnalysis[index].benefits = values
                                 print("✅ Partial benefits update for card \(index): \(values.count) items")
                             }
                         })

        // Extract limitations array
        extractArrayField(pattern: "\"limitations\"\\s*:\\s*\\[((?:[^\\]]|\\](?!\\s*[,}]))*)\\]?",
                         fieldName: "limitations",
                         updateHandler: { index, values in
                             if self.gptAnalysis[index].limitations != values {
                                 self.gptAnalysis[index].limitations = values
                                 print("⚠️ Partial limitations update for card \(index): \(values.count) items")
                             }
                         })
    }

    @MainActor
    private func extractField(pattern: String, fieldName: String, updateHandler: (Int, String) -> Void) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            print("⚠️ Failed to create regex for \(fieldName)")
            return
        }

        let range = NSRange(streamingContent.startIndex..., in: streamingContent)
        let matches = regex.matches(in: streamingContent, range: range)

        for (index, match) in matches.enumerated() {
            guard index < gptAnalysis.count,
                  match.numberOfRanges > 1,
                  let valueRange = Range(match.range(at: 1), in: streamingContent) else {
                continue
            }

            var value = String(streamingContent[valueRange])
            // Unescape JSON string content
            value = value.replacingOccurrences(of: "\\n", with: "\n")
            value = value.replacingOccurrences(of: "\\\"", with: "\"")
            value = value.replacingOccurrences(of: "\\\\", with: "\\")

            if !value.isEmpty {
                updateHandler(index, value)
            }
        }
    }

    @MainActor
    private func extractArrayField(pattern: String, fieldName: String, updateHandler: (Int, [String]) -> Void) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            print("⚠️ Failed to create regex for \(fieldName)")
            return
        }

        let range = NSRange(streamingContent.startIndex..., in: streamingContent)
        let matches = regex.matches(in: streamingContent, range: range)

        for (index, match) in matches.enumerated() {
            guard index < gptAnalysis.count,
                  match.numberOfRanges > 1,
                  let arrayRange = Range(match.range(at: 1), in: streamingContent) else {
                continue
            }

            let arrayContent = String(streamingContent[arrayRange])

            // Parse the array items from the content
            let itemPattern = "\"((?:[^\"\\\\]|\\\\.)*)\""
            guard let itemRegex = try? NSRegularExpression(pattern: itemPattern, options: [.dotMatchesLineSeparators]) else {
                continue
            }

            let itemRange = NSRange(arrayContent.startIndex..., in: arrayContent)
            let itemMatches = itemRegex.matches(in: arrayContent, range: itemRange)

            var items: [String] = []
            for itemMatch in itemMatches {
                if itemMatch.numberOfRanges > 1,
                   let itemValueRange = Range(itemMatch.range(at: 1), in: arrayContent) {
                    var item = String(arrayContent[itemValueRange])
                    // Unescape JSON string content
                    item = item.replacingOccurrences(of: "\\n", with: "\n")
                    item = item.replacingOccurrences(of: "\\\"", with: "\"")
                    item = item.replacingOccurrences(of: "\\\\", with: "\\")
                    items.append(item)
                }
            }

            if !items.isEmpty {
                updateHandler(index, items)
            }
        }
    }

    @MainActor
    private func fetchLegacyRecommendations(for types: [String]) async {
        let results = await apiService.getRecommendedCards(forTypes: types)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
        }

        if results.isEmpty {
            error = "No recommendations found."
        } else {
            recommendations = results
        }
    }
}

import Foundation

struct RewardRecommendation: Codable, Identifiable, Equatable {
    let id = UUID() // Local ID
    let card_id: String
    let card_name: String
    let issuer: String
    let value: Double
    let reward_type: String
    let reward_amount: Double
    let category: String

    private enum CodingKeys: String, CodingKey {
        case card_id, card_name, issuer, value, reward_type, reward_amount, category
    }
}

struct GPTAnalysisResponse: Codable {
    let category: String
    let types: [String]
    let analysis: [GPTAnalysisResult]
    let total_cards_analyzed: Int
}

struct GPTAnalysisResult: Codable, Identifiable, Equatable {
    let id = UUID() // Local ID
    let card_id: String
    let card_name: String
    let issuer: String
    let value: Double?
    let reward_type: String
    let reward_amount: Double?
    let category: String
    var benefits: [String]
    var explanation: String
    var limitations: [String]
    var estimated_value: String

    // For streaming - indicates if the analysis is still being generated
    var isStreaming: Bool = false

    private enum CodingKeys: String, CodingKey {
        case card_id, card_name, issuer, value, reward_type, reward_amount, category, benefits, explanation, limitations, estimated_value
    }

    // Custom initializer for creating partial results during streaming
    init(card_id: String, card_name: String, issuer: String, value: Double?, reward_type: String, reward_amount: Double?, category: String, benefits: [String] = [], explanation: String = "", limitations: [String] = [], estimated_value: String = "", isStreaming: Bool = false) {
        self.card_id = card_id
        self.card_name = card_name
        self.issuer = issuer
        self.value = value
        self.reward_type = reward_type
        self.reward_amount = reward_amount
        self.category = category
        self.benefits = benefits
        self.explanation = explanation
        self.limitations = limitations
        self.estimated_value = estimated_value
        self.isStreaming = isStreaming
    }
}

struct CardDetailsData: Codable, Equatable {
    var card_id: String
    var card_name: String
    var issuer: String
    var rewards_summary: String?
    var key_benefits: [String]?
    var reward_categories: [[String: String]]?
    var additional_benefits: [String]?
    var network: String?
}

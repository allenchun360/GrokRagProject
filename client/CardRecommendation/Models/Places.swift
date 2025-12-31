import Foundation

struct PlacesAutocompleteResponse: Codable {
    let predictions: [PlacePrediction]
}

struct PlacePrediction: Identifiable, Codable {
    let id = UUID()
    let description: String
    let placeId: String
    let types: [String]
    let structuredFormatting: StructuredFormatting

    enum CodingKeys: String, CodingKey {
        case description
        case placeId = "place_id"
        case structuredFormatting = "structured_formatting"
        case types
    }
}

struct StructuredFormatting: Codable {
    let mainText: String
    let secondaryText: String?

    enum CodingKeys: String, CodingKey {
        case mainText = "main_text"
        case secondaryText = "secondary_text"
    }
}

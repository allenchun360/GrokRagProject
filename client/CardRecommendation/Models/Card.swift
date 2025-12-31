import Foundation

struct Issuer: Codable, Identifiable, Equatable {
    let id: String
    let name: String
}

struct CardBrand: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let issuer: Issuer
    let base_point_value: String?
}

struct UserCardResponse: Codable {
    let data: [UserCard]
}

struct UserCard: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let card_number: String?
    let expiration_date: String?
    let cvv: String?
    let card_model: CardBrand
}

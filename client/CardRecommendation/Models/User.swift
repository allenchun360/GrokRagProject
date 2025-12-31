import Foundation

struct User: Codable {
    let id: String?
    let username: String
    let phoneNumber: String
    var firstName: String?
    var lastName: String?
    var email: String?
    var token: Token?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case phoneNumber = "phone_number"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case token
    }

    /// Returns true if the user has completed their profile (has both firstName and lastName)
    var hasCompletedProfile: Bool {
        guard let firstName = firstName, !firstName.trimmingCharacters(in: .whitespaces).isEmpty,
              let lastName = lastName, !lastName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        return true
    }

    struct Token: Codable {
        let access: String
        let refresh: String
    }
}

struct RegistrationResponse: Codable {
    let detail: String
    let user: User
}

struct LoginResponse: Codable {
    let message: String
    let user: User
}

struct UpdateResponse: Codable {
    let user: User
}

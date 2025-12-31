import Foundation

enum HTTPMethod: String {
    case GET, POST, PATCH, PUT, DELETE
}

struct APIRequest {
    var endpoint: String
    var method: HTTPMethod
    var parameters: [String: Any]?
    var headers: [String: String]?
    var requiresAuth: Bool = true

    func build() throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        headers?.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

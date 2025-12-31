import Foundation
import CoreLocation

struct APIErrorResponse: Codable {
    let error: String
}

class APIService {
    var onLogout: (() -> Void)?
//    private let baseURL = "https://card-recommendation-app-303961a6ebe3.herokuapp.com"
    private let baseURL = "http://localhost:8000"

    // Custom URLSession for streaming requests with 10-minute timeout
    private lazy var streamingSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 600 // 10 minutes
        config.timeoutIntervalForResource = 600 // 10 minutes
        return URLSession(configuration: config)
    }()

    // MARK: - Core Request Handlers

    private func performRequestWithAutoRefresh(_ request: APIRequest) async throws -> (Data, URLResponse) {
        var urlRequest = try request.build()
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid Response", code: -1)
        }

        if httpResponse.statusCode == 401,
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let code = json["code"] as? String,
        code == "token_not_valid" {

            print("🔐 Access token expired. Attempting to refresh...")

            try await refreshAccessToken()

            // Retry with refreshed token
            urlRequest = try request.build()
            return try await URLSession.shared.data(for: urlRequest)
        }

        return (data, response)
    }

    private func send<T: Decodable>(_ request: APIRequest, decodeTo type: T.Type) async throws -> T {
        let (data, response) = try await performRequestWithAutoRefresh(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid Response", code: -1)
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(T.self, from: data)
        } else {
            let errorMessage = extractErrorMessage(from: data)
            throw NSError(domain: errorMessage, code: httpResponse.statusCode)
        }
    }

    private func send(_ request: APIRequest) async throws -> Bool {
        let (data, response) = try await performRequestWithAutoRefresh(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid Response", code: -1)
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return true
        } else {
            let message = extractErrorMessage(from: data)
            throw NSError(domain: message, code: httpResponse.statusCode)
        }
    }

    // MARK: - Exposed API Functions

    func sendPhoneCode(phoneNumber: String, isRegister: Bool) async -> Bool {
        let request = APIRequest(
            endpoint: "\(baseURL)/send-phone-code/",
            method: .POST,
            parameters: ["phone_number": phoneNumber, "is_register": isRegister],
            requiresAuth: false
        )

        do {
            let response = try await send(request)
            return response
        } catch {
            show(error: error, title: isRegister ? "Phone number already in use" : "Please try again!")
            return false
        }
    }

    func verifyPhoneCodeForRegistration(phoneNumber: String, code: String) async throws -> User {
        let request = APIRequest(
            endpoint: "\(baseURL)/register-verify-phone-code/",
            method: .PATCH,
            parameters: ["phone_number": phoneNumber, "code": code],
            requiresAuth: false
        )

        do {
            let response: RegistrationResponse = try await send(request, decodeTo: RegistrationResponse.self)
            return response.user
        } catch {
            show(error: error, title: "Please try again!")
            throw error
        }
    }

    func verifyPhoneCodeForLogin(phoneNumber: String, code: String) async throws -> User {
        let request = APIRequest(
            endpoint: "\(baseURL)/login-verify-phone-code/",
            method: .PATCH,
            parameters: ["phone_number": phoneNumber, "code": code],
            requiresAuth: false
        )

        do {
            let response: LoginResponse = try await send(request, decodeTo: LoginResponse.self)
            return response.user
        } catch {
            show(error: error, title: "Please try again!")
            throw error
        }
    }

    func getUserProfile() async throws -> User {
        let request = APIRequest(
            endpoint: "\(baseURL)/get-user",
            method: .GET
        )
        return try await send(request, decodeTo: User.self)
    }

    func updateUserProfile(user: User) async throws -> User {
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        let request = APIRequest(
            endpoint: "\(baseURL)/update-user/",
            method: .PATCH,
            parameters: try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let response: UpdateResponse = try await send(request, decodeTo: UpdateResponse.self)
        return response.user
    }

    func deleteUserAccount() async throws -> Bool {
        let request = APIRequest(
            endpoint: "\(baseURL)/delete-user/",
            method: .DELETE
        )
        return try await send(request)
    }

    func getAllCards() async -> [CardBrand] {
        let request = APIRequest(
            endpoint: "\(baseURL)/cards/",
            method: .GET
        )

        do {
            let cards = try await send(request, decodeTo: [CardBrand].self)
            return cards
        } catch {
            show(error: error, title: "Failed to fetch cards")
            return []
        }
    }

    func getUserCards() async -> [UserCard] {
        let request = APIRequest(
            endpoint: "\(baseURL)/user-cards/",
            method: .GET
        )

        do {
            let userCards = try await send(request, decodeTo: [UserCard].self)
            return userCards
        } catch {
            show(error: error, title: "Failed to fetch cards")
            return []
        }
    }

    func createUserCards(cardIDs: [String]) async -> [UserCard] {
        let request = APIRequest(
            endpoint: "\(baseURL)/create-user-cards/",
            method: .POST,
            parameters: ["card_ids": cardIDs]
        )

        do {
            let response = try await send(request, decodeTo: UserCardResponse.self)
            let cardCount = response.data.count
            showSuccess(message: "You successfully added \(cardCount) cards", title: "Cards added")
            return response.data
        } catch {
            show(error: error, title: "Failed to add cards")
            return []
        }
    }

    func deleteUserCard(id: String) async -> Bool {
        let request = APIRequest(
            endpoint: "\(baseURL)/delete-user-card/\(id)/",
            method: .DELETE
        )

        do {
            let success = try await send(request)
            return success
        } catch {
            show(error: error, title: "Failed to delete card")
            return false
        }
    }

    func getNearbyStores(latitude: Double, longitude: Double, radius: Int = 100) async -> [Store] {
        let queryParams = "lat=\(latitude)&lng=\(longitude)&radius=\(radius)"
        let request = APIRequest(
            endpoint: "\(baseURL)/get-nearby-stores/?\(queryParams)",
            method: .GET
        )

        do {
            let response: BackendStoreResponse = try await send(request, decodeTo: BackendStoreResponse.self)
            print(response.stores)
            return response.stores.map {
                Store(
                    name: $0.name,
                    logo: "", // placeholder
                    categories: $0.categories,
                    coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                    address: $0.address,
                    distance: $0.distance
                )
            }
        } catch {
            return []
        }
    }

    func getOnlineStores() async -> [OnlineStore] {
        let request = APIRequest(
            endpoint: "\(baseURL)/get-online-stores/",
            method: .GET
        )

        do {
            let response: BackendOnlineStoreResponse = try await send(request, decodeTo: BackendOnlineStoreResponse.self)
            print(response.stores)
            return response.stores.map {
                OnlineStore(
                    name: $0.name,
                    logo: "", // placeholder
                    categories: $0.categories,
                    address: $0.address
                )
            }
        } catch {
            show(error: error, title: "Failed to get online stores")
            print(error)
            return []
        }
    }

    func getRecommendedCards(forTypes types: [String]) async -> [RewardRecommendation] {
        let query = types.map { "types=\($0)" }.joined(separator: "&")
        let request = APIRequest(
            endpoint: "\(baseURL)/get-card-benefits-by-types/?\(query)",
            method: .GET
        )

        do {
            let rewards = try await send(request, decodeTo: [RewardRecommendation].self)
            print(rewards)
            return rewards
        } catch {
            show(error: error, title: "Failed to get recommendations")
            return []
        }
    }

    func analyzeCardsWithGPT(forTypes types: [String], storeName: String, storeAddress: String) async -> GPTAnalysisResponse? {
        var queryParams = types.map { "types=\($0)" }
        queryParams.append("store_name=\(storeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? storeName)")
        queryParams.append("store_address=\(storeAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? storeAddress)")
        let query = queryParams.joined(separator: "&")
        let request = APIRequest(
            endpoint: "\(baseURL)/analyze-cards-with-gpt/?\(query)",
            method: .GET
        )

        do {
            let response = try await send(request, decodeTo: GPTAnalysisResponse.self)
            return response
        } catch {
            show(error: error, title: "Failed to analyze cards with GPT")
            return nil
        }
    }

    func analyzeCardsWithGPTStreaming(
        forTypes types: [String],
        storeName: String,
        storeAddress: String,
        onRankingReceived: @escaping ([RewardRecommendation]) -> Void,
        onChunkReceived: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) async {
        var queryParams = types.map { "types=\($0)" }
        queryParams.append("store_name=\(storeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? storeName)")
        queryParams.append("store_address=\(storeAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? storeAddress)")
        let query = queryParams.joined(separator: "&")

        let request = APIRequest(
            endpoint: "\(baseURL)/analyze-cards-with-gpt-streaming/?\(query)",
            method: .GET
        )

        do {
            var urlRequest = try request.build()
            var (bytes, response) = try await streamingSession.bytes(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Invalid Response", code: -1)
            }

            // Handle 401 token expiration
            if httpResponse.statusCode == 401 {
                print("🔐 Access token expired for streaming. Attempting to refresh...")
                try await refreshAccessToken()

                // Retry with refreshed token
                urlRequest = try request.build()
                (bytes, response) = try await streamingSession.bytes(for: urlRequest)

                guard let retryResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "Invalid Response", code: -1)
                }

                guard (200..<300).contains(retryResponse.statusCode) else {
                    throw NSError(domain: "HTTP Error", code: retryResponse.statusCode)
                }
            } else if !(200..<300).contains(httpResponse.statusCode) {
                throw NSError(domain: "HTTP Error", code: httpResponse.statusCode)
            }

            var accumulatedContent = ""
            var rankingSent = false

            for try await line in bytes.lines {
                // Server-Sent Events format: "data: {...}"
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))

                    if let data = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                        // Check if this is a chunk of the streaming response
                        if let chunk = json["chunk"] as? String {
                            accumulatedContent += chunk
                            print("📦 Received chunk (\(chunk.count) chars). Total: \(accumulatedContent.count) chars")

                            await MainActor.run {
                                onChunkReceived(chunk)
                            }

                            // Try to parse ranking from accumulated content if not yet sent
                            if !rankingSent {
                                if let ranking = parseRankingFromAccumulatedContent(accumulatedContent) {
                                    print("🏆 Ranking parsed: \(ranking.count) cards")
                                    await MainActor.run {
                                        onRankingReceived(ranking)
                                    }
                                    rankingSent = true
                                }
                            }
                        }

                        // Check if streaming is complete
                        if let done = json["done"] as? Bool, done {
                            if let fullResponse = json["full_response"] as? String {
                                print("✅ Streaming complete. Total length: \(fullResponse.count) chars")
                                print("📄 Full response preview: \(fullResponse.prefix(200))...")
                                await MainActor.run {
                                    onComplete(fullResponse)
                                }
                            }
                        }

                        // Check for errors
                        if let error = json["error"] as? String {
                            print("❌ Streaming error: \(error)")
                            throw NSError(domain: error, code: -1)
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                onError(error)
                show(error: error, title: "Failed to stream GPT analysis")
            }
        }
    }

    private func parseRankingFromAccumulatedContent(_ content: String) -> [RewardRecommendation]? {
        // Try to extract the ranking array from the accumulated JSON content
        // Look for "ranking": [...] pattern
        guard let rankingRange = content.range(of: "\"ranking\"\\s*:\\s*\\[", options: .regularExpression) else {
            return nil
        }

        // Find the matching closing bracket for the ranking array
        let startIndex = content.index(rankingRange.upperBound, offsetBy: -1)
        var bracketCount = 0
        var endIndex: String.Index?

        for index in content[startIndex...].indices {
            let char = content[index]
            if char == "[" {
                bracketCount += 1
            } else if char == "]" {
                bracketCount -= 1
                if bracketCount == 0 {
                    endIndex = index
                    break
                }
            }
        }

        guard let endIndex = endIndex else {
            return nil
        }

        let rankingJson = String(content[startIndex...endIndex])

        // The ranking contains simplified card info, so we need to convert it
        guard let data = rankingJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }

        // Convert ranking items to RewardRecommendation with placeholder values
        let recommendations = json.compactMap { item -> RewardRecommendation? in
            guard let cardId = item["card_id"] as? String,
                  let cardName = item["card_name"] as? String,
                  let issuer = item["issuer"] as? String else {
                return nil
            }

            // Create placeholder recommendation - values will be filled in by streaming analysis
            return RewardRecommendation(
                card_id: cardId,
                card_name: cardName,
                issuer: issuer,
                value: item["value"] as? Double ?? 0.0,
                reward_type: item["reward_type"] as? String ?? "",
                reward_amount: item["reward_amount"] as? Double ?? 0.0,
                category: item["category"] as? String ?? ""
            )
        }

        return recommendations.isEmpty ? nil : recommendations
    }

    func getCardDetailsStreaming(
        cardId: String,
        onChunkReceived: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) async {
        let request = APIRequest(
            endpoint: "\(baseURL)/card-details-streaming/\(cardId)/",
            method: .GET
        )

        do {
            var urlRequest = try request.build()
            var (bytes, response) = try await streamingSession.bytes(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Invalid Response", code: -1)
            }

            // Handle 401 token expiration
            if httpResponse.statusCode == 401 {
                print("🔐 Access token expired for streaming. Attempting to refresh...")
                try await refreshAccessToken()

                // Retry with refreshed token
                urlRequest = try request.build()
                (bytes, response) = try await streamingSession.bytes(for: urlRequest)

                guard let retryResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "Invalid Response", code: -1)
                }

                guard (200..<300).contains(retryResponse.statusCode) else {
                    throw NSError(domain: "HTTP Error", code: retryResponse.statusCode)
                }
            } else if !(200..<300).contains(httpResponse.statusCode) {
                throw NSError(domain: "HTTP Error", code: httpResponse.statusCode)
            }

            var accumulatedContent = ""

            for try await line in bytes.lines {
                // Server-Sent Events format: "data: {...}"
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))

                    if let data = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                        // Check if this is a chunk of the streaming response
                        if let chunk = json["chunk"] as? String {
                            accumulatedContent += chunk
                            print("📦 Received chunk (\(chunk.count) chars). Total: \(accumulatedContent.count) chars")

                            await MainActor.run {
                                onChunkReceived(chunk)
                            }
                        }

                        // Check if streaming is complete
                        if let done = json["done"] as? Bool, done {
                            if let fullResponse = json["full_response"] as? String {
                                print("✅ Streaming complete. Total length: \(fullResponse.count) chars")
                                await MainActor.run {
                                    onComplete(fullResponse)
                                }
                            }
                        }

                        // Check for errors
                        if let error = json["error"] as? String {
                            print("❌ Streaming error: \(error)")
                            throw NSError(domain: error, code: -1)
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                onError(error)
                show(error: error, title: "Failed to stream card details")
            }
        }
    }

    func refreshAccessToken() async throws {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            throw NSError(domain: "No refresh token stored", code: 401)
        }

        let request = APIRequest(
            endpoint: "\(baseURL)/api/token/refresh/",
            method: .POST,
            parameters: ["refresh": refreshToken],
            requiresAuth: false
        )

        struct RefreshResponse: Codable {
            let access: String
            let refresh: String
        }

        do {
            let urlRequest = try request.build()
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Invalid Response", code: -1)
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: errorMessage, code: httpResponse.statusCode)
            }

            let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
            UserDefaults.standard.set(decoded.access, forKey: "accessToken")
            UserDefaults.standard.set(decoded.refresh, forKey: "refreshToken")
            print("🔄 Token refreshed successfully")
        } catch {
            print("❌ Failed to refresh token: \(error.localizedDescription)")
            onLogout?()
            throw error
        }
    }

    // MARK: - Utility

    private func extractErrorMessage(from data: Data) -> String {
        if let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            return decoded.error
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }

    private func show(error: Error, title: String = "Error") {
        let message: String

        if let nsError = error as NSError? {
            message = nsError.domain
        } else {
            message = error.localizedDescription
        }
        Task { @MainActor in
            NotificationManager.shared.show(
                title: title,
                description: message,
                backgroundColor: .red
            )
        }
    }

    private func showSuccess(message: String, title: String = "Success") {
        Task { @MainActor in
            NotificationManager.shared.show(
                title: title,
                description: message,
                backgroundColor: .blue
            )
        }
    }
}

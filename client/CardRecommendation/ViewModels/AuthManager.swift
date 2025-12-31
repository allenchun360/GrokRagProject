import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var registeredName: Bool = false
    @Published var completed: Bool = false
    @Published var allCards: [CardBrand] = []
    @Published var userCards: [UserCard] = []
    
    private let apiService = APIService()
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        apiService.onLogout = { [weak self] in
            Task { @MainActor in
                self?.logout()
            }
        }
        loadSavedUser()
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? encoder.encode(user) {
            userDefaults.set(encoded, forKey: "currentUser")
            if let accessToken = user.token?.access {
                userDefaults.set(accessToken, forKey: "accessToken")
            }
            if let refreshToken = user.token?.refresh {
                userDefaults.set(refreshToken, forKey: "refreshToken")
            }
            self.currentUser = user
            self.isAuthenticated = true
            Task {
                await loadAllCards()
            }
        }
    }

    private func loadSavedUser() {
        if let userData = userDefaults.data(forKey: "currentUser") {
            if let user = try? decoder.decode(User.self, from: userData) {
                self.currentUser = user
                self.isAuthenticated = true
                if user.hasCompletedProfile {
                    Task {
                        await loadAllCards()
                    }
                    self.registeredName = true
                    self.completed = true
                }
            }
        }
        if let cardData = userDefaults.data(forKey: "userCards") {
            if let userCards = try? decoder.decode([UserCard].self, from: cardData) {
                self.userCards = userCards
            }
        }
    }

    func logout() {
        userDefaults.removeObject(forKey: "currentUser")
        userDefaults.removeObject(forKey: "accessToken")
        userDefaults.removeObject(forKey: "refreshToken")
        
        self.currentUser = nil
        self.isAuthenticated = false
        self.registeredName = false
        self.completed = false
    }
    
    func sendPhoneCode(phoneNumber: String, isRegister: Bool) async -> Bool {
        self.isLoading = true
        self.error = nil

        let cleanedPhoneNumber = cleanPhoneNumber(phoneNumberString: phoneNumber)

        let result = await apiService.sendPhoneCode(phoneNumber: cleanedPhoneNumber, isRegister: isRegister)
        self.isLoading = false

        if result {
            return true
        } else {
            self.error = "Failed to send verification code. Please try again."
            return false
        }
    }
    
    func register(phoneNumber: String, code: String) async -> Bool {
        self.isLoading = true
        self.error = nil

        let cleanedPhoneNumber = cleanPhoneNumber(phoneNumberString: phoneNumber)

        do {
            let user = try await apiService.verifyPhoneCodeForRegistration(phoneNumber: cleanedPhoneNumber, code: code)
            self.saveUser(user)
            self.isLoading = false
            return true
        } catch {
            self.isLoading = false
            self.error = error.localizedDescription
            return false
        }
    }

    func login(phoneNumber: String, code: String) async -> Bool {
        self.isLoading = true
        self.error = nil

        let cleanedPhoneNumber = cleanPhoneNumber(phoneNumberString: phoneNumber)

        do {
            let user = try await apiService.verifyPhoneCodeForLogin(phoneNumber: cleanedPhoneNumber, code: code)
            self.saveUser(user)
            self.isLoading = false
            return true
        } catch {
            self.isLoading = false
            self.error = error.localizedDescription
            return false
        }
    }

    func updateProfile(updatedUser: User) async -> Bool {
        self.isLoading = true
        self.error = nil

        do {
            print(updatedUser)
            let user = try await apiService.updateUserProfile(user: updatedUser)
            self.saveUser(user)
            self.isLoading = false
            return true
        } catch {
            self.isLoading = false
            self.error = error.localizedDescription
            return false
        }
    }

    func deleteAccount() async -> Bool {
        self.isLoading = true
        self.error = nil

        do {
            let success = try await apiService.deleteUserAccount()
            self.isLoading = false

            if success {
                self.logout()
                return true
            } else {
                self.error = "Failed to delete account. Please try again."
                return false
            }
        } catch {
            self.isLoading = false
            self.error = error.localizedDescription
            return false
        }
    }

    func loadAllCards() async {
        self.isLoading = true

        let cards = await apiService.getAllCards()
        self.isLoading = false
        self.allCards = cards
    }

    func getUserCards() async -> Bool {
        self.isLoading = true
        self.error = nil

        let cards = await apiService.getUserCards()
        self.isLoading = false

        self.userCards = cards
        return !cards.isEmpty
    }

    func createUserCards(cardIDs: [String]) async -> Bool {
        self.isLoading = true
        self.error = nil

        let cards = await apiService.createUserCards(cardIDs: cardIDs)
        self.isLoading = false

        if let encoded = try? encoder.encode(cards) {
            userDefaults.set(encoded, forKey: "userCards")
        }

        self.userCards = cards
        return true
    }
    
    func deleteUserCard(cardID: String) async -> Bool {
        self.isLoading = true
        self.error = nil

        let success = await apiService.deleteUserCard(id: cardID)
        self.isLoading = false

        if success {
            if let data = userDefaults.data(forKey: "userCards") {
                if var storedCards = try? decoder.decode([UserCard].self, from: data) {
                    // Remove just the matching card from stored list
                    storedCards.removeAll { $0.id == cardID }

                    if let encoded = try? encoder.encode(storedCards) {
                        userDefaults.set(encoded, forKey: "userCards")
                    }
                }
            }

            return true
        } else {
            self.error = "Failed to delete card"
            return false
        }
    }
}

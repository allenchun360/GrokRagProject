import Foundation
import SwiftUI
import Combine

class OnlineStoreViewModel: ObservableObject {
    @Published var stores: [OnlineStore] = []
    @Published var isLoading: Bool = false

    private let apiService = APIService()
    private var hasFetched = false

    @MainActor
    func fetchStores() async {
        // Only fetch once unless explicitly refreshed
        if hasFetched {
            return
        }
        
        isLoading = true
        stores = await apiService.getOnlineStores()
        hasFetched = true
        isLoading = false
    }

    @MainActor
    func refreshStores() async {
        hasFetched = false
        isLoading = true
        stores = await apiService.getOnlineStores()
        isLoading = false
    }
}



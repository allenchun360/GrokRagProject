import SwiftUI

enum HomeNavigationType {
    case settings
    case enterCardDetails
    case searchStore
    case cardRecommendation
    case cardInfo
    case none
}

struct HomeView: View {
    @StateObject private var storeVM = StoreViewModel()
    @StateObject private var onlineStoreVM = OnlineStoreViewModel()
    @State private var activeNavigation: HomeNavigationType = .none
    @State private var safeAreaInsets = EdgeInsets()
    @State private var selectedStore: Store? = nil
    @State private var selectedCard: UserCard? = nil
    @State private var deleteCard: UserCard? = nil
    @State private var storeGridHeight: CGFloat = 0
    @State private var selectedStoreTab: StoreTab = .nearby

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    WalletView(
                        selectedCard: $deleteCard,
                        onTapCard: { card in
                            selectedCard = card
                            activeNavigation = .cardInfo
                            // Optionally also set selectedStore here
                        }
                    )

                    // Stores Section
                    StoresNearYouView(
                        storeVM: storeVM,
                        onlineStoreVM: onlineStoreVM,
                        storeGridHeight: $storeGridHeight,
                        selectedTab: $selectedStoreTab,
                        onSearchTap: {
                            activeNavigation = .searchStore
                        },
                        onStoreTap: { store in
                            selectedStore = store
                            activeNavigation = .cardRecommendation
                        },
                        onOnlineStoreTap: { onlineStore in
                            // Convert OnlineStore to Store for CardRecommendationView
                            selectedStore = onlineStore.toStore()
                            activeNavigation = .cardRecommendation
                        }
                    )
                }
            }
            .refreshable {
                // Refresh only the currently selected tab
                switch selectedStoreTab {
                case .nearby:
                    guard !storeVM.isLoading else {
                        print("🔁 Refresh ignored: already loading nearby stores")
                        return
                    }
                    await storeVM.requestFreshLocationAndFetch()
                case .online:
                    guard !onlineStoreVM.isLoading else {
                        print("🔁 Refresh ignored: already loading online stores")
                        return
                    }
                    await Task {
                        await onlineStoreVM.refreshStores()
                    }.value
                }
            }
            .onScrollPhaseChange { oldPhase, newPhase in
                if newPhase != oldPhase {
                    withAnimation {
                        deleteCard = nil
                    }
                }
            }
            .onTapGesture {
                withAnimation {
                    deleteCard = nil
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.safeAreaInsets) { oldValue, newValue in
                        safeAreaInsets = newValue
                    }
            }
        )
        .overlay(alignment: .top) {
            // change to whatever color/view you need or UIVisualEffectView to keep the blur
            Color.black
                .frame(height: safeAreaInsets.top)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea()
        }
        .toolbarBackground(Color(.black), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("BlackGrok")
                .font(.title)
                .fontWeight(.bold)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    activeNavigation = .settings
                }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.blue)
                        .font(.system(size: 17))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    activeNavigation = .enterCardDetails
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
            }
        }
        .navigationDestination(isPresented: Binding(get: {
            activeNavigation != .none
        }, set: { newValue in
            if !newValue {
                activeNavigation = .none
                deleteCard = nil
            }
        })) {
            switch activeNavigation {
            case .settings: SettingsView()
            case .searchStore: SearchStoresView()
            case .enterCardDetails: SearchCardsView()
            case .cardRecommendation:
                if let store = selectedStore {
                    CardRecommendationView(store: store)
                }
            case .cardInfo:
                if let card = selectedCard {
                    CardInfoView(userCard: card)
                }
            case .none: EmptyView()
            }
        }
    }
}

#Preview {
    HomeView()
}

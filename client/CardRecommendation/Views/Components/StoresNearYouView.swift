import SwiftUI

enum StoreTab: String, CaseIterable {
    case nearby = "Stores near you"
    case online = "Online stores"
}

struct StoresNearYouView: View {
    @ObservedObject var storeVM: StoreViewModel
    @ObservedObject var onlineStoreVM: OnlineStoreViewModel
    @Binding var storeGridHeight: CGFloat
    @Binding var selectedTab: StoreTab
    let onSearchTap: () -> Void
    let onStoreTap: (Store) -> Void
    let onOnlineStoreTap: (OnlineStore) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            VStack(spacing: 24) {
                HStack {
                    Picker("Store Type", selection: $selectedTab) {
                        ForEach(StoreTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)

                    Button(action: onSearchTap) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }

                VStack {
                    if selectedTab == .nearby {
                        nearbyStoresContent
                    } else {
                        onlineStoresContent
                    }
                }
                .frame(height: storeGridHeight)
                .clipped()
                .padding(.bottom)
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(16)
            .shadow(radius: 2)
        }
        .padding()
    }
    
    @ViewBuilder
    private var nearbyStoresContent: some View {
        if storeVM.isLoading {
            VStack {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .onHeightChange { newHeight in
                withAnimation(.linear(duration: 0.3)) {
                    storeGridHeight = newHeight
                }
            }
            .transition(.opacity)
        } else if storeVM.stores.isEmpty {
            Text("No stores found nearby.")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding()
                .onHeightChange { newHeight in
                    withAnimation(.linear(duration: 0.4)) {
                        storeGridHeight = newHeight
                    }
                }
                .transition(.opacity)
        } else {
            VStack {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ],
                    spacing: 16
                ) {
                    ForEach(storeVM.stores) { store in
                        StoreButtonView(store: store, action: {
                            onStoreTap(store)
                        })
                    }
                }
                .onHeightChange { newHeight in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        storeGridHeight = newHeight
                    }
                } // Measure height
            }
        }
    }

    @ViewBuilder
    private var onlineStoresContent: some View {
        OnlineStoresView(
            viewModel: onlineStoreVM,
            storeGridHeight: $storeGridHeight,
            onStoreTap: onOnlineStoreTap
        )
    }
}

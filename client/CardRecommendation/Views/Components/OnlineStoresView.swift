import SwiftUI

struct OnlineStoresView: View {
    @ObservedObject var viewModel: OnlineStoreViewModel
    @Binding var storeGridHeight: CGFloat
    let onStoreTap: (OnlineStore) -> Void

    var body: some View {
        Group {
            if viewModel.isLoading {
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
            } else if viewModel.stores.isEmpty {
                Text("Online stores coming soon.")
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
                        ForEach(viewModel.stores) { store in
                            OnlineStoreButtonView(store: store, action: {
                                onStoreTap(store)
                            })
                        }
                    }
                    .onHeightChange { newHeight in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            storeGridHeight = newHeight
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.fetchStores()
        }
    }
}


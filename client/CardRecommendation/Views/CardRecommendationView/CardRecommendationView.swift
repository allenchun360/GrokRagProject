import SwiftUI

struct CardRecommendationView: View {
    var store: Store
    @StateObject private var viewModel = CardRecommendationViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputActive: Bool
    @State private var spendingInput: String = "$10"
    @State private var spending: Double = 10
    @State private var maxAvailable: Double = 100
    @State private var sliderValue: Double = 10
    @State private var safeAreaInsets = EdgeInsets()
    @State private var selectedIndex = 0
    @State private var cardHeights: [Int: CGFloat] = [:]

    private var maxCardHeight: CGFloat {
        cardHeights.values.max() ?? 0 // Default height if no heights recorded yet
    }

    var disabled: Bool {
        viewModel.isLoading
    }

    var body: some View {
        VStack {
            ZStack {
                ScrollView {
                    // MARK: - Store Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.name)
                            .font(.title)
                            .bold()

                        Text(store.address)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    if !viewModel.recommendations.isEmpty {
                        TabView(selection: $selectedIndex) {
                            ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.card_id) { index, recommendedCard in
                                VStack {
                                    // Use GPT Analysis View
                                    GPTAnalysisCardView(
                                        analysis: viewModel.gptAnalysis[index],
                                        spendingInput: $spendingInput,
                                        spending: $spending,
                                        isInputActive: $isInputActive,
                                        rank: index + 1
                                    )
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                .background(
                                    GeometryReader { geometry in
                                        Color.clear
                                            .onAppear {
                                                // Store height when card appears/renders
                                                if geometry.size.height > 0 {
                                                    cardHeights[index] = geometry.size.height
                                                }
                                            }
                                            .onChange(of: geometry.size.height) { oldValue, newValue in
                                                // Update height if it changes
                                                if newValue > 0 {
                                                    cardHeights[index] = newValue
                                                }
                                            }
                                    }
                                )
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .onPreferenceChange(ViewHeightKey.self) { height in
                            // Update height for the currently visible card
                            if height > 0 {
                                cardHeights[selectedIndex] = height
                            }
                        }
                        .frame(height: maxCardHeight)
                        .onChange(of: selectedIndex) { oldValue, newValue in
                            dismissKeyboard()
                        }
                        .opacity(viewModel.isLoading ? 0 : 1)
                    }
                }
                .scrollDisabled(disabled)
                .scrollDismissesKeyboard(.immediately)
                // .refreshable {
                //     await Task {
                //         await viewModel.fetchRecommendations(for: store.categories, showLoading: false)
                //     }.value
                // }

                if viewModel.isLoading {
                    VStack {
                        ProgressView("Finding the best card...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
                }
            }

            // MARK: - Use This Card Button
            if !viewModel.isLoading && viewModel.recommendations.count > 0 {
                VStack {
                    Button(action: {
                        openAppleWallet()
                    }) {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                                .baselineOffset(10)
                            Text("Use this card")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .background(.black)
                .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeInOut(duration: 0.4), value: viewModel.isLoading)
        .onAppear {
            Task {
                await viewModel.fetchRecommendations(for: store.categories, storeName: store.name, storeAddress: store.address)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
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
            Color.black
                .frame(height: safeAreaInsets.top)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea()
        }
        .toolbarBackground(Color(.black), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isStreaming {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

import SwiftUI
import CoreLocation

struct SearchStoresView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var predictions: [PlacePrediction] = []
    @State private var selectedStore: Store?
    @StateObject var locationManager = AutocompleteLocationManager()
    @State var textFieldFocused: Bool = true

    private let apiService = PlacesAPIService()

    var body: some View {
        VStack(spacing: 24) {
            // Search Field
            SearchBar(text: $searchText, placeholder: "Search stores...", isFocused: $textFieldFocused)
                .onChange(of: searchText) { oldValue, newValue in
                    fetchAutocomplete(for: newValue)
                }

            // Autocomplete Results
            ScrollView {
                if predictions.isEmpty {
                    // Keeps ScrollView active for keyboard dismissal
                    Color.clear
                } else {
                    ForEach(predictions) { prediction in
                        Button(action: {
                            selectedStore = Store(
                                name: prediction.structuredFormatting.mainText,
                                logo: "",  // Placeholder
                                categories: prediction.types,
                                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),  // Dummy coords
                                address: prediction.structuredFormatting.secondaryText ?? "",
                                distance: 0
                            )
                            textFieldFocused = false
                        }) {
                            HStack(spacing: 16) {
                                // RoundedRectangle(cornerRadius: 8)
                                //     .fill(Color.blue.opacity(0.2))
                                //     .frame(width: 44, height: 44)
                                //     .overlay(
                                //         Image(systemName: "mappin.circle")
                                //             .foregroundColor(.blue)
                                //             .font(.system(size: 20))
                                //     )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prediction.structuredFormatting.mainText)
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .multilineTextAlignment(.leading)
                                    Text(prediction.structuredFormatting.secondaryText ?? "")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()

                        }
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .ignoresSafeArea(.keyboard)
        .padding(.top)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedStore) { store in
            CardRecommendationView(store: store)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Browse")
            }
        }
    }

    private func fetchAutocomplete(for query: String) {
        guard !query.isEmpty else {
            predictions = []
            return
        }

        let location = locationManager.currentLocation

        apiService.fetchAutocomplete(query: query, location: location) { result in
            self.predictions = result
        }
    }
}


#Preview {
    SearchStoresView()
}

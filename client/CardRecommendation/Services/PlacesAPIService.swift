import Foundation
import CoreLocation

class PlacesAPIService {
    private let apiKey = Bundle.main.infoDictionary?["GoogleAPIKey"] as? String ?? ""

    func fetchAutocomplete(query: String, location: CLLocationCoordinate2D?, radius: Int = 10000, completion: @escaping ([PlacePrediction]) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion([])
            return
        }

        var urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(encodedQuery)&key=\(apiKey)&types=establishment"
        print(urlString)

        if let loc = location {
            urlString += "&location=\(loc.latitude),\(loc.longitude)&radius=\(radius)&strictbounds"
        }

        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let data = data,
                let decoded = try? JSONDecoder().decode(PlacesAutocompleteResponse.self, from: data)
            else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            let excludedTypes: Set<String> = [
                "establishment", "point_of_interest",
                "political", "locality", "sublocality", "postal_code", "route",
                "administrative_area_level_1", "administrative_area_level_2", "country", "continent", "post_box", "archipelago",
                "intersection", "university", "school", "place_of_worship", "cemetery", "embassy", "fire_station", "police",
                "neighborhood", "campground", "synagogue", "mosque", "church", "hindu_temple", "city_hall", "courthouse", "local_government_office",
                "school", "secondary_school", "funeral_home", "natural_feature", "real_estate_agency", "park", "shopping_mall"
            ]

            let filtered = decoded.predictions.filter { prediction in
                return !prediction.types.allSatisfy { excludedTypes.contains($0) }
            }

            DispatchQueue.main.async {
                print(filtered)
                completion(filtered)
            }
        }.resume()
    }
}

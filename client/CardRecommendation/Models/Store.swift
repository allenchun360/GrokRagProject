import Foundation
import CoreLocation

struct Store: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let logo: String
    let categories: [String]
    let coordinate: CLLocationCoordinate2D
    let address: String
    let distance: Double

    static func == (lhs: Store, rhs: Store) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.logo == rhs.logo &&
        lhs.categories == rhs.categories &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.address == rhs.address &&
        lhs.distance == rhs.distance
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct BackendStoreResponse: Codable {
    let stores: [BackendStore]
}

struct BackendStore: Codable {
    let name: String
    let categories: [String]
    let latitude: Double
    let longitude: Double
    let address: String
    let distance: Double
}

struct OnlineStore: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let logo: String
    let categories: [String]
    let address: String

    static func == (lhs: OnlineStore, rhs: OnlineStore) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.logo == rhs.logo &&
        lhs.categories == rhs.categories &&
        lhs.address == rhs.address
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Convert to Store for compatibility with CardRecommendationView
    func toStore() -> Store {
        Store(
            name: self.name,
            logo: self.logo,
            categories: self.categories,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Default values for online stores
            address: self.address,
            distance: 0 // Default value for online stores
        )
    }
}

struct BackendOnlineStore: Codable {
    let name: String
    let address: String
    let categories: [String]
}

struct BackendOnlineStoreResponse: Codable {
    let stores: [BackendOnlineStore]
}

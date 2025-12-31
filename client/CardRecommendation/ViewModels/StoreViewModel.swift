import Foundation
import SwiftUI
import CoreLocation
import MapKit
import Combine

class StoreViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var stores: [Store] = []
    @Published var isLoading: Bool = true
    @Published var locationDenied: Bool = false

    private let apiService = APIService()

    private let locationManager = CLLocationManager()
    private var userLocation: CLLocationCoordinate2D?

    private var hasFetched = false
    private var isRefreshing = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        locationManager.stopUpdatingLocation()

        // Always fetch if it's a refresh; otherwise respect hasFetched
        if isRefreshing || !hasFetched {
            hasFetched = true
            isRefreshing = false
            Task {
                await fetchStores()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationDenied = true
        default:
            break
        }
    }

    @MainActor
    func fetchStores() async {
        guard let coordinate = userLocation else {
            print("No user location available. Skipping store fetch.")
            return
        }
        isLoading = true
        stores = await apiService.getNearbyStores(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }

    @MainActor
    func requestFreshLocationAndFetch() async {
        print("📍 Refresh: requesting latest location...")
        isRefreshing = true
        hasFetched = false
        locationManager.startUpdatingLocation()
    }
}

import Foundation
import CoreLocation
import Combine

/// GPS location service for gym matching
final class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var nearbyGym: Gym?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocating = false
    
    private let locationManager = CLLocationManager()
    
    static let shared = LocationService()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update every 50m
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocating() {
        isLocating = true
        locationManager.startUpdatingLocation()
    }
    
    func stopLocating() {
        isLocating = false
        locationManager.stopUpdatingLocation()
    }
    
    /// Match current location to a nearby gym via backend
    func matchNearbyGym() async {
        guard let location = currentLocation else { return }
        do {
            let gyms = try await APIService.shared.getNearbyGyms(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            await MainActor.run {
                self.nearbyGym = gyms.first
            }
        } catch {
            print("Failed to match gym: \(error)")
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                self.startLocating()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

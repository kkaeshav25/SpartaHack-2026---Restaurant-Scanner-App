import CoreLocation
import Foundation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var errorMessage: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        print("📍 LocationManager initialized")
        checkLocationAuthorization()
    }
    
    func checkLocationAuthorization() {
        let status = manager.authorizationStatus
        authorizationStatus = status
        
        switch status {
        case .notDetermined:
            print("📍 Location: Permission not determined - requesting...")
            manager.requestWhenInUseAuthorization()
        case .restricted:
            print("❌ Location: Restricted by device policy")
            errorMessage = "Location access is restricted by device policy"
        case .denied:
            print("❌ Location: User denied permission")
            errorMessage = "Location access denied. Please enable in Settings > Privacy > Location Services"
        case .authorizedAlways:
            print("✅ Location: Authorized (Always)")
            manager.startUpdatingLocation()
        case .authorizedWhenInUse:
            print("✅ Location: Authorized (When in Use)")
            manager.startUpdatingLocation()
        @unknown default:
            print("⚠️ Location: Unknown authorization status")
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let newLocation = locations.first else { return }
        print("📍 Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        location = newLocation
        errorMessage = nil
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("❌ Location error: \(error.localizedDescription)")
        errorMessage = "Failed to get location: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 Location authorization changed")
        checkLocationAuthorization()
    }
}
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var errorMessage: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthorization()
    }
    
    func checkLocationAuthorization() {
        let status = manager.authorizationStatus
        authorizationStatus = status
        
        switch status {
        case .notDetermined:
            print("📍 Location: Requesting authorization...")
            manager.requestWhenInUseAuthorization()
        case .restricted:
            print("❌ Location: Restricted")
            errorMessage = "Location access is restricted"
        case .denied:
            print("❌ Location: Denied")
            errorMessage = "Location access denied. Enable in Settings."
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ Location: Authorized")
            manager.startUpdatingLocation()
        @unknown default:
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
        print("📍 Location authorization changed: \(manager.authorizationStatus.rawValue)")
        checkLocationAuthorization()
    }
}
import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var menuURL: String?
    @State private var restaurantName: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Restaurant Menu Finder")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 40)
                
                Spacer()
                
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                }
                
                if isLoading {
                    ProgressView("Finding menu...")
                        .padding()
                }
                
                if let name = restaurantName {
                    Text("Found: \(name)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                if let url = menuURL {
                    Link(destination: URL(string: url)!) {
                        HStack {
                            Image(systemName: "menucard")
                            Text("View Menu")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button(action: {
                    showCamera = true
                    errorMessage = nil
                    menuURL = nil
                    restaurantName = nil
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Photo")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $capturedImage)
            }
            .onChange(of: capturedImage) { newImage in
                if let image = newImage, let location = locationManager.location {
                    findMenu(image: image, location: location)
                }
            }
        }
    }
    
    private func findMenu(image: UIImage, location: CLLocation) {
        isLoading = true
        errorMessage = nil
        
        fetchMenu(image: image, location: location) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    self.restaurantName = response.restaurantName
                    self.menuURL = response.menuURL
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
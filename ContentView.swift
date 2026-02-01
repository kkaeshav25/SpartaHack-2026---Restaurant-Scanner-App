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
    
    @State private var selectedTab = 0
    
    // Food craving search states
    @State private var foodCraving: String = ""
    @State private var searchResults: [RestaurantResult] = []
    @State private var searchLoading = false
    @State private var searchError: String?

    

    var body: some View {

        NavigationView {
            
            TabView(selection: $selectedTab) {
                // Tab 1: Photo to Menu
                photoSearchTab
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("Photo Search")
                    }
                    .tag(0)
                
                // Tab 2: Food Craving Search
                foodCravingTab
                    .tabItem {
                        Image(systemName: "fork.knife")
                        Text("Food Craving")
                    }
                    .tag(1)
            }
            .navigationTitle("Restaurant Finder")
        }
    }
    
    var photoSearchTab: some View {
        VStack(spacing: 20) {
            
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
        .padding(.top, 20)
        .sheet(isPresented: $showCamera) {
            CameraView(image: $capturedImage)
        }
        .onChange(of: capturedImage) { newImage in
            guard let image = newImage else { return }
            
            if let location = locationManager.location {
                findMenu(image: image, location: location)
            } else {
                self.errorMessage = "Could not get GPS location. Try again in a few seconds."
            }
        }
    }
    
    var foodCravingTab: some View {
        VStack(spacing: 20) {
            
            HStack {
                TextField("What are you craving?", text: $foodCraving)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: performFoodSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.trailing)
            }
            
            if searchLoading {
                ProgressView("Searching...")
                    .padding()
            }
            
            if let error = searchError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            if !searchResults.isEmpty {
                List(searchResults, id: \.place_id) { restaurant in
                    NavigationLink(destination: RestaurantMenuView(restaurant: restaurant)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(restaurant.name)
                                .font(.headline)
                            
                            HStack(spacing: 15) {
                                if restaurant.rating > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.orange)
                                        Text(String(format: "%.1f", restaurant.rating))
                                            .font(.subheadline)
                                    }
                                }
                                
                                if restaurant.price_level > 0 {
                                    HStack(spacing: 2) {
                                        ForEach(0..<restaurant.price_level, id: \.self) { _ in
                                            Text("$")
                                                .font(.subheadline)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if let openNow = restaurant.open_now {
                                    Text(openNow ? "Open" : "Closed")
                                        .font(.caption)
                                        .foregroundColor(openNow ? .green : .red)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            } else if !foodCraving.isEmpty && !searchLoading && searchError == nil {
                VStack {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Tap search to find restaurants")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.top, 10)
    }
    
    private func performFoodSearch() {
        guard !foodCraving.isEmpty else {
            searchError = "Please enter a food type"
            return
        }
        
        guard let location = locationManager.location else {
            searchError = "Location not available. Try again in a few seconds."
            return
        }
        
        searchLoading = true
        searchError = nil
        
        searchRestaurants(foodCraving: foodCraving, location: location) { result in
            DispatchQueue.main.async {
                searchLoading = false
                switch result {
                case .success(let response):
                    searchResults = response.results
                case .failure(let error):
                    searchError = error.localizedDescription
                    searchResults = []
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
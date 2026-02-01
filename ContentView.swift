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
    @State private var searchResults: DirectionsResponse? = nil
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
                ProgressView("Finding \(foodCraving) nearby...")
                    .padding()
            }
            
            if let error = searchError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            if let directions = searchResults {
                // Show directions
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Restaurant header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.orange)
                                Text(directions.restaurant_name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            if !directions.restaurant_address.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text(directions.restaurant_address)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Distance and duration summary
                        VStack(spacing: 12) {
                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Distance")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(formatDistance(directions.total_distance))
                                        .font(.headline)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Duration")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(formatDuration(directions.total_duration))
                                        .font(.headline)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                        
                        // Directions steps
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Directions (\(directions.steps.count) steps)")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(directions.steps.enumerated()), id: \.offset) { index, step in
                                DirectionStepCard(
                                    stepNumber: index + 1,
                                    step: step
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.vertical)
                }
            } else if !foodCraving.isEmpty && !searchLoading && searchError == nil {
                VStack {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Tap search to find directions")
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
        
        fetchDirections(foodCraving: foodCraving, location: location) { result in
            DispatchQueue.main.async {
                searchLoading = false
                switch result {
                case .success(let directions):
                    searchResults = directions
                case .failure(let error):
                    searchError = error.localizedDescription
                    searchResults = nil
                }
            }
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return String(format: "%.0f m", meters)
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins) min"
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

struct DirectionStepCard: View {
    let stepNumber: Int
    let step: DirectionStep
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Step number badge
                Text("\(stepNumber)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.blue)
                    .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.instruction)
                        .font(.subheadline)
                        .lineLimit(isExpanded ? .max : 2)
                    
                    // Distance and duration info
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(formatDistance(step.distance))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(formatDuration(step.duration))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return String(format: "%.0f m", meters)
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(Int(seconds)) sec"
        }
    }
}
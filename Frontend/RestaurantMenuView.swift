import SwiftUI
import CoreLocation

struct RestaurantMenuView: View {
    let restaurant: RestaurantResult
    let userLocation: CLLocation
    let foodCraving: String?  // The food type they searched for (e.g., "Pizza", "Kimchi")
    
    var body: some View {
        VStack(spacing: 20) {
            // Food Craving Type (if available)
            if let craving = foodCraving {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You searched for:")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fontWeight(.semibold)
                    
                    Text(craving)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBlue).opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
            }
            
            // Restaurant Header
            VStack(alignment: .leading, spacing: 12) {
                Text(restaurant.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Rating and Price Level
                HStack(spacing: 20) {
                    if restaurant.rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", restaurant.rating))
                                .font(.subheadline)
                                .fontWeight(.semibold)
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
                    
                    if let openNow = restaurant.open_now {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(openNow ? .green : .red)
                            Text(openNow ? "Open Now" : "Closed")
                                .font(.subheadline)
                                .foregroundColor(openNow ? .green : .red)
                        }
                    }
                }
                
                // Distance
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text(String(format: "%.1f m away", restaurant.distance_meters))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
}

// Supporting structures
struct MenuItem: Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let category: String
    let image_url: String?
    let available: Bool
}

struct MenuItemsResponse: Codable {
    let store_id: String
    let restaurant_name: String
    let items: [MenuItem]
    let total_items: Int
}

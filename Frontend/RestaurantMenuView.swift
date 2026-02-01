import SwiftUI

struct RestaurantMenuView: View {
    let restaurant: RestaurantResult
    let userLocation: CLLocation
    
    @State private var menuItems: [MenuItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchQuery = ""
    @State private var selectedItems: [MenuItem: Int] = [:]
    @State private var showQuote = false
    @State private var deliveryQuote: DeliveryQuote?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    if restaurant.rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
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
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 2)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search menu items", text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Menu items list
            if isLoading {
                Spacer()
                ProgressView("Loading menu...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(filteredMenuItems, id: \.id) { item in
                        MenuItemRow(
                            item: item,
                            quantity: selectedItems[item] ?? 0,
                            onAdd: { addItem(item) },
                            onRemove: { removeItem(item) }
                        )
                    }
                }
            }
            
            // Cart summary
            if !selectedItems.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Text("Subtotal")
                            .fontWeight(.medium)
                        Spacer()
                        Text("$\(String(format: "%.2f", subtotal))")
                            .fontWeight(.bold)
                    }
                    
                    Button(action: { showQuote = true }) {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("Get Delivery Quote")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(radius: 5)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMenu()
        }
        .sheet(isPresented: $showQuote) {
            if let quote = deliveryQuote {
                DeliveryQuoteView(quote: quote, restaurant: restaurant)
            } else {
                LoadingQuoteView(onLoad: calculateQuote)
            }
        }
    }
    
    var filteredMenuItems: [MenuItem] {
        if searchQuery.isEmpty {
            return menuItems
        }
        return menuItems.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.description.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var subtotal: Double {
        selectedItems.reduce(0) { total, item in
            total + (item.key.price * Double(item.value))
        }
    }
    
    func loadMenu() {
        isLoading = true
        errorMessage = nil
        
        fetchRestaurantMenu(
            restaurantName: restaurant.name,
            location: userLocation
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    menuItems = response.items.sorted { $0.price < $1.price }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addItem(_ item: MenuItem) {
        selectedItems[item, default: 0] += 1
    }
    
    func removeItem(_ item: MenuItem) {
        if let count = selectedItems[item], count > 0 {
            if count == 1 {
                selectedItems.removeValue(forKey: item)
            } else {
                selectedItems[item] = count - 1
            }
        }
    }
    
    func calculateQuote() {
        // Calculate delivery quote
        // This would call the backend endpoint
        // For now, showing placeholder
        deliveryQuote = DeliveryQuote(
            subtotal: subtotal,
            delivery_fee: 3.99,
            service_fee: subtotal * 0.15,
            tax: subtotal * 0.08,
            total: subtotal + 3.99 + (subtotal * 0.15) + (subtotal * 0.08),
            estimated_delivery_time: 30
        )
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    let quantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Item image
            if let imageUrl = item.image_url, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Text("$\(String(format: "%.2f", item.price))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Add/remove buttons
            if quantity > 0 {
                HStack(spacing: 12) {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                    
                    Text("\(quantity)")
                        .font(.headline)
                        .frame(minWidth: 20)
                    
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(item.available ? 1.0 : 0.5)
    }
}

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

struct DeliveryQuote: Codable {
    let subtotal: Double
    let delivery_fee: Double
    let service_fee: Double
    let tax: Double
    let total: Double
    let estimated_delivery_time: Int
}

struct DeliveryQuoteView: View {
    let quote: DeliveryQuote
    let restaurant: RestaurantResult
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Delivery Quote")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(restaurant.name)
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                VStack(spacing: 16) {
                    QuoteRow(label: "Subtotal", amount: quote.subtotal)
                    QuoteRow(label: "Delivery Fee", amount: quote.delivery_fee)
                    QuoteRow(label: "Service Fee", amount: quote.service_fee)
                    QuoteRow(label: "Tax", amount: quote.tax)
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("$\(String(format: "%.2f", quote.total))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("Estimated delivery: \(quote.estimated_delivery_time) min")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                Spacer()
                
                Button(action: {}) {
                    Text("Order on DoorDash")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct QuoteRow: View {
    let label: String
    let amount: Double
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text("$\(String(format: "%.2f", amount))")
                .fontWeight(.medium)
        }
    }
}

struct LoadingQuoteView: View {
    let onLoad: () -> Void
    
    var body: some View {
        VStack {
            ProgressView("Calculating delivery quote...")
                .padding()
        }
        .onAppear(perform: onLoad)
    }
}

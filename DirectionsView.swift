import SwiftUI
import CoreLocation
struct DirectionsView: View {
    let directions: DirectionsResponse
    let userLocation: CLLocation
    
    @State private var selectedTravelMode = "driving"
    let travelModes = ["driving", "walking", "bicycling", "transit"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with restaurant info
            VStack(alignment: .leading, spacing: 12) {
                Text(directions.restaurant_name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !directions.restaurant_address.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text(directions.restaurant_address)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                // Distance and duration summary
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 2)
            
            // Travel mode selector
            HStack(spacing: 10) {
                Text("Travel Mode:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Picker("", selection: $selectedTravelMode) {
                    ForEach(travelModes, id: \.self) { mode in
                        HStack(spacing: 4) {
                            Image(systemName: getTravelModeIcon(mode))
                            Text(mode.capitalized)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Directions list
            List {
                ForEach(Array(directions.steps.enumerated()), id: \.offset) { index, step in
                    DirectionStepRow(
                        stepNumber: index + 1,
                        step: step
                    )
                }
            }
            
            // Footer with action button
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "location.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Distance")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formatDistance(directions.total_distance))
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Link(destination: URL(string: "maps://")!) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Open in Maps")
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
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func getTravelModeIcon(_ mode: String) -> String {
        switch mode {
        case "driving":
            return "car.fill"
        case "walking":
            return "figure.walk"
        case "bicycling":
            return "bicycle"
        case "transit":
            return "bus.fill"
        default:
            return "car.fill"
        }
    }
}

struct DirectionStepRow: View {
    let stepNumber: Int
    let step: DirectionStep
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main instruction
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
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets())
        .background(Color(.systemBackground))
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

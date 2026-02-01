import Foundation
import UIKit
import CoreLocation

struct MenuResponse: Codable {
    let restaurant: String
    let menuURL: String 
    enum CodingKeys: String, CodingKey {
        case restaurant
        case menuURL = "menu_url"
    } 
    var restaurantName: String { restaurant }
}

struct RestaurantResult: Codable {
    let name: String
    let place_id: String
    let rating: Double
    let price_level: Int
    let distance_meters: Double
    let open_now: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case place_id
        case rating
        case price_level
        case distance_meters
        case open_now
    }
}

struct SearchResponse: Codable {
    let results: [RestaurantResult]
    let total_found: Int
}
enum MenuError: LocalizedError {
    case invalidImage
    case noLocation
    case networkError(String)
    case decodingError
    case serverError(String)
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process the image"
        case .noLocation: return "Location not available"
        case .networkError(let msg): return "Network error: \(msg)"
        case .decodingError: return "Could not parse server response"
        case .serverError(let msg): return msg
        }

    }

}

func searchRestaurants(
    foodCraving: String,
    location: CLLocation,
    completion: @escaping (Result<SearchResponse, MenuError>) -> Void
) {
    let body: [String: Any] = [
        "food_craving": foodCraving,
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude
    ]

    guard let url = URL(string: "https://shirley-fluidal-josette.ngrok-free.dev/search") else {
        completion(.failure(.networkError("Invalid URL")))
        return
    }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.timeoutInterval = 180

    do {
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
    } catch {
        completion(.failure(.networkError("Could not encode request")))
        return
    }

    URLSession.shared.dataTask(with: req) { data, response, error in
        if let error = error {
            completion(.failure(.networkError(error.localizedDescription)))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
              let data = data else {
            completion(.failure(.networkError("Invalid response")))
            return
        }

        if httpResponse.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? String {
                completion(.failure(.serverError(detail)))
            } else {
                completion(.failure(.serverError("Server error: \(httpResponse.statusCode)")))
            }
            return
        }

        do {
            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            completion(.success(searchResponse))
        } catch {
            completion(.failure(.decodingError))
        }
    }.resume()
}

func fetchMenu(
    image: UIImage,

    location: CLLocation,

    completion: @escaping (Result<MenuResponse, MenuError>) -> Void

) {
    guard let img64 = base64(image) else {

        completion(.failure(.invalidImage))

        return

    }
    let body: [String: Any] = [
        "image_base64": img64,

        "latitude": location.coordinate.latitude,

        "longitude": location.coordinate.longitude

    ]



    // TODO: Replace with your actual backend URL

    // Local: "http://localhost:8000/menu"

    // Production: "https://your-app.railway.app/menu"

    // Make sure to add "/menu" at the end!

    guard let url = URL(string: "https://shirley-fluidal-josette.ngrok-free.dev/menu") else {

        completion(.failure(.networkError("Invalid URL")))

        return

    }

    

    var req = URLRequest(url: url)

    req.httpMethod = "POST"

    req.setValue("application/json", forHTTPHeaderField: "Content-Type")

    req.timeoutInterval = 180

    

    do {

        req.httpBody = try JSONSerialization.data(withJSONObject: body)

    } catch {

        completion(.failure(.networkError("Could not encode request")))

        return

    }



    URLSession.shared.dataTask(with: req) { data, response, error in

        if let error = error {

            completion(.failure(.networkError(error.localizedDescription)))

            return

        }

        

        guard let httpResponse = response as? HTTPURLResponse,

              let data = data else {

            completion(.failure(.networkError("Invalid response")))

            return

        }

        

        if httpResponse.statusCode != 200 {

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],

               let detail = json["detail"] as? String {

                completion(.failure(.serverError(detail)))

            } else {

                completion(.failure(.serverError("Server error: \(httpResponse.statusCode)")))

            }

            return

        }

        

        do {

            let decoder = JSONDecoder()

            let menuResponse = try decoder.decode(MenuResponse.self, from: data)

            completion(.success(menuResponse))

        } catch {

            completion(.failure(.decodingError))

        }

    }.resume()

}

func base64(_ image: UIImage) -> String? {

    image.jpegData(compressionQuality: 0.7)?.base64EncodedString()

}
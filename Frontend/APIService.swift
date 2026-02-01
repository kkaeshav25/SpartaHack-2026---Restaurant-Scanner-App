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

enum MenuError: LocalizedError {
    case networkError(String)
    case serverError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .networkError(let msg):
            return "Network Error: \(msg)"
        case .serverError(let msg):
            return "Server Error: \(msg)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

func fetchMenu(
    image: UIImage,
    location: CLLocation,
    completion: @escaping (Result<MenuResponse, MenuError>) -> Void
) {
    guard let img64 = base64(image) else {
        completion(.failure(.networkError("Could not encode image")))
        return
    }

    let body: [String: Any] = [
        "image_base64": img64,
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude
    ]

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

func searchRestaurants(
    foodCraving: String,
    location: CLLocation,
    completion: @escaping (Result<RestaurantSearchResponse, MenuError>) -> Void
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
            let response = try decoder.decode(RestaurantSearchResponse.self, from: data)
            completion(.success(response))
        } catch {
            completion(.failure(.decodingError))
        }
    }.resume()
}

func base64(_ image: UIImage) -> String? {
    image.jpegData(compressionQuality: 0.7)?.base64EncodedString()
}
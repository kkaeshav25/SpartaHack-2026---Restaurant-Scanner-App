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
    guard let url = URL(string: "http://localhost:8000/menu") else {
        completion(.failure(.networkError("Invalid URL")))
        return
    }
    
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.timeoutInterval = 30
    
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
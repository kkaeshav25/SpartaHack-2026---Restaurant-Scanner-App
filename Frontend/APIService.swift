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
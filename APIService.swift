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
    
    // Log image size for debugging
    let base64Size = img64.count
    let sizeInMB = Double(base64Size) / 1_000_000.0
    print("📸 Image base64 size: \(String(format: "%.2f", sizeInMB)) MB")

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
    req.timeoutInterval = 120  // 2 minutes
    
    print("⏱️ Starting request with 120s timeout...")
    let startTime = Date()
    
    do {
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
    } catch {
        completion(.failure(.networkError("Could not encode request")))
        return
    }

    URLSession.shared.dataTask(with: req) { data, response, error in
        let elapsedTime = Date().timeIntervalSince(startTime)
        print("⏱️ Request completed in \(String(format: "%.2f", elapsedTime))s")
        
        if let error = error {
            print("❌ Error: \(error.localizedDescription)")
            completion(.failure(.networkError(error.localizedDescription)))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              let data = data else {
            completion(.failure(.networkError("Invalid response")))
            return
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? String {
                print("❌ Server error: \(detail)")
                completion(.failure(.serverError(detail)))
            } else {
                completion(.failure(.serverError("Server error: \(httpResponse.statusCode)")))
            }
            return
        }
        
        // Decode successful response
        do {
            let decoder = JSONDecoder()
            let menuResponse = try decoder.decode(MenuResponse.self, from: data)
            print("✅ Success! Found: \(menuResponse.restaurant)")
            completion(.success(menuResponse))
        } catch {
            print("❌ Decoding error: \(error)")
            completion(.failure(.decodingError))
        }
    }.resume()
}

func base64(_ image: UIImage) -> String? {
    // Resize image to reduce size
    let resizedImage = resizeImage(image: image, targetWidth: 800)
    
    // Use lower compression quality for faster upload
    // 0.5 = 50% quality - good balance between size and OCR accuracy
    guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
        return nil
    }
    
    let base64String = imageData.base64EncodedString()
    print("🖼️ Compressed image size: \(String(format: "%.2f", Double(imageData.count) / 1_000_000.0)) MB")
    
    return base64String
}

func resizeImage(image: UIImage, targetWidth: CGFloat) -> UIImage {
    let originalSize = image.size
    
    // If image is already smaller, don't resize
    if originalSize.width <= targetWidth {
        return image
    }
    
    let scale = targetWidth / originalSize.width
    let targetHeight = originalSize.height * scale
    let targetSize = CGSize(width: targetWidth, height: targetHeight)
    
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resizedImage = renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    
    print("📏 Resized image from \(originalSize.width)x\(originalSize.height) to \(targetSize.width)x\(targetSize.height)")
    
    return resizedImage
}
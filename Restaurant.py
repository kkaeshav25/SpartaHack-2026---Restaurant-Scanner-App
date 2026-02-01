import requests
import os
import time
from fastapi import HTTPException
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Load API key from environment variable
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

if not GOOGLE_API_KEY:
    raise ValueError("GOOGLE_API_KEY environment variable is not set")

def ocr_image(image_base64: str) -> str:
    """Extract text from image using Google Vision API"""
    start_time = time.time()
    
    url = f"https://vision.googleapis.com/v1/images:annotate?key={GOOGLE_API_KEY}"

    payload = {
        "requests": [{
            "image": {"content": image_base64},
            "features": [{"type": "TEXT_DETECTION"}]
        }]
    }

    print(f"📤 Sending image to Google Vision API...")
    print(f"   Image size: {len(image_base64) / 1_000_000:.2f} MB (base64)")
    
    try:
        r = requests.post(url, json=payload, timeout=60)  # 60 second timeout
        r.raise_for_status()
        
        elapsed = time.time() - start_time
        print(f"✅ OCR completed in {elapsed:.2f}s")
        
        response_data = r.json()
        text = response_data["responses"][0].get("fullTextAnnotation", {}).get("text", "")
        
        print(f"📝 Extracted text: {text[:100]}..." if len(text) > 100 else f"📝 Extracted text: {text}")
        
        return text
        
    except requests.exceptions.Timeout:
        print("❌ OCR request timed out after 60s")
        raise HTTPException(504, "OCR request timed out - image may be too large")
    except requests.exceptions.RequestException as e:
        print(f"❌ OCR request failed: {str(e)}")
        raise HTTPException(500, f"OCR failed: {str(e)}")

def guess_restaurant_name(text: str) -> str:
    """Extract restaurant name from OCR text (assumes first line is the name)"""
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    
    if not lines:
        return ""
    
    # Try to get the most prominent line (usually the first one)
    name = lines[0]
    print(f"🏪 Guessed restaurant name: '{name}'")
    
    return name

def find_restaurant(name: str, lat: float, lon: float, radius: int = 1000):
    """Find restaurant using Google Places API"""
    start_time = time.time()
    
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

    params = {
        "key": GOOGLE_API_KEY,
        "location": f"{lat},{lon}",
        "radius": radius,
        "keyword": name,
        "type": "restaurant"
    }

    print(f"🔍 Searching for '{name}' within {radius}m of ({lat}, {lon})")
    
    try:
        r = requests.get(url, params=params, timeout=30)
        r.raise_for_status()
        
        elapsed = time.time() - start_time
        print(f"✅ Places search completed in {elapsed:.2f}s")
        
        results = r.json().get("results", [])
        
        if not results:
            print(f"❌ No restaurants found matching '{name}'")
            raise HTTPException(404, f"Restaurant '{name}' not found within {radius}m")
        
        print(f"✅ Found {len(results)} restaurant(s)")
        print(f"   Best match: {results[0]['name']}")
        
        return results[0]
        
    except requests.exceptions.Timeout:
        print("❌ Places search timed out")
        raise HTTPException(504, "Restaurant search timed out")
    except requests.exceptions.RequestException as e:
        print(f"❌ Places search failed: {str(e)}")
        raise HTTPException(500, f"Restaurant search failed: {str(e)}")

def get_menu_url(place_id: str) -> str:
    """Get restaurant website or Google Maps URL"""
    start_time = time.time()
    
    url = "https://maps.googleapis.com/maps/api/place/details/json"

    params = {
        "key": GOOGLE_API_KEY,
        "place_id": place_id,
        "fields": "website,url"
    }

    print(f"🔗 Getting details for place_id: {place_id}")
    
    try:
        r = requests.get(url, params=params, timeout=30)
        r.raise_for_status()
        
        elapsed = time.time() - start_time
        print(f"✅ Place details retrieved in {elapsed:.2f}s")
        
        result = r.json().get("result", {})
        menu_url = result.get("website") or result.get("url")
        
        print(f"🌐 Menu URL: {menu_url}")
        
        return menu_url
        
    except requests.exceptions.Timeout:
        print("❌ Place details request timed out")
        raise HTTPException(504, "Menu retrieval timed out")
    except requests.exceptions.RequestException as e:
        print(f"❌ Place details failed: {str(e)}")
        raise HTTPException(500, f"Menu retrieval failed: {str(e)}")

def search_restaurants_by_food(food_craving: str, lat: float, lon: float, radius: int = 1000):
    """Search for restaurants serving a specific food type, ranked by price"""
    start_time = time.time()
    
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

    params = {
        "key": GOOGLE_API_KEY,
        "location": f"{lat},{lon}",
        "radius": radius,
        "keyword": food_craving,
        "type": "restaurant"
    }

    print(f"🔍 Searching for '{food_craving}' restaurants within {radius}m of ({lat}, {lon})")
    
    try:
        r = requests.get(url, params=params, timeout=30)
        r.raise_for_status()
        
        elapsed = time.time() - start_time
        print(f"✅ Food search completed in {elapsed:.2f}s")
        
        results = r.json().get("results", [])
        
        if not results:
            print(f"❌ No restaurants found serving '{food_craving}'")
            raise HTTPException(404, f"No restaurants found serving '{food_craving}'")
        
        print(f"✅ Found {len(results)} restaurant(s)")
        
        # Sort by price level (1-4, where 1 is cheapest)
        # Restaurants without price_level go to the end
        sorted_results = sorted(
            results,
            key=lambda x: (x.get("price_level", 5), -x.get("rating", 0))
        )
        
        formatted_results = []
        for place in sorted_results:
            formatted_results.append({
                "name": place["name"],
                "place_id": place["place_id"],
                "rating": place.get("rating", 0),
                "price_level": place.get("price_level", 0),
                "distance_meters": place.get("distance_meters", 0),
                "open_now": place.get("opening_hours", {}).get("open_now", None)
            })
        
        return formatted_results
        
    except requests.exceptions.Timeout:
        print("❌ Food search request timed out")
        raise HTTPException(504, "Restaurant search timed out")
    except requests.exceptions.RequestException as e:
        print(f"❌ Food search failed: {str(e)}")
        raise HTTPException(500, f"Restaurant search failed: {str(e)}")


def find_menu(image_base64: str, lat: float, lon: float, radius: int = 1000):
    """Main function to find restaurant menu from image and location"""
    total_start = time.time()
    
    print("\n" + "="*60)
    print("🍽️  NEW MENU SEARCH REQUEST")
    print("="*60)
    
    # Step 1: OCR
    text = ocr_image(image_base64)
    
    # Step 2: Extract name
    name = guess_restaurant_name(text)
    if not name:
        print("❌ Could not detect restaurant name from image")
        raise HTTPException(400, "Could not detect restaurant name from image")
    
    # Step 3: Find restaurant
    place = find_restaurant(name, lat, lon, radius)
    
    # Step 4: Get menu URL
    menu_url = get_menu_url(place["place_id"])
    
    total_elapsed = time.time() - total_start
    print(f"\n✅ TOTAL TIME: {total_elapsed:.2f}s")
    print("="*60 + "\n")
    
    return {
        "restaurant": place["name"],
        "menu_url": menu_url
    }
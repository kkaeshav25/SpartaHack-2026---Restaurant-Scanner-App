import requests
import os
from fastapi import HTTPException
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Load API key from environment variable
# This is the proper way to handle API keys on the server side
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

if not GOOGLE_API_KEY:
    raise ValueError("GOOGLE_API_KEY environment variable is not set")

def ocr_image(image_base64: str) -> str:
    """Extract text from image using Google Vision API"""
    url = f"https://vision.googleapis.com/v1/images:annotate?key={GOOGLE_API_KEY}"

    payload = {
        "requests": [{
            "image": {"content": image_base64},
            "features": [{"type": "TEXT_DETECTION"}]
        }]
    }

    r = requests.post(url, json=payload)
    r.raise_for_status()

    return r.json()["responses"][0].get(
        "fullTextAnnotation", {}
    ).get("text", "")

def guess_restaurant_name(text: str) -> str:
    """Extract restaurant name from OCR text (assumes first line is the name)"""
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    return lines[0] if lines else ""

def find_restaurant(name: str, lat: float, lon: float):
    """Find restaurant using Google Places API"""
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

    params = {
        "key": GOOGLE_API_KEY,
        "location": f"{lat},{lon}",
        "radius": 100,
        "keyword": name,
        "type": "restaurant"
    }

    r = requests.get(url, params=params)
    r.raise_for_status()

    results = r.json().get("results", [])
    if not results:
        raise HTTPException(404, "Restaurant not found")

    return results[0]

def get_menu_url(place_id: str) -> str:
    """Get restaurant website or Google Maps URL"""
    url = "https://maps.googleapis.com/maps/api/place/details/json"

    params = {
        "key": GOOGLE_API_KEY,
        "place_id": place_id,
        "fields": "website,url"
    }

    r = requests.get(url, params=params)
    r.raise_for_status()

    result = r.json().get("result", {})
    return result.get("website") or result.get("url")

def find_menu(image_base64: str, lat: float, lon: float):
    """Main function to find restaurant menu from image and location"""
    text = ocr_image(image_base64)
    name = guess_restaurant_name(text)

    if not name:
        raise HTTPException(400, "Could not detect restaurant name")

    place = find_restaurant(name, lat, lon)
    menu_url = get_menu_url(place["place_id"])

    return {
        "restaurant": place["name"],
        "menu_url": menu_url
    }
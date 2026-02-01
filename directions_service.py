import requests
import os
from typing import List, Dict, Optional
from fastapi import HTTPException
from dotenv import load_dotenv

load_dotenv()

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

if not GOOGLE_API_KEY:
    raise ValueError("GOOGLE_API_KEY environment variable is not set")


def get_directions(
    start_lat: float,
    start_lng: float,
    end_lat: float,
    end_lng: float,
    mode: str = "driving"
) -> Optional[Dict]:
    """
    Get directions from Google Maps Directions API
    
    Args:
        start_lat, start_lng: Starting location coordinates
        end_lat, end_lng: Destination location coordinates
        mode: Travel mode - "driving", "walking", "bicycling", "transit"
    
    Returns:
        {
            "steps": [
                {
                    "instruction": str,
                    "distance": float (meters),
                    "duration": float (seconds)
                }
            ],
            "total_distance": float (meters),
            "total_duration": float (seconds),
            "encoded_polyline": str (for map display)
        }
    """
    if not GOOGLE_API_KEY:
        raise HTTPException(400, "Google API key not configured")
    
    url = "https://maps.googleapis.com/maps/api/directions/json"
    
    params = {
        "origin": f"{start_lat},{start_lng}",
        "destination": f"{end_lat},{end_lng}",
        "key": GOOGLE_API_KEY,
        "mode": mode
    }
    
    try:
        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        if data.get("status") != "OK":
            raise HTTPException(400, f"Directions API error: {data.get('status')}")
        
        routes = data.get("routes", [])
        if not routes:
            raise HTTPException(404, "No routes found")
        
        route = routes[0]
        legs = route.get("legs", [])
        
        if not legs:
            raise HTTPException(404, "No legs found in route")
        
        leg = legs[0]
        steps = leg.get("steps", [])
        
        # Parse steps
        formatted_steps = []
        for step in steps:
            # Extract HTML instruction and convert to plain text
            html_instruction = step.get("html_instructions", "")
            # Simple HTML tag removal
            plain_instruction = html_instruction.replace("<b>", "").replace("</b>", "").replace("<div", "").replace(">", "").replace("</div>", "")
            
            formatted_steps.append({
                "instruction": plain_instruction,
                "distance": step.get("distance", {}).get("value", 0),  # in meters
                "duration": step.get("duration", {}).get("value", 0),  # in seconds
            })
        
        return {
            "steps": formatted_steps,
            "total_distance": leg.get("distance", {}).get("value", 0),
            "total_duration": leg.get("duration", {}).get("value", 0),
            "encoded_polyline": route.get("overview_polyline", {}).get("points", "")
        }
        
    except requests.RequestException as e:
        print(f"Directions API error: {str(e)}")
        raise HTTPException(500, f"Failed to fetch directions: {str(e)}")


def search_nearby_locations(
    query: str,
    lat: float,
    lng: float,
    radius: int = 5000
) -> Optional[Dict]:
    """
    Search for nearby locations matching the query
    
    Args:
        query: Search query (e.g., "pizza", "coffee")
        lat, lng: Center point for search
        radius: Search radius in meters
    
    Returns:
        {
            "name": str,
            "lat": float,
            "lng": float,
            "address": str,
            "place_id": str,
            "distance": float (meters from user)
        }
    """
    if not GOOGLE_API_KEY:
        raise HTTPException(400, "Google API key not configured")
    
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    
    params = {
        "keyword": query,
        "location": f"{lat},{lng}",
        "radius": radius,
        "key": GOOGLE_API_KEY,
        "type": "restaurant"
    }
    
    try:
        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        if data.get("status") != "OK":
            raise HTTPException(400, f"Places API error: {data.get('status')}")
        
        results = data.get("results", [])
        
        if not results:
            raise HTTPException(404, f"No locations found for '{query}'")
        
        # Get the first result
        place = results[0]
        location = place.get("geometry", {}).get("location", {})
        
        # Calculate distance from user (approximate)
        from math import radians, sin, cos, sqrt, atan2
        
        user_lat, user_lng = lat, lng
        place_lat, place_lng = location.get("lat"), location.get("lng")
        
        R = 6371000  # Earth's radius in meters
        lat1 = radians(user_lat)
        lat2 = radians(place_lat)
        dlat = radians(place_lat - user_lat)
        dlng = radians(place_lng - user_lng)
        
        a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlng / 2) ** 2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))
        distance = R * c
        
        return {
            "name": place.get("name"),
            "lat": place_lat,
            "lng": place_lng,
            "address": place.get("vicinity", ""),
            "place_id": place.get("place_id"),
            "distance": distance,
            "rating": place.get("rating", 0),
            "open_now": place.get("opening_hours", {}).get("open_now")
        }
        
    except requests.RequestException as e:
        print(f"Places API error: {str(e)}")
        raise HTTPException(500, f"Failed to search locations: {str(e)}")

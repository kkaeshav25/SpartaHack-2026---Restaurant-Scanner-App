import requests
import os
from typing import List, Dict, Optional
from fastapi import HTTPException
from dotenv import load_dotenv

load_dotenv()

DOORDASH_DEVELOPER_ID = os.getenv("DEVELOPER_ID")
DOORDASH_KEY_ID = os.getenv("KEY_ID")
DOORDASH_SIGNING_SECRET = os.getenv("SIGNING_SECRET")
DOORDASH_API_URL = "https://openapi.doordash.com"

# Note: DoorDash Drive API requires business account
# This is a placeholder structure - you'll need to sign up for DoorDash Developer API

def search_doordash_store(restaurant_name: str, lat: float, lon: float) -> Optional[Dict]:
    """
    Search for a restaurant on DoorDash
    Returns store information including store_id
    """
    if not DOORDASH_DEVELOPER_ID:
        raise HTTPException(400, "DoorDash credentials not configured")
    
    headers = {
        "Authorization": f"Bearer {DOORDASH_DEVELOPER_ID}",
        "Content-Type": "application/json"
    }
    
    # Placeholder - actual endpoint structure depends on DoorDash API version
    url = f"{DOORDASH_API_URL}/v1/stores/search"
    
    params = {
        "query": restaurant_name,
        "lat": lat,
        "lng": lon
    }
    
    try:
        response = requests.get(url, headers=headers, params=params, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        stores = data.get("stores", [])
        
        if stores:
            return stores[0]  # Return first match
        return None
        
    except requests.RequestException as e:
        print(f"DoorDash search error: {str(e)}")
        return None


def get_store_menu(store_id: str) -> List[Dict]:
    """
    Get menu items from a DoorDash store
    Returns list of menu items with prices
    """
    if not DOORDASH_DEVELOPER_ID:
        raise HTTPException(400, "DoorDash credentials not configured")
    
    headers = {
        "Authorization": f"Bearer {DOORDASH_DEVELOPER_ID}",
        "Content-Type": "application/json"
    }
    
    url = f"{DOORDASH_API_URL}/v1/stores/{store_id}/menu"
    
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        menu_items = []
        
        # Parse menu structure
        for category in data.get("categories", []):
            for item in category.get("items", []):
                menu_items.append({
                    "id": item.get("id"),
                    "name": item.get("name"),
                    "description": item.get("description", ""),
                    "price": item.get("price", 0) / 100,  # Convert cents to dollars
                    "category": category.get("name"),
                    "image_url": item.get("image_url"),
                    "available": item.get("available", True)
                })
        
        return menu_items
        
    except requests.RequestException as e:
        print(f"DoorDash menu error: {str(e)}")
        raise HTTPException(500, f"Failed to fetch menu: {str(e)}")


def calculate_delivery_quote(store_id: str, delivery_address: Dict, items: List[Dict]) -> Dict:
    """
    Calculate delivery fee and total cost
    
    Args:
        store_id: DoorDash store ID
        delivery_address: {"lat": float, "lng": float, "street": str, "city": str}
        items: List of {"item_id": str, "quantity": int}
    
    Returns:
        {
            "subtotal": float,
            "delivery_fee": float,
            "service_fee": float,
            "tax": float,
            "total": float,
            "estimated_delivery_time": int (minutes)
        }
    """
    if not DOORDASH_DEVELOPER_ID:
        raise HTTPException(400, "DoorDash credentials not configured")
    
    headers = {
        "Authorization": f"Bearer {DOORDASH_DEVELOPER_ID}",
        "Content-Type": "application/json"
    }
    
    url = f"{DOORDASH_API_URL}/v1/delivery/quote"
    
    payload = {
        "store_id": store_id,
        "delivery_address": delivery_address,
        "items": items
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        return {
            "subtotal": data.get("subtotal", 0) / 100,
            "delivery_fee": data.get("delivery_fee", 0) / 100,
            "service_fee": data.get("service_fee", 0) / 100,
            "tax": data.get("tax", 0) / 100,
            "total": data.get("total", 0) / 100,
            "estimated_delivery_time": data.get("estimated_delivery_time_minutes", 30)
        }
        
    except requests.RequestException as e:
        print(f"DoorDash quote error: {str(e)}")
        raise HTTPException(500, f"Failed to get delivery quote: {str(e)}")


def search_menu_items(store_id: str, query: str) -> List[Dict]:
    """
    Search for specific menu items in a store
    """
    menu_items = get_store_menu(store_id)
    
    # Filter items by query
    query_lower = query.lower()
    filtered_items = [
        item for item in menu_items
        if query_lower in item["name"].lower() or query_lower in item["description"].lower()
    ]
    
    # Sort by price (cheapest first)
    filtered_items.sort(key=lambda x: x["price"])
    
    return filtered_items

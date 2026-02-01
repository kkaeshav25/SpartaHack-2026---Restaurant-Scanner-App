from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional
from Restaurant import find_menu, search_restaurants_by_food
from doordash_service import (
    search_doordash_store, 
    get_store_menu, 
    calculate_delivery_quote,
    search_menu_items
)
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Restaurant Menu Finder API",
    description="Find restaurant menus from photos",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class MenuRequest(BaseModel):
    image_base64: str = Field(..., description="Base64 encoded image")
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class MenuResponse(BaseModel):
    restaurant: str
    menu_url: str

class RestaurantSearchRequest(BaseModel):
    food_craving: str = Field(..., description="Type of food to search for")
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class RestaurantResult(BaseModel):
    name: str
    place_id: str
    rating: float
    price_level: int
    distance_meters: float
    open_now: bool | None

class RestaurantSearchResponse(BaseModel):
    results: list[RestaurantResult]
    total_found: int


class MenuItem(BaseModel):
    id: str
    name: str
    description: str
    price: float
    category: str
    image_url: Optional[str]
    available: bool

class MenuItemsResponse(BaseModel):
    store_id: str
    restaurant_name: str
    items: List[MenuItem]
    total_items: int

class DeliveryAddress(BaseModel):
    lat: float
    lng: float
    street: str
    city: str
    state: Optional[str] = None
    zipcode: Optional[str] = None

class OrderItem(BaseModel):
    item_id: str
    quantity: int = 1

class DeliveryQuoteRequest(BaseModel):
    store_id: str
    delivery_address: DeliveryAddress
    items: List[OrderItem]

class DeliveryQuoteResponse(BaseModel):
    subtotal: float
    delivery_fee: float
    service_fee: float
    tax: float
    total: float
    estimated_delivery_time: int

@app.get("/")
def read_root():
    return {"message": "Restaurant Menu Finder API", "status": "running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/menu", response_model=MenuResponse)
def menu(req: MenuRequest):
    try:
        logger.info(f"Processing menu request for location: {req.latitude}, {req.longitude}")
        result = find_menu(req.image_base64, req.latitude, req.longitude)
        logger.info(f"Found restaurant: {result['restaurant']}")
        return result
    except HTTPException as e:
        logger.error(f"HTTP exception: {e.detail}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.post("/search", response_model=RestaurantSearchResponse)
def search(req: RestaurantSearchRequest):
    try:
        logger.info(f"Processing food search for '{req.food_craving}' at location: {req.latitude}, {req.longitude}")
        results = search_restaurants_by_food(req.food_craving, req.latitude, req.longitude)
        logger.info(f"Found {len(results)} restaurants")
        return {
            "results": results,
            "total_found": len(results)
        }
    except HTTPException as e:
        logger.error(f"HTTP exception: {e.detail}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/restaurant/{restaurant_name}/menu")
def get_restaurant_menu(
    restaurant_name: str,
    latitude: float,
    longitude: float
):
    """
    Get DoorDash menu for a specific restaurant
    """
    try:
        logger.info(f"Fetching DoorDash menu for '{restaurant_name}'")
        
        # Search for store on DoorDash
        store = search_doordash_store(restaurant_name, latitude, longitude)
        
        if not store:
            raise HTTPException(404, f"Restaurant '{restaurant_name}' not found on DoorDash")
        
        store_id = store.get("id")
        
        # Get menu items
        menu_items = get_store_menu(store_id)
        
        return MenuItemsResponse(
            store_id=store_id,
            restaurant_name=store.get("name", restaurant_name),
            items=menu_items,
            total_items=len(menu_items)
        )
        
    except HTTPException as e:
        logger.error(f"HTTP exception: {e.detail}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/restaurant/{store_id}/search")
def search_restaurant_menu(
    store_id: str,
    query: str,
    sort_by: str = "price"  # "price" or "name"
):
    """
    Search for specific items in a restaurant's menu
    Sort by cost (cheapest first by default)
    """
    try:
        logger.info(f"Searching menu items for '{query}' in store {store_id}")
        
        items = search_menu_items(store_id, query)
        
        if sort_by == "price":
            items.sort(key=lambda x: x["price"])
        elif sort_by == "name":
            items.sort(key=lambda x: x["name"])
        
        return {
            "store_id": store_id,
            "query": query,
            "items": items,
            "total_found": len(items)
        }
        
    except HTTPException as e:
        logger.error(f"HTTP exception: {e.detail}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.post("/delivery/quote", response_model=DeliveryQuoteResponse)
def get_delivery_quote(req: DeliveryQuoteRequest):
    """
    Calculate delivery fee and total cost for an order
    """
    try:
        logger.info(f"Calculating delivery quote for store {req.store_id}")
        
        delivery_address = {
            "lat": req.delivery_address.lat,
            "lng": req.delivery_address.lng,
            "street": req.delivery_address.street,
            "city": req.delivery_address.city,
            "state": req.delivery_address.state,
            "zipcode": req.delivery_address.zipcode
        }
        
        items = [{"item_id": item.item_id, "quantity": item.quantity} for item in req.items]
        
        quote = calculate_delivery_quote(req.store_id, delivery_address, items)
        
        return quote
        
    except HTTPException as e:
        logger.error(f"HTTP exception: {e.detail}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

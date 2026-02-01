from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional
from Restaurant import find_menu, search_restaurants_by_food
from directions_service import get_directions, search_nearby_locations
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

class DirectionStep(BaseModel):
    instruction: str
    distance: float  # in meters
    duration: float  # in seconds

class DirectionsResponse(BaseModel):
    steps: List[DirectionStep]
    total_distance: float  # in meters
    total_duration: float  # in seconds
    encoded_polyline: str
    restaurant_name: str
    restaurant_address: str
    distance_to_restaurant: float  # in meters

class LocationSearchRequest(BaseModel):
    food_craving: str = Field(..., description="Type of food to search for")
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    travel_mode: str = Field(default="driving", description="driving, walking, bicycling, transit")

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

@app.post("/directions", response_model=DirectionsResponse)
def get_directions_to_restaurant(req: LocationSearchRequest):
    """
    Search for a restaurant matching the food craving and get directions to it
    """
    try:
        logger.info(f"Processing directions request for '{req.food_craving}' at location: {req.latitude}, {req.longitude}")
        
        # Search for a restaurant matching the food craving
        location_info = search_nearby_locations(
            req.food_craving, 
            req.latitude, 
            req.longitude
        )
        
        if not location_info:
            raise HTTPException(404, f"No restaurants found serving '{req.food_craving}'")
        
        restaurant_name = location_info.get("name")
        restaurant_lat = location_info.get("lat")
        restaurant_lng = location_info.get("lng")
        distance_to_restaurant = location_info.get("distance", 0)
        
        logger.info(f"Found restaurant: {restaurant_name} at ({restaurant_lat}, {restaurant_lng})")
        
        # Get directions to the restaurant
        directions = get_directions(
            req.latitude,
            req.longitude,
            restaurant_lat,
            restaurant_lng,
            mode=req.travel_mode
        )
        
        if not directions:
            raise HTTPException(500, "Failed to get directions")
        
        logger.info(f"Generated directions with {len(directions['steps'])} steps")
        
        return DirectionsResponse(
            steps=directions["steps"],
            total_distance=directions["total_distance"],
            total_duration=directions["total_duration"],
            encoded_polyline=directions["encoded_polyline"],
            restaurant_name=restaurant_name,
            restaurant_address=location_info.get("address", ""),
            distance_to_restaurant=distance_to_restaurant
        )
        
    except HTTPException as e:
        logger.error(f"HTTP exception: {e.detail}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

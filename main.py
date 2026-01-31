from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from Restaurant import find_menu
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

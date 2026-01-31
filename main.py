from fastapi import FastAPI
from pydantic import BaseModel
from Restaurant import find_menu

app = FastAPI()
class MenuRequest(BaseModel):
    image_base64: str
    latitude: float
    longitude: float

@app.post("/menu")
def menu(req: MenuRequest):
    return find_menu(
        req.image_base64,
        req.latitude,
        req.longitude
    )


from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests
import os

app = FastAPI()
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

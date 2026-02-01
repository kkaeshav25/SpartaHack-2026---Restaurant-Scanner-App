"""
directions_service.py -- removed

This file was added during a Google Maps directions experiment. The project
has been rolled back to the previous DoorDash-based implementation, so this
module is no longer used. It is retained as a placeholder in case you want
to reintroduce Google Maps functionality later.
"""
from fastapi import HTTPException

def unused_placeholder():
    raise HTTPException(410, "directions_service removed during rollback")

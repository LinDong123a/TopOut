from uuid import UUID
from pydantic import BaseModel


class GymOut(BaseModel):
    id: UUID
    name: str
    address: str
    city: str
    latitude: float
    longitude: float

    model_config = {"from_attributes": True}


class GymCreate(BaseModel):
    name: str
    address: str = ""
    city: str = ""
    latitude: float
    longitude: float


class GymActiveOut(BaseModel):
    id: UUID
    name: str
    city: str
    active_count: int

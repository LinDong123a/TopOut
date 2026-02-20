import math
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.redis import get_redis
from app.models.gym import Gym
from app.models.user import User
from app.schemas.gym import GymActiveOut, GymCreate, GymOut

router = APIRouter(prefix="/gyms", tags=["gyms"])

NEARBY_RADIUS_M = 200


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


@router.get("", response_model=list[GymOut])
async def list_gyms(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Gym))
    return result.scalars().all()


@router.post("", response_model=GymOut, status_code=201)
async def create_gym(body: GymCreate, db: AsyncSession = Depends(get_db), _: User = Depends(get_current_user)):
    gym = Gym(**body.model_dump())
    db.add(gym)
    await db.commit()
    await db.refresh(gym)
    return gym


@router.get("/nearby", response_model=list[GymOut])
async def nearby_gyms(
    lat: float = Query(...),
    lng: float = Query(...),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Gym))
    gyms = result.scalars().all()
    return [g for g in gyms if _haversine(lat, lng, g.latitude, g.longitude) <= NEARBY_RADIUS_M]


@router.get("/active", response_model=list[GymActiveOut])
async def active_gyms(db: AsyncSession = Depends(get_db)):
    r = await get_redis()
    keys = [k async for k in r.scan_iter("gym:*:climbers")]
    active = []
    for key in keys:
        gym_id = key.split(":")[1]
        count = await r.scard(key)
        if count > 0:
            result = await db.execute(select(Gym).where(Gym.id == UUID(gym_id)))
            gym = result.scalar_one_or_none()
            if gym:
                active.append(GymActiveOut(id=gym.id, name=gym.name, city=gym.city, active_count=count))
    return active


@router.get("/{gym_id}", response_model=GymOut)
async def get_gym(gym_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Gym).where(Gym.id == gym_id))
    gym = result.scalar_one_or_none()
    if not gym:
        raise HTTPException(status_code=404, detail="Gym not found")
    return gym

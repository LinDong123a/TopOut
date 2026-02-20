"""Seed script to populate initial gym data."""

import asyncio

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import async_session
from app.models.gym import Gym

SEED_GYMS = [
    {"name": "岩时攀岩馆（望京店）", "address": "北京市朝阳区望京SOHO", "city": "北京", "latitude": 39.9906, "longitude": 116.4803},
    {"name": "岩舞空间（三里屯店）", "address": "北京市朝阳区三里屯路", "city": "北京", "latitude": 39.9338, "longitude": 116.4540},
    {"name": "奥赛攀岩（浦东店）", "address": "上海市浦东新区", "city": "上海", "latitude": 31.2304, "longitude": 121.4737},
    {"name": "岩壁上攀岩馆", "address": "深圳市南山区", "city": "深圳", "latitude": 22.5431, "longitude": 113.9806},
    {"name": "CAMP4攀岩馆", "address": "成都市锦江区", "city": "成都", "latitude": 30.5728, "longitude": 104.0668},
]


async def seed():
    async with async_session() as db:
        result = await db.execute(select(Gym).limit(1))
        if result.scalar_one_or_none():
            print("Gyms already seeded, skipping.")
            return
        for g in SEED_GYMS:
            db.add(Gym(**g))
        await db.commit()
        print(f"Seeded {len(SEED_GYMS)} gyms.")


if __name__ == "__main__":
    asyncio.run(seed())

from uuid import UUID
from pydantic import BaseModel


class UserOut(BaseModel):
    id: UUID
    phone: str
    nickname: str
    avatar_url: str | None = None

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    nickname: str | None = None
    avatar_url: str | None = None

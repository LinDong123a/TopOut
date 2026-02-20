from pydantic import BaseModel


class RegisterRequest(BaseModel):
    phone: str
    password: str
    nickname: str = "攀岩者"


class LoginRequest(BaseModel):
    phone: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class SMSCodeRequest(BaseModel):
    phone: str


class SMSLoginRequest(BaseModel):
    phone: str
    code: str

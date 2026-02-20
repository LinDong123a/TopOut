"""WebSocket endpoint for real-time climb data upload and gym subscription."""

import json
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.redis import get_redis
from app.core.security import decode_access_token

router = APIRouter()

# In-memory connections per gym for broadcasting
_gym_subscribers: dict[str, set[WebSocket]] = {}


async def _authenticate(ws: WebSocket) -> str | None:
    """Authenticate via first message or query param. Returns user_id or None."""
    token = ws.query_params.get("token")
    if not token:
        return None
    try:
        payload = decode_access_token(token)
        return payload["sub"]
    except Exception:
        return None


@router.websocket("/ws/climb")
async def ws_climb(ws: WebSocket):
    """Client uploads climb data here. Server stores state in Redis and broadcasts to gym subscribers."""
    await ws.accept()
    user_id = await _authenticate(ws)
    if not user_id:
        await ws.close(code=4001, reason="Unauthorized")
        return

    r = await get_redis()
    current_gym: str | None = None

    try:
        while True:
            raw = await ws.receive_text()
            msg = json.loads(raw)
            action = msg.get("action")

            if action == "start":
                gym_id = msg["gym_id"]
                visible = msg.get("visible", True)
                anonymous = msg.get("anonymous", False)
                nickname = msg.get("nickname", "攀岩者")

                current_gym = gym_id
                climber_data = json.dumps({
                    "user_id": user_id,
                    "nickname": "攀岩者" if anonymous else nickname,
                    "anonymous": anonymous,
                    "visible": visible,
                    "status": "climbing",
                    "heart_rate": 0,
                    "duration": 0,
                })

                if visible:
                    await r.sadd(f"gym:{gym_id}:climbers", user_id)
                    await r.set(f"climber:{user_id}", climber_data, ex=3600)
                    await _broadcast_gym(gym_id, {"event": "climber_joined", "data": json.loads(climber_data)})
                    # Publish to Redis pub/sub for multi-instance
                    await r.publish(f"gym:{gym_id}", json.dumps({"event": "climber_joined", "data": json.loads(climber_data)}))

            elif action == "heartrate":
                if current_gym:
                    raw_data = await r.get(f"climber:{user_id}")
                    if raw_data:
                        data = json.loads(raw_data)
                        data["heart_rate"] = msg.get("value", 0)
                        data["duration"] = msg.get("duration", 0)
                        await r.set(f"climber:{user_id}", json.dumps(data), ex=3600)
                        if data.get("visible"):
                            update = {"event": "heartrate_update", "data": {"user_id": user_id, "heart_rate": data["heart_rate"], "duration": data["duration"]}}
                            await _broadcast_gym(current_gym, update)
                            await r.publish(f"gym:{current_gym}", json.dumps(update))

            elif action == "status":
                if current_gym:
                    raw_data = await r.get(f"climber:{user_id}")
                    if raw_data:
                        data = json.loads(raw_data)
                        data["status"] = msg.get("value", "climbing")
                        await r.set(f"climber:{user_id}", json.dumps(data), ex=3600)
                        if data.get("visible"):
                            update = {"event": "status_update", "data": {"user_id": user_id, "status": data["status"]}}
                            await _broadcast_gym(current_gym, update)
                            await r.publish(f"gym:{current_gym}", json.dumps(update))

            elif action == "end":
                if current_gym:
                    await r.srem(f"gym:{current_gym}:climbers", user_id)
                    await r.delete(f"climber:{user_id}")
                    await _broadcast_gym(current_gym, {"event": "climber_left", "data": {"user_id": user_id}})
                    await r.publish(f"gym:{current_gym}", json.dumps({"event": "climber_left", "data": {"user_id": user_id}}))
                    current_gym = None

    except WebSocketDisconnect:
        if current_gym:
            await r.srem(f"gym:{current_gym}:climbers", user_id)
            await r.delete(f"climber:{user_id}")
            await _broadcast_gym(current_gym, {"event": "climber_left", "data": {"user_id": user_id}})
            try:
                await r.publish(f"gym:{current_gym}", json.dumps({"event": "climber_left", "data": {"user_id": user_id}}))
            except Exception:
                pass


@router.websocket("/ws/gym/{gym_id}")
async def ws_gym_subscribe(ws: WebSocket, gym_id: str):
    """Subscribe to a gym's real-time updates."""
    await ws.accept()

    if gym_id not in _gym_subscribers:
        _gym_subscribers[gym_id] = set()
    _gym_subscribers[gym_id].add(ws)

    # Send current state
    r = await get_redis()
    members = await r.smembers(f"gym:{gym_id}:climbers")
    climbers = []
    for uid in members:
        raw = await r.get(f"climber:{uid}")
        if raw:
            climbers.append(json.loads(raw))
    await ws.send_json({"event": "snapshot", "data": climbers})

    try:
        while True:
            await ws.receive_text()  # keep alive
    except WebSocketDisconnect:
        _gym_subscribers.get(gym_id, set()).discard(ws)


async def _broadcast_gym(gym_id: str, message: dict):
    subs = _gym_subscribers.get(gym_id, set()).copy()
    for ws in subs:
        try:
            await ws.send_json(message)
        except Exception:
            _gym_subscribers.get(gym_id, set()).discard(ws)

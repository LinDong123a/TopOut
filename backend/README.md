# TopOut Backend

攀岩 App 后端服务 — FastAPI + PostgreSQL + Redis + WebSocket

## 快速启动

```bash
cd backend
docker-compose up --build
```

API 地址: http://localhost:8000
API 文档: http://localhost:8000/docs
健康检查: http://localhost:8000/health

## API 概要

### 认证
- `POST /api/auth/register` — 注册（phone, password, nickname）
- `POST /api/auth/login` — 登录（phone, password）→ JWT token

### 用户
- `GET /api/users/me` — 当前用户信息（需 Bearer token）
- `PUT /api/users/me` — 更新昵称/头像

### 场馆
- `GET /api/gyms` — 所有场馆
- `POST /api/gyms` — 创建场馆（需认证）
- `GET /api/gyms/nearby?lat=&lng=` — 200m 半径内场馆
- `GET /api/gyms/active` — 当前有人在爬的场馆
- `GET /api/gyms/{id}` — 场馆详情

### WebSocket

#### `/ws/climb?token=JWT_TOKEN` — 攀爬数据上报

客户端发送 JSON 消息：

```json
// 开始攀爬
{"action": "start", "gym_id": "uuid", "visible": true, "anonymous": false, "nickname": "小明"}

// 心率推送（每秒）
{"action": "heartrate", "value": 120, "duration": 65}

// 状态变更
{"action": "status", "value": "resting"}  // climbing | resting

// 结束攀爬
{"action": "end"}
```

#### `/ws/gym/{gym_id}` — 场馆实时订阅

连接后自动收到当前快照，之后实时推送：
- `climber_joined` — 新用户加入
- `heartrate_update` — 心率更新
- `status_update` — 状态变更
- `climber_left` — 用户离开

## 本地开发（不用 Docker）

```bash
pip install -r requirements.txt
# 启动 PostgreSQL 和 Redis，设置环境变量
export DATABASE_URL=postgresql+asyncpg://topout:topout@localhost:5432/topout
export REDIS_URL=redis://localhost:6379/0
uvicorn app.main:app --reload
```

## 预置数据

启动时自动 seed 5 个主要城市的攀岩馆数据（北京、上海、深圳、成都）。

## 技术栈
- FastAPI (async)
- PostgreSQL 16 + SQLAlchemy 2.0 (async)
- Redis 7 (实时状态 + pub/sub)
- JWT 认证
- Docker Compose 一键启动

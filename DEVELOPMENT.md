# 🛠️ NaoTodo 开发者指南

## 📋 目录
- [快速开始](#快速开始)
- [MongoDB 配置迁移指南](#mongodb-配置迁移指南)
- [安全配置](#安全配置)
- [环境变量详解](#环境变量详解)
- [API 端点](#api-端点)
- [故障排除](#故障排除)

## 🚀 快速开始

### 1. 环境准备
```bash
# 确保安装以下软件
node --version  # >= 18.0.0
pnpm --version  # >= 8.0.0
mongod --version # >= 4.4
```

### 2. 项目设置
```bash
# 克隆项目
git clone https://github.com/AsokaWang/Todo.git
cd Todo

# 后端设置
cd nao-todo-server
cp .env.example .env
# 编辑 .env 文件配置必要参数
pnpm install

# 前端设置
cd ../nao-todo
pnpm install
```

### 3. 启动开发环境
```bash
# 终端1: 启动 MongoDB
mongod

# 终端2: 启动后端服务
cd nao-todo-server
pnpm run websrv dev

# 终端3: 启动前端应用
cd nao-todo
pnpm run webapp dev
```

## 🔧 MongoDB 配置迁移指南

### 旧版本 vs 新版本

#### 🔴 旧版本（已废弃）
```typescript
// 硬编码连接方式
const mongodbUrl = `mongodb://${PROD ? '172.18.0.3' : 'localhost'}:27017/naotodo`;
mongoose.connect(mongodbUrl);
```

#### ✅ 新版本（推荐）
```typescript
// 使用环境变量和现代配置
import { connectToMongoDB } from '@nao-todo-server/utils';
await connectToMongoDB();
```

### 迁移步骤

1. **创建 .env 文件**
   ```bash
   cd nao-todo-server
   cp .env.example .env
   ```

2. **配置环境变量**
   ```bash
   # 编辑 .env 文件
   MONGODB_URI=mongodb://localhost:27017/naotodo
   JWT_SECRET=your-secure-secret-at-least-32-characters-long
   ```

3. **更新代码**
   - 旧代码会自动使用新配置
   - 建议逐步迁移到新的 API

### 新配置的优势

✅ **安全性**
- 敏感信息不再硬编码
- 支持 SSL/TLS 连接
- 连接字符串遮罩显示

✅ **可配置性**
- 连接池优化
- 超时设置可调
- 环境特定配置

✅ **监控能力**
- 连接状态监控
- 健康检查端点
- 连接统计信息

✅ **错误处理**
- 优雅的重连机制
- 详细的错误日志
- 进程退出时安全关闭

## 🔐 安全配置

### Git 安全
项目已更新 `.gitignore` 防止敏感信息泄漏：

```gitignore
# 环境变量和敏感信息
.env
.env.local
.env.production
.env.development
*.env

# SSL 证书
*.pem
*.key
*.crt
*.cer

# 数据库配置
config/database.json
config/secrets.json
```

### 密钥管理最佳实践

1. **JWT 密钥生成**
   ```bash
   # 生成安全的 JWT 密钥
   openssl rand -base64 32
   ```

2. **生产环境配置**
   ```bash
   # 使用系统环境变量
   export MONGODB_URI="mongodb://user:pass@host:port/db?authSource=admin&ssl=true"
   export JWT_SECRET="$(openssl rand -base64 32)"
   ```

3. **容器化部署**
   ```dockerfile
   # Dockerfile
   ENV MONGODB_URI=""
   ENV JWT_SECRET=""
   # 运行时通过 secrets 或环境变量注入
   ```

### 连接字符串安全

❌ **不安全的做法**
```bash
# 明文密码
MONGODB_URI=mongodb://admin:password123@host:port/naotodo
```

✅ **安全的做法**
```bash
# 使用 URL 编码
MONGODB_URI=mongodb://admin:%40dmin%24ecure%21@host:port/naotodo?authSource=admin&ssl=true

# 或使用 SRV 记录
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/naotodo?retryWrites=true&w=majority
```

## 📝 环境变量详解

### 核心配置

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `NODE_ENV` | string | `development` | 应用环境 |
| `PORT` | number | `3002` | 服务器端口 |
| `MONGODB_URI` | string | `mongodb://localhost:27017/naotodo` | 数据库连接字符串 |
| `JWT_SECRET` | string | - | JWT 签名密钥（必需） |

### MongoDB 连接配置

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `MONGODB_MAX_POOL_SIZE` | number | `100` | 最大连接池大小 |
| `MONGODB_MIN_POOL_SIZE` | number | `5` | 最小连接池大小 |
| `MONGODB_MAX_IDLE_TIME_MS` | number | `30000` | 空闲连接超时 |
| `MONGODB_SERVER_SELECTION_TIMEOUT_MS` | number | `5000` | 服务器选择超时 |
| `MONGODB_SOCKET_TIMEOUT_MS` | number | `45000` | Socket 超时 |

### CORS 和安全配置

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `CORS_ORIGIN` | string | `http://localhost:5173` | 允许的前端域名 |
| `CORS_CREDENTIALS` | boolean | `true` | 是否允许凭据 |

### 文件上传配置

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `UPLOAD_PATH` | string | `./uploads` | 上传文件存储路径 |
| `MAX_FILE_SIZE` | number | `5242880` | 最大文件大小（5MB） |

### SSL/HTTPS 配置

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `SSL_CERT_PATH` | string | `./certs/fullchain.pem` | SSL 证书路径 |
| `SSL_KEY_PATH` | string | `./certs/privkey.pem` | SSL 私钥路径 |

### AI 功能配置

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `OPENAI_API_KEY` | string | - | OpenAI API 密钥 |
| `OPENAI_MODEL` | string | `gpt-3.5-turbo` | 使用的 AI 模型 |
| `OPENAI_MAX_TOKENS` | number | `1000` | 最大令牌数 |

### 日志配置

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `LOG_LEVEL` | string | `info` | 日志级别 |
| `LOG_FILE` | string | `./logs/app.log` | 日志文件路径 |
| `LOG_MAX_SIZE` | number | `10485760` | 日志文件最大大小 |
| `LOG_MAX_FILES` | number | `5` | 保留日志文件数量 |

## 📡 API 端点

### 健康检查
```bash
GET /health
```

响应示例：
```json
{
  "status": "OK",
  "timestamp": "2025-01-11T12:00:00.000Z",
  "uptime": 3600,
  "environment": "development",
  "mongodb": {
    "connected": true,
    "stats": {
      "readyState": 1,
      "name": "naotodo",
      "host": "localhost",
      "port": 27017
    }
  },
  "memory": {
    "rss": 52428800,
    "heapTotal": 20971520,
    "heapUsed": 18874368
  }
}
```

### API 根路径
```bash
GET /
```

响应示例：
```json
{
  "message": "NaoTodo Server API",
  "version": "1.0.0",
  "environment": "development",
  "timestamp": "2025-01-11T12:00:00.000Z"
}
```

## 🔍 故障排除

### 常见问题

#### 1. MongoDB 连接失败
```
❌ MongoDB 连接失败: MongoNetworkError: connect ECONNREFUSED 127.0.0.1:27017
```

**解决方案：**
```bash
# 检查 MongoDB 服务状态
sudo systemctl status mongod

# 启动 MongoDB 服务
sudo systemctl start mongod

# 检查端口是否被占用
netstat -tulpn | grep :27017

# 检查环境变量配置
echo $MONGODB_URI
```

#### 2. JWT 密钥未配置
```
❌ JWT_SECRET 环境变量未设置
```

**解决方案：**
```bash
# 生成安全的 JWT 密钥
openssl rand -base64 32

# 添加到 .env 文件
echo "JWT_SECRET=$(openssl rand -base64 32)" >> .env
```

#### 3. 端口被占用
```
❌ Error: listen EADDRINUSE: address already in use :::3002
```

**解决方案：**
```bash
# 查找占用端口的进程
lsof -i :3002

# 终止进程
kill -9 <PID>

# 或使用不同端口
echo "PORT=3003" >> .env
```

#### 4. CORS 错误
```
Access to fetch at 'http://localhost:3002/api/...' from origin 'http://localhost:5173' has been blocked by CORS policy
```

**解决方案：**
```bash
# 检查 CORS 配置
echo $CORS_ORIGIN

# 更新配置
echo "CORS_ORIGIN=http://localhost:5173" >> .env
```

### 调试模式

启用 MongoDB 调试：
```bash
DEV_SHOW_MONGOOSE_DEBUG=true pnpm run websrv dev
```

启用详细日志：
```bash
LOG_LEVEL=debug pnpm run websrv dev
```

### 性能监控

查看连接统计：
```bash
curl http://localhost:3002/health | jq .mongodb.stats
```

监控内存使用：
```bash
curl http://localhost:3002/health | jq .memory
```

## 🤝 贡献指南

1. **Fork 项目** 并创建功能分支
2. **遵循配置规范** 使用环境变量
3. **测试更改** 确保不破坏现有功能
4. **更新文档** 如有配置变更
5. **提交 PR** 详细描述更改内容

## 📚 更多资源

- [MongoDB 连接字符串参考](https://docs.mongodb.com/manual/reference/connection-string/)
- [Express.js 最佳实践](https://expressjs.com/en/advanced/best-practice-security.html)
- [Node.js 环境变量管理](https://nodejs.org/en/learn/command-line/how-to-read-environment-variables-from-nodejs)
- [JWT 最佳实践](https://tools.ietf.org/html/rfc7519)
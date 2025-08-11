# 🍃 MongoDB 配置指南

## 📋 目录
- [快速开始](#快速开始)
- [环境配置](#环境配置)
- [连接字符串详解](#连接字符串详解)
- [不同环境配置](#不同环境配置)
- [安全配置](#安全配置)
- [性能优化](#性能优化)
- [故障排除](#故障排除)
- [管理工具](#管理工具)

## 🚀 快速开始

### 1. 安装 MongoDB

#### macOS (使用 Homebrew)
```bash
# 安装 MongoDB Community Edition
brew tap mongodb/brew
brew install mongodb-community

# 启动 MongoDB 服务
brew services start mongodb/brew/mongodb-community

# 验证安装
mongosh --version
```

#### Ubuntu/Debian
```bash
# 导入公钥
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

# 添加仓库
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# 安装 MongoDB
sudo apt-get update
sudo apt-get install -y mongodb-org

# 启动服务
sudo systemctl start mongod
sudo systemctl enable mongod

# 验证安装
mongosh --version
```

#### CentOS/RHEL
```bash
# 创建仓库文件
cat <<EOF | sudo tee /etc/yum.repos.d/mongodb-org-6.0.repo
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

# 安装 MongoDB
sudo yum install -y mongodb-org

# 启动服务
sudo systemctl start mongod
sudo systemctl enable mongod
```

#### Windows
```powershell
# 下载 MongoDB Community Server
# https://www.mongodb.com/try/download/community

# 以管理员身份运行安装程序
# 选择 "Complete" 安装类型
# 勾选 "Install MongoDB as a Service"

# 验证安装
mongosh --version
```

### 2. 配置 NaoTodo 项目

```bash
# 1. 进入项目目录
cd /path/to/nao-todo-server

# 2. 复制环境变量模板
cp .env.example .env

# 3. 编辑 .env 文件
vim .env  # 或使用其他编辑器
```

### 3. 基础环境变量配置

```bash
# .env 文件内容
NODE_ENV=development
PORT=3002

# MongoDB 配置 (本地开发)
MONGODB_URI=mongodb://localhost:27017/naotodo
MONGODB_DB_NAME=naotodo

# JWT 安全配置 (必须设置)
JWT_SECRET=your-super-secure-jwt-secret-at-least-32-characters-long
```

### 4. 启动项目

```bash
# 安装依赖
pnpm install

# 启动 MongoDB (如果未自动启动)
# macOS
brew services start mongodb/brew/mongodb-community
# Linux
sudo systemctl start mongod

# 启动 NaoTodo 服务器
pnpm run websrv dev
```

## ⚙️ 环境配置

### 开发环境配置

```bash
# .env.development
NODE_ENV=development
PORT=3002

# 本地 MongoDB
MONGODB_URI=mongodb://localhost:27017/naotodo
MONGODB_DB_NAME=naotodo

# 连接池配置 (开发环境)
MONGODB_MAX_POOL_SIZE=10
MONGODB_MIN_POOL_SIZE=2
MONGODB_MAX_IDLE_TIME_MS=30000
MONGODB_SERVER_SELECTION_TIMEOUT_MS=5000
MONGODB_SOCKET_TIMEOUT_MS=45000

# 调试配置
DEV_SHOW_MONGOOSE_DEBUG=true
LOG_LEVEL=debug
```

### 测试环境配置

```bash
# .env.test
NODE_ENV=test
PORT=3003

# 测试数据库 (独立数据库)
MONGODB_URI=mongodb://localhost:27017/naotodo_test
MONGODB_DB_NAME=naotodo_test

# 测试环境优化配置
MONGODB_MAX_POOL_SIZE=5
MONGODB_MIN_POOL_SIZE=1
MONGODB_MAX_IDLE_TIME_MS=10000

# 安全密钥 (测试专用)
JWT_SECRET=test-jwt-secret-for-testing-only-32-chars
```

### 生产环境配置

```bash
# .env.production
NODE_ENV=production
PORT=3002

# 生产 MongoDB (带认证)
MONGODB_URI=mongodb://naotodo_user:secure_password@prod-server:27017/naotodo?authSource=admin&ssl=true&retryWrites=true&w=majority
MONGODB_DB_NAME=naotodo

# 生产环境连接池
MONGODB_MAX_POOL_SIZE=100
MONGODB_MIN_POOL_SIZE=10
MONGODB_MAX_IDLE_TIME_MS=60000
MONGODB_SERVER_SELECTION_TIMEOUT_MS=10000
MONGODB_SOCKET_TIMEOUT_MS=120000

# 安全配置
JWT_SECRET=${JWT_SECRET_FROM_SECURE_STORE}
SSL_CERT_PATH=/etc/ssl/certs/naotodo.pem
SSL_KEY_PATH=/etc/ssl/private/naotodo.key

# 性能和监控
DEV_SHOW_MONGOOSE_DEBUG=false
LOG_LEVEL=info
```

## 🔗 连接字符串详解

### 标准连接字符串格式

```
mongodb://[username:password@]host1[:port1][,...hostN[:portN]][/[defaultauthdb][?options]]
```

### 连接字符串示例

#### 1. 本地开发 (无认证)
```bash
MONGODB_URI=mongodb://localhost:27017/naotodo
```

#### 2. 本地开发 (带认证)
```bash
MONGODB_URI=mongodb://admin:password@localhost:27017/naotodo?authSource=admin
```

#### 3. 远程服务器 (基础认证)
```bash
MONGODB_URI=mongodb://naotodo_user:password@192.168.1.100:27017/naotodo
```

#### 4. 生产环境 (完整安全配置)
```bash
MONGODB_URI=mongodb://naotodo_user:secure_password@prod-mongo1:27017,prod-mongo2:27017,prod-mongo3:27017/naotodo?authSource=admin&ssl=true&retryWrites=true&w=majority&readPreference=primaryPreferred
```

#### 5. MongoDB Atlas (云服务)
```bash
MONGODB_URI=mongodb+srv://username:password@cluster0.abc123.mongodb.net/naotodo?retryWrites=true&w=majority
```

#### 6. 副本集配置
```bash
MONGODB_URI=mongodb://user:pass@mongo1:27017,mongo2:27017,mongo3:27017/naotodo?replicaSet=rs0&readPreference=secondaryPreferred
```

### 连接参数说明

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `authSource` | 认证数据库 | `admin` |
| `ssl` | 启用 SSL/TLS | `true` (生产) |
| `retryWrites` | 重试写入 | `true` |
| `w` | 写入关注级别 | `majority` |
| `readPreference` | 读取偏好 | `primaryPreferred` |
| `maxPoolSize` | 最大连接池 | `100` |
| `minPoolSize` | 最小连接池 | `5` |
| `maxIdleTimeMS` | 空闲超时 | `30000` |
| `serverSelectionTimeoutMS` | 服务器选择超时 | `5000` |
| `socketTimeoutMS` | Socket 超时 | `45000` |
| `heartbeatFrequencyMS` | 心跳频率 | `10000` |
| `compressors` | 压缩算法 | `snappy,zlib` |

## 🔒 安全配置

### 1. 创建数据库用户

```javascript
// 连接到 MongoDB
mongosh

// 切换到 admin 数据库
use admin

// 创建管理员用户
db.createUser({
  user: "admin",
  pwd: "secure_admin_password",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "dbAdminAnyDatabase", db: "admin" }
  ]
})

// 创建应用专用用户
use naotodo
db.createUser({
  user: "naotodo_user",
  pwd: "secure_app_password",
  roles: [
    { role: "readWrite", db: "naotodo" },
    { role: "dbAdmin", db: "naotodo" }
  ]
})
```

### 2. 启用认证

```bash
# 编辑 MongoDB 配置文件
sudo vim /etc/mongod.conf

# 添加安全配置
security:
  authorization: enabled
  
# 重启 MongoDB
sudo systemctl restart mongod
```

### 3. SSL/TLS 配置

```yaml
# mongod.conf
net:
  port: 27017
  bindIp: 127.0.0.1
  ssl:
    mode: requireSSL
    PEMKeyFile: /etc/ssl/mongodb.pem
    CAFile: /etc/ssl/ca.pem
```

### 4. 防火墙配置

```bash
# Ubuntu/Debian
sudo ufw allow from 192.168.1.0/24 to any port 27017
sudo ufw deny 27017

# CentOS/RHEL
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.1.0/24' port protocol='tcp' port='27017' accept"
sudo firewall-cmd --reload
```

## ⚡ 性能优化

### 1. 索引优化

```javascript
// 连接到数据库
mongosh mongodb://localhost:27017/naotodo

// 为常用查询创建索引
db.todos.createIndex({ "userId": 1, "isDeleted": 1 })
db.todos.createIndex({ "userId": 1, "projectId": 1, "state": 1 })
db.todos.createIndex({ "userId": 1, "dueDate.endAt": 1 })
db.todos.createIndex({ "userId": 1, "createdAt": -1 })

// 复合索引
db.todos.createIndex({ 
  "userId": 1, 
  "isDeleted": 1, 
  "state": 1, 
  "priority": 1 
})

// 全文搜索索引
db.todos.createIndex({ 
  "name": "text", 
  "description": "text" 
}, {
  weights: { name: 10, description: 5 },
  name: "todos_text_index"
})

// 查看索引使用情况
db.todos.getIndexes()
```

### 2. 连接池优化

```bash
# .env 中的连接池配置
MONGODB_MAX_POOL_SIZE=100      # 最大连接数
MONGODB_MIN_POOL_SIZE=10       # 最小连接数
MONGODB_MAX_IDLE_TIME_MS=60000 # 空闲连接超时 (60s)
MONGODB_SERVER_SELECTION_TIMEOUT_MS=5000  # 服务器选择超时 (5s)
MONGODB_SOCKET_TIMEOUT_MS=120000          # Socket 超时 (120s)
```

### 3. 内存和存储优化

```yaml
# mongod.conf
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 4
      journalCompressor: snappy
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: snappy
    indexConfig:
      prefixCompression: true

systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true
  logRotate: reopen

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongod.pid

operationProfiling:
  slowOpThresholdMs: 100
  mode: slowOp
```

## 🐛 故障排除

### 常见问题及解决方案

#### 1. 连接被拒绝
```bash
Error: MongoNetworkError: connect ECONNREFUSED 127.0.0.1:27017

# 解决方案:
# 1. 检查 MongoDB 服务状态
sudo systemctl status mongod

# 2. 启动 MongoDB 服务
sudo systemctl start mongod

# 3. 检查端口是否被占用
netstat -tulpn | grep :27017

# 4. 检查配置文件
sudo vim /etc/mongod.conf
```

#### 2. 认证失败
```bash
Error: Authentication failed

# 解决方案:
# 1. 检查用户名和密码
mongosh --username naotodo_user --password --authenticationDatabase naotodo

# 2. 重新创建用户
mongosh
use naotodo
db.dropUser("naotodo_user")
db.createUser({...})
```

#### 3. 连接超时
```bash
Error: Server selection timed out

# 解决方案:
# 1. 增加超时时间
MONGODB_SERVER_SELECTION_TIMEOUT_MS=10000

# 2. 检查网络连接
ping your-mongodb-host

# 3. 检查防火墙设置
sudo ufw status
```

#### 4. SSL 证书错误
```bash
Error: SSL certificate verification failed

# 解决方案:
# 1. 使用正确的证书路径
MONGODB_URI=mongodb://user:pass@host:27017/db?ssl=true&sslCertificateKeyFile=/path/to/cert.pem

# 2. 跳过证书验证 (仅开发环境)
MONGODB_URI=mongodb://user:pass@host:27017/db?ssl=true&sslValidate=false
```

#### 5. 内存不足
```bash
Error: Cannot allocate memory

# 解决方案:
# 1. 调整 WiredTiger 缓存大小
# 在 mongod.conf 中设置:
storage.wiredTiger.engineConfig.cacheSizeGB: 2

# 2. 监控内存使用
db.serverStatus().mem
db.runCommand({serverStatus: 1}).wiredTiger.cache
```

## 🔧 管理工具

### 1. MongoDB 状态检查脚本
```bash
#!/bin/bash
# mongodb-status.sh

echo "=== MongoDB 状态检查 ==="

# 检查服务状态
echo "1. 服务状态:"
systemctl is-active mongod

# 检查进程
echo "2. 进程状态:"
pgrep -f mongod

# 检查端口
echo "3. 端口监听:"
netstat -tulpn | grep :27017

# 检查连接
echo "4. 连接测试:"
mongosh --eval "db.adminCommand('ping')"

# 检查数据库大小
echo "5. 数据库统计:"
mongosh --quiet --eval "
  db.adminCommand('listDatabases').databases.forEach(
    function(database) {
      print(database.name + ': ' + (database.sizeOnDisk/1024/1024).toFixed(2) + ' MB');
    }
  )
"
```

### 2. 数据备份脚本
```bash
#!/bin/bash
# mongodb-backup.sh

BACKUP_DIR="/backup/mongodb"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="naotodo"

echo "开始备份 MongoDB 数据库: $DB_NAME"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 执行备份
mongodump \
  --db "$DB_NAME" \
  --out "$BACKUP_DIR/$DATE" \
  --gzip

# 压缩备份文件
tar -czf "$BACKUP_DIR/${DB_NAME}_${DATE}.tar.gz" -C "$BACKUP_DIR" "$DATE"

# 清理临时文件
rm -rf "$BACKUP_DIR/$DATE"

# 保留最近30天的备份
find "$BACKUP_DIR" -name "${DB_NAME}_*.tar.gz" -mtime +30 -delete

echo "备份完成: $BACKUP_DIR/${DB_NAME}_${DATE}.tar.gz"
```

### 3. 数据恢复脚本
```bash
#!/bin/bash
# mongodb-restore.sh

if [ $# -eq 0 ]; then
    echo "用法: $0 <backup_file.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"
TEMP_DIR="/tmp/mongodb_restore_$$"
DB_NAME="naotodo"

echo "开始恢复 MongoDB 数据库: $DB_NAME"
echo "备份文件: $BACKUP_FILE"

# 解压备份文件
mkdir -p "$TEMP_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# 查找备份目录
BACKUP_DIR=$(find "$TEMP_DIR" -type d -name "$DB_NAME" | head -1)

if [ -z "$BACKUP_DIR" ]; then
    echo "错误: 在备份文件中找不到数据库 $DB_NAME"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 执行恢复
mongorestore \
  --db "$DB_NAME" \
  --drop \
  --gzip \
  "$BACKUP_DIR"

# 清理临时文件
rm -rf "$TEMP_DIR"

echo "恢复完成"
```

## 📚 更多资源

- [MongoDB 官方文档](https://docs.mongodb.com/)
- [MongoDB 安全检查清单](https://docs.mongodb.com/manual/security/security-checklist/)
- [MongoDB 性能最佳实践](https://docs.mongodb.com/manual/administration/production-notes/)
- [Mongoose 官方文档](https://mongoosejs.com/docs/)
- [MongoDB University](https://university.mongodb.com/) - 免费在线课程

---

🎯 **配置完成后，您可以使用 `pnpm run websrv dev` 启动 NaoTodo 服务器，系统会自动连接到配置的 MongoDB 数据库！**
# MongoDB 故障排除指南

本指南帮助诊断和解决 NaoTodo 项目中常见的 MongoDB 配置和连接问题。

## 目录

1. [连接问题](#连接问题)
2. [认证问题](#认证问题)
3. [性能问题](#性能问题)
4. [数据同步问题](#数据同步问题)
5. [磁盘空间问题](#磁盘空间问题)
6. [常用诊断命令](#常用诊断命令)
7. [日志分析](#日志分析)
8. [紧急恢复流程](#紧急恢复流程)

## 连接问题

### 问题：无法连接到 MongoDB

**症状：**
- 应用启动时显示"无法连接到 MongoDB"
- 超时错误
- 连接被拒绝

**排查步骤：**

1. **检查 MongoDB 服务状态**
   ```bash
   # Linux/macOS
   sudo systemctl status mongod
   
   # macOS (Homebrew)
   brew services list | grep mongodb
   ```

2. **检查端口是否开放**
   ```bash
   # 检查 MongoDB 默认端口 27017
   netstat -an | grep 27017
   telnet localhost 27017
   ```

3. **验证连接字符串**
   ```bash
   # 测试基本连接
   mongosh "mongodb://localhost:27017/naotodo"
   
   # 测试带认证的连接
   mongosh "mongodb://username:password@host:port/naotodo"
   ```

4. **检查防火墙设置**
   ```bash
   # Ubuntu/Debian
   sudo ufw status
   sudo ufw allow 27017
   
   # CentOS/RHEL
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --add-port=27017/tcp --permanent
   ```

**解决方案：**
- 启动 MongoDB 服务：`sudo systemctl start mongod`
- 更新 `.env` 文件中的 `MONGODB_URI`
- 检查网络配置和防火墙规则

### 问题：连接池耗尽

**症状：**
- `MongoServerSelectionError`
- 应用响应缓慢
- 连接超时

**解决方案：**
```bash
# 调整 .env 文件中的连接池配置
MONGODB_MAX_POOL_SIZE=50
MONGODB_MIN_POOL_SIZE=10
MONGODB_MAX_IDLE_TIME_MS=60000
```

## 认证问题

### 问题：认证失败

**症状：**
- `Authentication failed`
- `Unauthorized`

**排查步骤：**

1. **验证用户和密码**
   ```javascript
   // 在 mongosh 中测试
   use naotodo
   db.auth("username", "password")
   ```

2. **检查用户权限**
   ```javascript
   use naotodo
   db.runCommand({usersInfo: "naotodo_user"})
   ```

3. **重置用户密码**
   ```javascript
   use naotodo
   db.changeUserPassword("naotodo_user", "new_password")
   ```

**解决方案：**
```bash
# 创建新用户
cd nao-todo-server
./scripts/mongodb/setup-mongodb.sh
# 选择选项 2) 创建数据库用户
```

## 性能问题

### 问题：查询缓慢

**诊断命令：**
```javascript
// 启用分析器
use naotodo
db.setProfilingLevel(2)

// 查看慢查询
db.system.profile.find().limit(5).sort({ts: -1}).pretty()

// 分析特定查询
db.todos.find({userId: "user123"}).explain("executionStats")
```

**优化建议：**
1. 创建必要的索引
2. 优化查询条件
3. 使用投影减少数据传输
4. 考虑分页查询

### 问题：内存使用过高

**检查内存使用：**
```javascript
use naotodo
db.serverStatus().mem
db.stats()
```

**解决方案：**
- 调整 WiredTiger 缓存大小
- 优化索引策略
- 清理不必要的数据

## 数据同步问题

### 问题：数据不一致

**检查数据完整性：**
```javascript
use naotodo

// 检查集合统计
db.todos.count()
db.users.count()
db.projects.count()

// 验证数据关系
db.todos.aggregate([
  {$group: {_id: null, totalUsers: {$addToSet: "$userId"}}},
  {$project: {userCount: {$size: "$totalUsers"}}}
])
```

**修复方案：**
```bash
# 从备份恢复
cd nao-todo-server
./scripts/mongodb/restore-mongodb.sh backup_20240101_120000.tar.gz
```

## 磁盘空间问题

### 问题：磁盘空间不足

**检查磁盘使用：**
```bash
# 检查 MongoDB 数据目录大小
du -sh /var/lib/mongodb

# 检查日志文件大小
du -sh /var/log/mongodb

# 检查可用空间
df -h
```

**清理方案：**
```bash
# 压缩数据库
mongosh --eval "db.runCommand({compact: 'collection_name'})"

# 清理日志
sudo logrotate -f /etc/logrotate.d/mongodb

# 删除旧备份
find /backup/mongodb -name "*.tar.gz" -mtime +30 -delete
```

## 常用诊断命令

### MongoDB 状态检查

```javascript
// 服务器状态
db.serverStatus()

// 复制集状态
rs.status()

// 数据库统计
db.stats()

// 连接状态
db.runCommand({currentOp: true})

// 索引使用统计
db.todos.aggregate([{$indexStats: {}}])
```

### 系统资源监控

```bash
# CPU 和内存使用
top -p $(pgrep mongod)

# I/O 统计
iostat -x 1

# 网络连接
netstat -an | grep :27017

# 进程信息
ps aux | grep mongod
```

## 日志分析

### 查看 MongoDB 日志

```bash
# 实时查看日志
tail -f /var/log/mongodb/mongod.log

# 搜索错误
grep -i "error\|exception\|failed" /var/log/mongodb/mongod.log

# 分析连接问题
grep -i "connection" /var/log/mongodb/mongod.log
```

### 应用日志

```bash
# 查看应用日志
cd nao-todo-server
tail -f logs/app.log

# 搜索 MongoDB 相关错误
grep -i "mongodb\|mongoose" logs/app.log
```

## 紧急恢复流程

### 1. 数据库无法启动

```bash
# 检查数据目录权限
sudo chown -R mongodb:mongodb /var/lib/mongodb

# 检查配置文件
sudo mongod --config /etc/mongod.conf --repair

# 使用备份恢复
cd nao-todo-server
./scripts/mongodb/restore-mongodb.sh --drop latest_backup.tar.gz
```

### 2. 数据损坏

```bash
# 备份当前状态
mongodump --out=/backup/emergency_$(date +%Y%m%d_%H%M%S)

# 修复数据库
mongod --repair

# 验证修复结果
mongosh --eval "db.runCommand({validate: 'todos'})"
```

### 3. 性能严重下降

```bash
# 临时解决方案
# 1. 重启 MongoDB 服务
sudo systemctl restart mongod

# 2. 清理连接
mongosh --eval "db.runCommand({killOp: op_id})"

# 3. 重建索引
mongosh --eval "db.todos.reIndex()"
```

## 预防措施

### 1. 定期备份

```bash
# 设置定时备份
crontab -e
# 添加：0 2 * * * /path/to/backup-mongodb.sh --compress
```

### 2. 监控配置

```bash
# 配置监控脚本
cat > /usr/local/bin/mongodb-health-check.sh << 'EOF'
#!/bin/bash
if ! mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    echo "MongoDB health check failed" | mail -s "MongoDB Alert" admin@example.com
fi
EOF

chmod +x /usr/local/bin/mongodb-health-check.sh

# 添加到 crontab
crontab -e
# 添加：*/5 * * * * /usr/local/bin/mongodb-health-check.sh
```

### 3. 性能调优

```yaml
# /etc/mongod.conf 优化配置
storage:
  wiredTiger:
    engineConfig:
      cacheSizeGB: 4  # 根据服务器内存调整
      journalCompressor: snappy
    collectionConfig:
      blockCompressor: snappy

operationProfiling:
  slowOpThresholdMs: 100
  mode: slowOp
```

## 获取帮助

当遇到无法解决的问题时：

1. **收集信息**
   ```bash
   # 生成诊断报告
   ./scripts/mongodb/generate-diagnostic-report.sh
   ```

2. **社区支持**
   - MongoDB 官方文档
   - Stack Overflow
   - MongoDB 社区论坛

3. **联系管理员**
   - 提供详细的错误信息
   - 包含相关日志文件
   - 描述问题复现步骤

## 常见错误代码

| 错误码 | 描述 | 解决方法 |
|--------|------|----------|
| 18 | AuthenticationFailed | 检查用户名和密码 |
| 13 | Unauthorized | 检查用户权限 |
| 6 | HostUnreachable | 检查网络连接 |
| 89 | NetworkTimeout | 增加超时时间 |
| 28 | PathNotFound | 检查数据库路径 |

---

**注意：** 在生产环境中进行任何修复操作之前，请务必备份当前数据。
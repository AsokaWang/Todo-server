# MongoDB 管理脚本

这个目录包含了 NaoTodo 项目的 MongoDB 管理和维护脚本。

## 脚本列表

### 1. 安装配置脚本

#### `setup-mongodb.sh`
自动安装和配置 MongoDB 服务器。

**功能：**
- 自动检测操作系统并安装对应的 MongoDB 版本
- 配置安全设置和用户认证
- 创建 NaoTodo 专用数据库用户
- 初始化数据库索引

**使用方法：**
```bash
./scripts/mongodb/setup-mongodb.sh
```

**支持的操作系统：**
- Ubuntu/Debian
- CentOS/RHEL
- macOS (通过 Homebrew)

### 2. 备份脚本

#### `backup-mongodb.sh`
自动备份 MongoDB 数据库。

**功能：**
- 支持完整数据库备份
- 可选择特定集合备份
- 自动压缩和清理旧备份
- 支持远程数据库备份
- 备份报告生成

**使用方法：**
```bash
# 基本备份
./scripts/mongodb/backup-mongodb.sh

# 压缩备份
./scripts/mongodb/backup-mongodb.sh --compress

# 指定集合备份
./scripts/mongodb/backup-mongodb.sh --collections users,todos

# 查看帮助
./scripts/mongodb/backup-mongodb.sh --help
```

**常用选项：**
- `-c, --compress`: 压缩备份文件
- `-d, --dir DIR`: 指定备份目录
- `-r, --retention DAYS`: 设置保留天数
- `--collections COLS`: 指定要备份的集合
- `--exclude COLS`: 排除特定集合

### 3. 恢复脚本

#### `restore-mongodb.sh`
从备份文件恢复 MongoDB 数据库。

**功能：**
- 支持从压缩文件恢复
- 支持从目录恢复
- 可选择性恢复特定集合
- 恢复前预览和确认
- 恢复后验证

**使用方法：**
```bash
# 从备份文件恢复
./scripts/mongodb/restore-mongodb.sh backup_20240101_120000.tar.gz

# 删除现有数据后恢复
./scripts/mongodb/restore-mongodb.sh --drop backup.tar.gz

# 只恢复特定集合
./scripts/mongodb/restore-mongodb.sh --collection users backup.tar.gz

# 预览恢复操作
./scripts/mongodb/restore-mongodb.sh --dry-run backup.tar.gz

# 查看可用备份
./scripts/mongodb/restore-mongodb.sh
```

**常用选项：**
- `--drop`: 恢复前删除现有数据库
- `--collection COLLECTION`: 只恢复指定集合
- `--exclude COLLECTION`: 排除指定集合
- `--dry-run`: 预览模式，不实际执行

### 4. 诊断报告脚本

#### `generate-diagnostic-report.sh`
生成详细的 MongoDB 系统诊断报告。

**功能：**
- 系统资源使用情况
- MongoDB 服务状态
- 数据库性能指标
- 连接测试和配置验证
- 日志分析和问题诊断
- 优化建议

**使用方法：**
```bash
# 生成基本报告
./scripts/mongodb/generate-diagnostic-report.sh

# 包含日志分析
./scripts/mongodb/generate-diagnostic-report.sh --include-logs

# 生成 HTML 格式报告
./scripts/mongodb/generate-diagnostic-report.sh --format html

# 指定输出目录
./scripts/mongodb/generate-diagnostic-report.sh -o /custom/path
```

**输出格式：**
- `text`: 纯文本报告（默认）
- `html`: HTML 格式报告
- `json`: JSON 格式报告

## 配置文件

### 环境变量配置
所有脚本都会读取项目根目录的 `.env` 文件来获取配置信息：

```bash
# MongoDB 连接配置
MONGODB_URI=mongodb://localhost:27017/naotodo
MONGODB_DB_NAME=naotodo

# 备份配置
BACKUP_DIR=/backup/mongodb
RETENTION_DAYS=30

# 通知配置（可选）
BACKUP_WEBHOOK_URL=https://hooks.slack.com/...
BACKUP_EMAIL=admin@example.com
```

## 使用场景

### 日常运维

1. **定期备份**
   ```bash
   # 添加到 crontab
   0 2 * * * /path/to/backup-mongodb.sh --compress
   ```

2. **健康检查**
   ```bash
   # 每周生成诊断报告
   0 9 * * 1 /path/to/generate-diagnostic-report.sh --include-logs
   ```

3. **故障恢复**
   ```bash
   # 从最新备份恢复
   ./restore-mongodb.sh latest_backup.tar.gz
   ```

### 开发环境

1. **快速重置数据库**
   ```bash
   # 备份当前数据
   ./backup-mongodb.sh

   # 从干净的数据恢复
   ./restore-mongodb.sh --drop clean_database.tar.gz
   ```

2. **性能测试**
   ```bash
   # 生成性能报告
   ./generate-diagnostic-report.sh --format html
   ```

### 生产部署

1. **初始化环境**
   ```bash
   # 自动安装和配置
   ./setup-mongodb.sh
   ```

2. **数据迁移**
   ```bash
   # 从旧环境备份
   ./backup-mongodb.sh -u "mongodb://old-server:27017/naotodo"

   # 在新环境恢复
   ./restore-mongodb.sh migration_backup.tar.gz
   ```

## 安全注意事项

1. **权限控制**
   - 确保脚本文件有适当的执行权限
   - 限制对备份文件的访问权限
   - 定期轮换数据库密码

2. **敏感信息保护**
   - 不要在脚本中硬编码密码
   - 使用环境变量或配置文件
   - 在版本控制中排除 `.env` 文件

3. **网络安全**
   - 在生产环境启用 SSL/TLS
   - 限制数据库访问的IP地址
   - 使用防火墙保护数据库端口

## 故障排除

如果脚本执行出现问题，请查看：

1. **检查日志文件**
   ```bash
   tail -f /var/log/mongodb/mongod.log
   ```

2. **验证配置**
   ```bash
   # 检查环境变量
   cat .env

   # 测试连接
   mongosh "$MONGODB_URI"
   ```

3. **生成诊断报告**
   ```bash
   ./generate-diagnostic-report.sh --include-logs
   ```

## 获取帮助

每个脚本都支持 `--help` 参数，可以查看详细的使用说明：

```bash
./setup-mongodb.sh --help
./backup-mongodb.sh --help
./restore-mongodb.sh --help
./generate-diagnostic-report.sh --help
```

更多信息请参考：
- [MONGODB_SETUP.md](../../MONGODB_SETUP.md) - 详细的MongoDB配置指南
- [MONGODB_TROUBLESHOOTING.md](../../MONGODB_TROUBLESHOOTING.md) - 故障排除指南
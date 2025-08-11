#!/bin/bash

# MongoDB 自动安装和配置脚本
# 适用于 NaoTodo 项目

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        else
            error "无法检测 Linux 发行版"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VER=$(sw_vers -productVersion)
    else
        error "不支持的操作系统: $OSTYPE"
    fi
    
    log "检测到操作系统: $OS $VER"
}

# 检查 MongoDB 是否已安装
check_mongodb() {
    if command -v mongod &> /dev/null; then
        MONGODB_VERSION=$(mongod --version | grep "db version" | cut -d' ' -f3)
        log "MongoDB 已安装，版本: $MONGODB_VERSION"
        return 0
    else
        warn "MongoDB 未安装"
        return 1
    fi
}

# 安装 MongoDB (Ubuntu/Debian)
install_mongodb_ubuntu() {
    log "在 Ubuntu/Debian 上安装 MongoDB..."
    
    # 导入公钥
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
    
    # 添加仓库
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    
    # 更新包列表
    sudo apt-get update
    
    # 安装 MongoDB
    sudo apt-get install -y mongodb-org
    
    # 启动服务
    sudo systemctl start mongod
    sudo systemctl enable mongod
    
    log "MongoDB 安装完成"
}

# 安装 MongoDB (CentOS/RHEL)
install_mongodb_centos() {
    log "在 CentOS/RHEL 上安装 MongoDB..."
    
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
    
    log "MongoDB 安装完成"
}

# 安装 MongoDB (macOS)
install_mongodb_macos() {
    log "在 macOS 上安装 MongoDB..."
    
    # 检查 Homebrew
    if ! command -v brew &> /dev/null; then
        error "请先安装 Homebrew: https://brew.sh/"
    fi
    
    # 添加 MongoDB 官方 tap
    brew tap mongodb/brew
    
    # 安装 MongoDB Community Edition
    brew install mongodb-community
    
    # 启动服务
    brew services start mongodb/brew/mongodb-community
    
    log "MongoDB 安装完成"
}

# 配置 MongoDB 安全设置
configure_mongodb_security() {
    log "配置 MongoDB 安全设置..."
    
    # 备份原配置文件
    if [ -f /etc/mongod.conf ]; then
        sudo cp /etc/mongod.conf /etc/mongod.conf.backup
        log "已备份原配置文件到 /etc/mongod.conf.backup"
    fi
    
    # 创建安全配置
    cat <<EOF | sudo tee /tmp/mongod-security.conf
# MongoDB 安全配置片段
security:
  authorization: enabled
  
# 网络配置
net:
  port: 27017
  bindIp: 127.0.0.1,$(hostname -I | awk '{print $1}')
  
# 日志配置
systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true
  logRotate: reopen
  
# 存储配置
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 2
      journalCompressor: snappy
    collectionConfig:
      blockCompressor: snappy
EOF

    warn "请手动将 /tmp/mongod-security.conf 的内容合并到 /etc/mongod.conf"
    warn "然后重启 MongoDB: sudo systemctl restart mongod"
}

# 创建 NaoTodo 数据库用户
create_naotodo_user() {
    log "创建 NaoTodo 数据库用户..."
    
    read -s -p "请输入管理员密码: " ADMIN_PASS
    echo
    read -s -p "请输入 naotodo 用户密码: " NAOTODO_PASS
    echo
    
    # 创建用户脚本
    cat <<EOF > /tmp/create-naotodo-user.js
// 创建管理员用户
use admin
db.createUser({
  user: "admin",
  pwd: "$ADMIN_PASS",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "dbAdminAnyDatabase", db: "admin" }
  ]
})

// 创建 naotodo 应用用户
use naotodo
db.createUser({
  user: "naotodo_user",
  pwd: "$NAOTODO_PASS",
  roles: [
    { role: "readWrite", db: "naotodo" },
    { role: "dbAdmin", db: "naotodo" }
  ]
})

print("用户创建完成")
EOF

    # 执行脚本
    mongosh < /tmp/create-naotodo-user.js
    
    # 清理临时文件
    rm -f /tmp/create-naotodo-user.js
    
    log "数据库用户创建完成"
    info "请更新 .env 文件中的 MONGODB_URI："
    echo "MONGODB_URI=mongodb://naotodo_user:$NAOTODO_PASS@localhost:27017/naotodo?authSource=naotodo"
}

# 初始化 NaoTodo 数据库
init_naotodo_db() {
    log "初始化 NaoTodo 数据库..."
    
    cat <<EOF > /tmp/init-naotodo.js
// 使用 naotodo 数据库
use naotodo

// 创建集合和索引
db.users.createIndex({ "email": 1 }, { unique: true })
db.users.createIndex({ "account": 1 }, { unique: true })

db.todos.createIndex({ "userId": 1, "isDeleted": 1 })
db.todos.createIndex({ "userId": 1, "projectId": 1, "state": 1 })
db.todos.createIndex({ "userId": 1, "dueDate.endAt": 1 })
db.todos.createIndex({ "userId": 1, "createdAt": -1 })

db.projects.createIndex({ "userId": 1, "title": 1 }, { unique: true })

db.tags.createIndex({ "userId": 1, "name": 1 })

db.comments.createIndex({ "todoId": 1, "createdAt": -1 })

db.events.createIndex({ "userId": 1, "createdAt": -1 })
db.events.createIndex({ "todoId": 1, "createdAt": -1 })

print("数据库索引创建完成")
EOF

    mongosh < /tmp/init-naotodo.js
    rm -f /tmp/init-naotodo.js
    
    log "数据库初始化完成"
}

# 验证安装
verify_installation() {
    log "验证 MongoDB 安装..."
    
    # 检查服务状态
    if systemctl is-active --quiet mongod || brew services list | grep mongodb-community | grep started; then
        log "✅ MongoDB 服务运行正常"
    else
        error "❌ MongoDB 服务未运行"
    fi
    
    # 检查连接
    if mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
        log "✅ MongoDB 连接正常"
    else
        error "❌ 无法连接到 MongoDB"
    fi
    
    # 显示版本信息
    MONGODB_VERSION=$(mongosh --quiet --eval "db.version()")
    log "✅ MongoDB 版本: $MONGODB_VERSION"
}

# 主函数
main() {
    info "=== NaoTodo MongoDB 安装配置脚本 ==="
    echo
    
    # 检测操作系统
    detect_os
    
    # 检查是否已安装 MongoDB
    if check_mongodb; then
        read -p "MongoDB 已安装，是否重新配置？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "跳过安装，进行配置..."
        else
            log "继续重新配置..."
        fi
    else
        # 根据操作系统安装 MongoDB
        case $OS in
            *"Ubuntu"*|*"Debian"*)
                install_mongodb_ubuntu
                ;;
            *"CentOS"*|*"Red Hat"*|*"RHEL"*)
                install_mongodb_centos
                ;;
            *"macOS"*)
                install_mongodb_macos
                ;;
            *)
                error "不支持的操作系统: $OS"
                ;;
        esac
    fi
    
    # 验证安装
    verify_installation
    
    # 配置选项
    echo
    info "选择配置选项："
    echo "1) 配置安全设置"
    echo "2) 创建数据库用户"  
    echo "3) 初始化 NaoTodo 数据库"
    echo "4) 全部配置"
    echo "5) 跳过配置"
    
    read -p "请选择 (1-5): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            configure_mongodb_security
            ;;
        2)
            create_naotodo_user
            ;;
        3)
            init_naotodo_db
            ;;
        4)
            configure_mongodb_security
            create_naotodo_user
            init_naotodo_db
            ;;
        5)
            log "跳过配置"
            ;;
        *)
            warn "无效选择，跳过配置"
            ;;
    esac
    
    echo
    log "=== 配置完成 ==="
    info "下一步："
    echo "1. 检查 MongoDB 配置文件: /etc/mongod.conf"
    echo "2. 更新 NaoTodo .env 文件中的 MONGODB_URI"
    echo "3. 重启 MongoDB 服务: sudo systemctl restart mongod"
    echo "4. 启动 NaoTodo 服务器: pnpm run websrv dev"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
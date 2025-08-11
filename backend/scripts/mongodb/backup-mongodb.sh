#!/bin/bash

# MongoDB 备份脚本
# 支持本地和远程 MongoDB 备份

set -e

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-/backup/mongodb}"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="${DB_NAME:-naotodo}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# 从 .env 文件读取配置
ENV_FILE="${SCRIPT_DIR}/../../.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# 显示使用帮助
show_help() {
    cat << EOF
MongoDB 备份脚本

用法:
  $0 [选项] [数据库名]

选项:
  -h, --help              显示帮助信息
  -d, --dir DIR           备份目录 (默认: $BACKUP_DIR)
  -r, --retention DAYS    保留天数 (默认: $RETENTION_DAYS)
  -c, --compress          压缩备份文件
  -u, --uri URI           MongoDB 连接字符串
  --collections COLS      指定集合 (逗号分隔)
  --exclude COLS          排除集合 (逗号分隔)
  --oplog                 包含 oplog
  --gzip                  使用 gzip 压缩

环境变量:
  MONGODB_URI             MongoDB 连接字符串
  BACKUP_DIR              备份目录
  DB_NAME                 数据库名
  RETENTION_DAYS          保留天数

示例:
  $0                      # 备份默认数据库
  $0 naotodo              # 备份指定数据库
  $0 -d /custom/backup    # 使用自定义备份目录
  $0 --compress naotodo   # 压缩备份文件
  $0 --collections users,todos  # 只备份指定集合

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -r|--retention)
                RETENTION_DAYS="$2"
                shift 2
                ;;
            -c|--compress)
                COMPRESS=true
                shift
                ;;
            -u|--uri)
                MONGODB_URI="$2"
                shift 2
                ;;
            --collections)
                COLLECTIONS="$2"
                shift 2
                ;;
            --exclude)
                EXCLUDE_COLLECTIONS="$2"
                shift 2
                ;;
            --oplog)
                INCLUDE_OPLOG=true
                shift
                ;;
            --gzip)
                USE_GZIP=true
                shift
                ;;
            -*)
                error "未知选项: $1"
                ;;
            *)
                DB_NAME="$1"
                shift
                ;;
        esac
    done
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    if ! command -v mongodump &> /dev/null; then
        missing_deps+=("mongodump")
    fi
    
    if [ "$COMPRESS" = true ] && ! command -v tar &> /dev/null; then
        missing_deps+=("tar")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "缺少依赖: ${missing_deps[*]}. 请安装 MongoDB 数据库工具。"
    fi
}

# 创建备份目录
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log "创建备份目录: $BACKUP_DIR"
    fi
    
    # 检查目录权限
    if [ ! -w "$BACKUP_DIR" ]; then
        error "备份目录没有写权限: $BACKUP_DIR"
    fi
}

# 构建 mongodump 命令
build_mongodump_cmd() {
    local cmd="mongodump"
    
    # MongoDB 连接字符串
    if [ -n "$MONGODB_URI" ]; then
        cmd="$cmd --uri=\"$MONGODB_URI\""
    else
        cmd="$cmd --host=localhost:27017"
    fi
    
    # 数据库名
    if [ -n "$DB_NAME" ]; then
        cmd="$cmd --db=\"$DB_NAME\""
    fi
    
    # 输出目录
    cmd="$cmd --out=\"$BACKUP_DIR/$DATE\""
    
    # 指定集合
    if [ -n "$COLLECTIONS" ]; then
        IFS=',' read -ra COLLECTION_ARRAY <<< "$COLLECTIONS"
        for collection in "${COLLECTION_ARRAY[@]}"; do
            cmd="$cmd --collection=\"$collection\""
        done
    fi
    
    # 排除集合
    if [ -n "$EXCLUDE_COLLECTIONS" ]; then
        IFS=',' read -ra EXCLUDE_ARRAY <<< "$EXCLUDE_COLLECTIONS"
        for collection in "${EXCLUDE_ARRAY[@]}"; do
            cmd="$cmd --excludeCollection=\"$collection\""
        done
    fi
    
    # 包含 oplog
    if [ "$INCLUDE_OPLOG" = true ]; then
        cmd="$cmd --oplog"
    fi
    
    # 使用 gzip 压缩
    if [ "$USE_GZIP" = true ]; then
        cmd="$cmd --gzip"
    fi
    
    echo "$cmd"
}

# 执行备份
perform_backup() {
    local backup_cmd
    backup_cmd=$(build_mongodump_cmd)
    
    log "开始备份 MongoDB 数据库: $DB_NAME"
    log "备份命令: $backup_cmd"
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行备份
    eval "$backup_cmd"
    
    # 计算耗时
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "备份完成，耗时: ${duration}s"
    
    # 检查备份结果
    if [ -d "$BACKUP_DIR/$DATE" ]; then
        local backup_size=$(du -sh "$BACKUP_DIR/$DATE" | cut -f1)
        log "备份大小: $backup_size"
    else
        error "备份失败: 找不到备份目录 $BACKUP_DIR/$DATE"
    fi
}

# 压缩备份文件
compress_backup() {
    if [ "$COMPRESS" = true ]; then
        log "压缩备份文件..."
        
        cd "$BACKUP_DIR"
        tar -czf "${DB_NAME}_${DATE}.tar.gz" "$DATE"
        
        if [ $? -eq 0 ]; then
            local compressed_size=$(du -sh "${DB_NAME}_${DATE}.tar.gz" | cut -f1)
            log "压缩完成: ${DB_NAME}_${DATE}.tar.gz (大小: $compressed_size)"
            
            # 删除原始备份目录
            rm -rf "$DATE"
            log "清理原始备份目录"
        else
            error "压缩失败"
        fi
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log "清理 $RETENTION_DAYS 天前的备份文件..."
    
    # 清理压缩文件
    find "$BACKUP_DIR" -name "${DB_NAME}_*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    
    # 清理目录
    find "$BACKUP_DIR" -type d -name "*" -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true
    
    local remaining_count=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.tar.gz" -o -type d -name "20*" | wc -l)
    log "剩余备份文件数: $remaining_count"
}

# 生成备份报告
generate_report() {
    local report_file="$BACKUP_DIR/backup_report_${DATE}.txt"
    
    cat > "$report_file" << EOF
MongoDB 备份报告
===============

备份时间: $(date)
数据库名: $DB_NAME
备份目录: $BACKUP_DIR
MongoDB URI: $MONGODB_URI

备份详情:
EOF

    if [ "$COMPRESS" = true ]; then
        echo "备份文件: ${DB_NAME}_${DATE}.tar.gz" >> "$report_file"
        if [ -f "$BACKUP_DIR/${DB_NAME}_${DATE}.tar.gz" ]; then
            echo "文件大小: $(du -sh "$BACKUP_DIR/${DB_NAME}_${DATE}.tar.gz" | cut -f1)" >> "$report_file"
        fi
    else
        echo "备份目录: $DATE" >> "$report_file"
        if [ -d "$BACKUP_DIR/$DATE" ]; then
            echo "目录大小: $(du -sh "$BACKUP_DIR/$DATE" | cut -f1)" >> "$report_file"
        fi
    fi
    
    echo "" >> "$report_file"
    echo "备份状态: 成功" >> "$report_file"
    echo "保留策略: $RETENTION_DAYS 天" >> "$report_file"
    
    log "备份报告生成: $report_file"
}

# 发送通知 (可选)
send_notification() {
    if [ -n "$BACKUP_WEBHOOK_URL" ]; then
        local status="success"
        local message="MongoDB 备份完成: $DB_NAME ($DATE)"
        
        curl -X POST "$BACKUP_WEBHOOK_URL" \
             -H "Content-Type: application/json" \
             -d "{\"text\":\"$message\", \"status\":\"$status\"}" \
             &> /dev/null || warn "通知发送失败"
    fi
    
    if [ -n "$BACKUP_EMAIL" ] && command -v mail &> /dev/null; then
        echo "MongoDB 备份完成: $DB_NAME" | mail -s "NaoTodo 备份通知" "$BACKUP_EMAIL" || warn "邮件发送失败"
    fi
}

# 主函数
main() {
    info "=== NaoTodo MongoDB 备份脚本 ==="
    
    # 解析参数
    parse_args "$@"
    
    # 检查依赖
    check_dependencies
    
    # 创建备份目录
    create_backup_dir
    
    # 显示配置信息
    info "备份配置:"
    echo "  数据库名: $DB_NAME"
    echo "  备份目录: $BACKUP_DIR"
    echo "  保留天数: $RETENTION_DAYS"
    echo "  压缩备份: ${COMPRESS:-false}"
    echo "  MongoDB URI: ${MONGODB_URI:-默认连接}"
    echo
    
    # 执行备份
    perform_backup
    
    # 压缩备份
    compress_backup
    
    # 清理旧备份
    cleanup_old_backups
    
    # 生成报告
    generate_report
    
    # 发送通知
    send_notification
    
    log "备份任务完成"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
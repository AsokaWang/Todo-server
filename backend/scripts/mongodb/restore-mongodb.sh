#!/bin/bash

# MongoDB 恢复脚本
# 支持从备份文件恢复 MongoDB 数据

set -e

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-/backup/mongodb}"
DB_NAME="${DB_NAME:-naotodo}"
TEMP_DIR="/tmp/mongodb_restore_$$"

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

# 清理临时文件
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log "清理临时文件: $TEMP_DIR"
    fi
}

# 设置退出时清理
trap cleanup EXIT

# 显示使用帮助
show_help() {
    cat << EOF
MongoDB 恢复脚本

用法:
  $0 [选项] <备份文件或目录>

选项:
  -h, --help              显示帮助信息
  -d, --db DATABASE       目标数据库名 (默认: $DB_NAME)
  -u, --uri URI           MongoDB 连接字符串
  --drop                  恢复前删除现有数据库
  --collection COLLECTION 只恢复指定集合
  --exclude COLLECTION    排除指定集合
  --dry-run               预览恢复操作，不实际执行
  --gzip                  处理 gzip 压缩的备份
  -y, --yes               自动确认所有操作

环境变量:
  MONGODB_URI             MongoDB 连接字符串
  BACKUP_DIR              备份目录
  DB_NAME                 数据库名

示例:
  $0 backup_20240101_120000.tar.gz           # 恢复压缩备份文件
  $0 /path/to/backup/20240101_120000          # 恢复目录
  $0 --drop backup.tar.gz                    # 删除现有数据后恢复
  $0 --collection users backup.tar.gz        # 只恢复 users 集合
  $0 --dry-run backup.tar.gz                 # 预览恢复操作

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
            -d|--db)
                DB_NAME="$2"
                shift 2
                ;;
            -u|--uri)
                MONGODB_URI="$2"
                shift 2
                ;;
            --drop)
                DROP_DATABASE=true
                shift
                ;;
            --collection)
                COLLECTION_NAME="$2"
                shift 2
                ;;
            --exclude)
                EXCLUDE_COLLECTION="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --gzip)
                IS_GZIP=true
                shift
                ;;
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;
            -*)
                error "未知选项: $1"
                ;;
            *)
                if [ -z "$BACKUP_SOURCE" ]; then
                    BACKUP_SOURCE="$1"
                else
                    error "只能指定一个备份源"
                fi
                shift
                ;;
        esac
    done
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    if ! command -v mongorestore &> /dev/null; then
        missing_deps+=("mongorestore")
    fi
    
    if ! command -v mongosh &> /dev/null && ! command -v mongo &> /dev/null; then
        missing_deps+=("mongosh 或 mongo")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "缺少依赖: ${missing_deps[*]}. 请安装 MongoDB 数据库工具。"
    fi
}

# 验证备份源
validate_backup_source() {
    if [ -z "$BACKUP_SOURCE" ]; then
        error "请指定备份文件或目录"
    fi
    
    # 如果是相对路径，尝试在备份目录中查找
    if [[ ! "$BACKUP_SOURCE" == /* ]] && [ -d "$BACKUP_DIR" ]; then
        local potential_path="$BACKUP_DIR/$BACKUP_SOURCE"
        if [ -f "$potential_path" ] || [ -d "$potential_path" ]; then
            BACKUP_SOURCE="$potential_path"
        fi
    fi
    
    if [ ! -f "$BACKUP_SOURCE" ] && [ ! -d "$BACKUP_SOURCE" ]; then
        error "备份源不存在: $BACKUP_SOURCE"
    fi
    
    log "备份源验证成功: $BACKUP_SOURCE"
}

# 列出可用的备份
list_available_backups() {
    info "可用的备份文件:"
    echo
    
    if [ -d "$BACKUP_DIR" ]; then
        # 列出压缩文件
        local tar_files=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f 2>/dev/null | sort -r)
        if [ -n "$tar_files" ]; then
            echo "压缩备份文件:"
            while IFS= read -r file; do
                local size=$(du -sh "$file" | cut -f1)
                local date=$(date -r "$file" '+%Y-%m-%d %H:%M:%S')
                printf "  %-40s %8s  %s\n" "$(basename "$file")" "$size" "$date"
            done <<< "$tar_files"
            echo
        fi
        
        # 列出目录
        local backup_dirs=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r)
        if [ -n "$backup_dirs" ]; then
            echo "目录备份:"
            while IFS= read -r dir; do
                local size=$(du -sh "$dir" | cut -f1)
                local date=$(date -r "$dir" '+%Y-%m-%d %H:%M:%S')
                printf "  %-40s %8s  %s\n" "$(basename "$dir")" "$size" "$date"
            done <<< "$backup_dirs"
        fi
    else
        warn "备份目录不存在: $BACKUP_DIR"
    fi
}

# 提取备份文件
extract_backup() {
    local source="$1"
    
    if [ -f "$source" ]; then
        # 检查文件类型
        local file_type=$(file "$source")
        
        if [[ $file_type == *"gzip compressed"* ]] || [[ $source == *.tar.gz ]]; then
            log "提取压缩备份文件: $source"
            mkdir -p "$TEMP_DIR"
            tar -xzf "$source" -C "$TEMP_DIR"
            
            # 查找备份目录
            BACKUP_PATH=$(find "$TEMP_DIR" -type d -name "$DB_NAME" | head -1)
            if [ -z "$BACKUP_PATH" ]; then
                # 如果找不到同名目录，使用第一个包含 .bson 文件的目录
                BACKUP_PATH=$(find "$TEMP_DIR" -name "*.bson" -type f | head -1 | xargs dirname)
                if [ -z "$BACKUP_PATH" ]; then
                    error "在备份文件中找不到有效的备份数据"
                fi
            fi
        else
            error "不支持的文件格式: $source"
        fi
    elif [ -d "$source" ]; then
        log "使用目录备份: $source"
        if [ -d "$source/$DB_NAME" ]; then
            BACKUP_PATH="$source/$DB_NAME"
        else
            BACKUP_PATH="$source"
        fi
    else
        error "无效的备份源: $source"
    fi
    
    log "备份数据路径: $BACKUP_PATH"
}

# 检查 MongoDB 连接
check_mongodb_connection() {
    local mongo_cmd="mongosh"
    if ! command -v mongosh &> /dev/null; then
        mongo_cmd="mongo"
    fi
    
    local test_cmd="$mongo_cmd --quiet --eval 'db.adminCommand(\"ping\")'"
    if [ -n "$MONGODB_URI" ]; then
        test_cmd="$mongo_cmd --quiet '$MONGODB_URI' --eval 'db.adminCommand(\"ping\")'"
    fi
    
    if eval "$test_cmd" &>/dev/null; then
        log "MongoDB 连接测试成功"
    else
        error "无法连接到 MongoDB"
    fi
}

# 构建 mongorestore 命令
build_mongorestore_cmd() {
    local cmd="mongorestore"
    
    # MongoDB 连接字符串
    if [ -n "$MONGODB_URI" ]; then
        cmd="$cmd --uri='$MONGODB_URI'"
    fi
    
    # 目标数据库
    if [ -n "$DB_NAME" ]; then
        cmd="$cmd --db='$DB_NAME'"
    fi
    
    # 删除现有数据库
    if [ "$DROP_DATABASE" = true ]; then
        cmd="$cmd --drop"
    fi
    
    # 指定集合
    if [ -n "$COLLECTION_NAME" ]; then
        cmd="$cmd --collection='$COLLECTION_NAME'"
    fi
    
    # 排除集合
    if [ -n "$EXCLUDE_COLLECTION" ]; then
        cmd="$cmd --excludeCollection='$EXCLUDE_COLLECTION'"
    fi
    
    # 处理 gzip 压缩
    if [ "$IS_GZIP" = true ]; then
        cmd="$cmd --gzip"
    fi
    
    # 详细输出
    cmd="$cmd --verbose"
    
    # 备份路径
    cmd="$cmd '$BACKUP_PATH'"
    
    echo "$cmd"
}

# 显示恢复预览
show_restore_preview() {
    info "恢复操作预览:"
    echo "  备份源: $BACKUP_SOURCE"
    echo "  备份路径: $BACKUP_PATH"
    echo "  目标数据库: $DB_NAME"
    echo "  删除现有数据: ${DROP_DATABASE:-false}"
    echo "  指定集合: ${COLLECTION_NAME:-全部}"
    echo "  排除集合: ${EXCLUDE_COLLECTION:-无}"
    echo "  MongoDB URI: ${MONGODB_URI:-默认连接}"
    echo
    
    # 显示备份内容
    if [ -d "$BACKUP_PATH" ]; then
        info "备份内容:"
        find "$BACKUP_PATH" -name "*.bson" -type f | while IFS= read -r file; do
            local collection=$(basename "$file" .bson)
            local size=$(du -sh "$file" | cut -f1)
            echo "  集合: $collection (大小: $size)"
        done
        echo
    fi
}

# 确认恢复操作
confirm_restore() {
    if [ "$AUTO_CONFIRM" != true ]; then
        echo -n "确认执行恢复操作? (y/N): "
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            log "操作已取消"
            exit 0
        fi
    fi
}

# 执行恢复
perform_restore() {
    local restore_cmd
    restore_cmd=$(build_mongorestore_cmd)
    
    log "开始恢复 MongoDB 数据库: $DB_NAME"
    log "恢复命令: $restore_cmd"
    
    if [ "$DRY_RUN" = true ]; then
        log "预览模式: 不执行实际恢复操作"
        return 0
    fi
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行恢复
    eval "$restore_cmd"
    local exit_code=$?
    
    # 计算耗时
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $exit_code -eq 0 ]; then
        log "恢复完成，耗时: ${duration}s"
    else
        error "恢复失败，退出码: $exit_code"
    fi
}

# 验证恢复结果
verify_restore() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi
    
    log "验证恢复结果..."
    
    local mongo_cmd="mongosh"
    if ! command -v mongosh &> /dev/null; then
        mongo_cmd="mongo"
    fi
    
    local verify_script="
use $DB_NAME
print('数据库: ' + db.getName())
print('集合数量: ' + db.runCommand('listCollections').cursor.firstBatch.length)

db.runCommand('listCollections').cursor.firstBatch.forEach(function(collection) {
    var count = db.getCollection(collection.name).countDocuments();
    print('集合 ' + collection.name + ': ' + count + ' 文档');
});
"
    
    if [ -n "$MONGODB_URI" ]; then
        echo "$verify_script" | eval "$mongo_cmd --quiet '$MONGODB_URI'"
    else
        echo "$verify_script" | eval "$mongo_cmd --quiet"
    fi
}

# 生成恢复报告
generate_report() {
    local report_file="$BACKUP_DIR/restore_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
MongoDB 恢复报告
===============

恢复时间: $(date)
备份源: $BACKUP_SOURCE
目标数据库: $DB_NAME
MongoDB URI: ${MONGODB_URI:-默认连接}

恢复参数:
- 删除现有数据: ${DROP_DATABASE:-false}
- 指定集合: ${COLLECTION_NAME:-全部}
- 排除集合: ${EXCLUDE_COLLECTION:-无}
- 预览模式: ${DRY_RUN:-false}

恢复状态: $([ "$DRY_RUN" = true ] && echo "预览完成" || echo "恢复成功")
EOF
    
    log "恢复报告生成: $report_file"
}

# 主函数
main() {
    info "=== NaoTodo MongoDB 恢复脚本 ==="
    
    # 解析参数
    parse_args "$@"
    
    # 如果没有指定备份源，显示可用备份
    if [ -z "$BACKUP_SOURCE" ]; then
        list_available_backups
        echo
        error "请指定要恢复的备份文件或目录"
    fi
    
    # 检查依赖
    check_dependencies
    
    # 验证备份源
    validate_backup_source
    
    # 提取备份文件
    extract_backup "$BACKUP_SOURCE"
    
    # 检查 MongoDB 连接
    check_mongodb_connection
    
    # 显示恢复预览
    show_restore_preview
    
    # 确认操作
    confirm_restore
    
    # 执行恢复
    perform_restore
    
    # 验证结果
    verify_restore
    
    # 生成报告
    generate_report
    
    log "恢复任务完成"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
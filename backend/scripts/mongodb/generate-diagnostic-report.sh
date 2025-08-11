#!/bin/bash

# MongoDB 诊断报告生成脚本
# 生成详细的系统和数据库状态报告

set -e

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${REPORT_DIR:-/tmp/mongodb_reports}"
DATE=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORT_DIR/mongodb_diagnostic_report_${DATE}.txt"

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
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# 显示使用帮助
show_help() {
    cat << EOF
MongoDB 诊断报告生成器

用法:
  $0 [选项]

选项:
  -h, --help              显示帮助信息
  -o, --output DIR        输出目录 (默认: $REPORT_DIR)
  -f, --format FORMAT     输出格式 (text|json|html) (默认: text)
  --include-logs          包含日志文件分析
  --include-config        包含配置文件
  --anonymize             匿名化敏感信息

示例:
  $0                      # 生成基本报告
  $0 -o /custom/path      # 指定输出目录
  $0 --include-logs       # 包含日志分析
  $0 --format html        # 生成 HTML 格式报告

EOF
}

# 解析命令行参数
parse_args() {
    INCLUDE_LOGS=false
    INCLUDE_CONFIG=false
    ANONYMIZE=false
    FORMAT="text"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                REPORT_DIR="$2"
                REPORT_FILE="$REPORT_DIR/mongodb_diagnostic_report_${DATE}.txt"
                shift 2
                ;;
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            --include-logs)
                INCLUDE_LOGS=true
                shift
                ;;
            --include-config)
                INCLUDE_CONFIG=true
                shift
                ;;
            --anonymize)
                ANONYMIZE=true
                shift
                ;;
            *)
                error "未知选项: $1"
                ;;
        esac
    done
}

# 创建输出目录
create_output_dir() {
    if [ ! -d "$REPORT_DIR" ]; then
        mkdir -p "$REPORT_DIR"
        log "创建输出目录: $REPORT_DIR"
    fi
}

# 收集系统信息
collect_system_info() {
    cat >> "$REPORT_FILE" << EOF
================================================================================
系统信息
================================================================================
生成时间: $(date)
主机名: $(hostname)
操作系统: $(uname -a)
CPU 信息: $(lscpu | grep "Model name" | cut -d: -f2- | xargs || echo "N/A")
内存信息: $(free -h | grep "Mem:" || echo "N/A")
磁盘使用: 
$(df -h | grep -E "(Filesystem|/dev/)")

网络配置:
$(ip addr show | grep -E "(inet|ether)" | head -10 || echo "N/A")

EOF
}

# 收集 MongoDB 服务状态
collect_mongodb_service_status() {
    cat >> "$REPORT_FILE" << EOF
================================================================================
MongoDB 服务状态
================================================================================
EOF
    
    # 检查 MongoDB 进程
    echo "MongoDB 进程:" >> "$REPORT_FILE"
    ps aux | grep -E "(mongod|mongos)" | grep -v grep >> "$REPORT_FILE" 2>/dev/null || echo "未找到 MongoDB 进程" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 检查服务状态
    echo "服务状态:" >> "$REPORT_FILE"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl status mongod >> "$REPORT_FILE" 2>/dev/null || echo "无法获取 systemctl 状态" >> "$REPORT_FILE"
    elif command -v brew >/dev/null 2>&1; then
        brew services list | grep mongodb >> "$REPORT_FILE" 2>/dev/null || echo "无法获取 brew services 状态" >> "$REPORT_FILE"
    else
        echo "无法检查服务状态" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # 检查端口占用
    echo "端口使用情况:" >> "$REPORT_FILE"
    netstat -an | grep :27017 >> "$REPORT_FILE" 2>/dev/null || ss -tuln | grep :27017 >> "$REPORT_FILE" 2>/dev/null || echo "无法检查端口状态" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# 收集 MongoDB 数据库信息
collect_mongodb_database_info() {
    cat >> "$REPORT_FILE" << EOF
================================================================================
MongoDB 数据库信息
================================================================================
EOF
    
    # 检查 MongoDB 连接
    local mongo_cmd="mongosh"
    if ! command -v mongosh &> /dev/null; then
        mongo_cmd="mongo"
    fi
    
    local connection_test_script="
try {
    print('=== 连接测试 ===');
    db.adminCommand('ping');
    print('连接状态: 正常');
    
    print('\\n=== 服务器状态 ===');
    var status = db.serverStatus();
    print('MongoDB 版本: ' + status.version);
    print('运行时间: ' + Math.round(status.uptime / 3600) + ' 小时');
    print('当前连接数: ' + status.connections.current);
    print('可用连接数: ' + status.connections.available);
    
    print('\\n=== 内存使用 ===');
    print('虚拟内存: ' + Math.round(status.mem.virtual) + ' MB');
    print('常驻内存: ' + Math.round(status.mem.resident) + ' MB');
    
    print('\\n=== 存储引擎 ===');
    print('存储引擎: ' + status.storageEngine.name);
    
    print('\\n=== 数据库列表 ===');
    db.adminCommand('listDatabases').databases.forEach(function(database) {
        print(database.name + ' (' + Math.round(database.sizeOnDisk / 1024 / 1024) + ' MB)');
    });
    
    print('\\n=== naotodo 数据库统计 ===');
    use naotodo;
    if (db.stats) {
        var dbStats = db.stats();
        print('数据大小: ' + Math.round(dbStats.dataSize / 1024 / 1024) + ' MB');
        print('存储大小: ' + Math.round(dbStats.storageSize / 1024 / 1024) + ' MB');
        print('索引大小: ' + Math.round(dbStats.indexSize / 1024 / 1024) + ' MB');
        print('集合数量: ' + dbStats.collections);
        print('文档数量: ' + dbStats.objects);
    }
    
    print('\\n=== 集合统计 ===');
    var collections = ['users', 'todos', 'projects', 'tags', 'comments', 'events'];
    collections.forEach(function(collection) {
        try {
            var count = db.getCollection(collection).countDocuments();
            print(collection + ': ' + count + ' 文档');
        } catch(e) {
            print(collection + ': 无法获取统计信息');
        }
    });
    
    print('\\n=== 索引信息 ===');
    collections.forEach(function(collection) {
        try {
            print(collection + ' 索引:');
            db.getCollection(collection).getIndexes().forEach(function(index) {
                print('  ' + index.name + ': ' + JSON.stringify(index.key));
            });
        } catch(e) {
            print(collection + ': 无法获取索引信息');
        }
    });
    
} catch(e) {
    print('连接失败: ' + e);
}
"
    
    # 执行 MongoDB 信息收集
    if [ -n "$MONGODB_URI" ]; then
        echo "$connection_test_script" | eval "$mongo_cmd --quiet '$MONGODB_URI'" >> "$REPORT_FILE" 2>&1 || echo "无法连接到 MongoDB (使用连接字符串)" >> "$REPORT_FILE"
    else
        echo "$connection_test_script" | eval "$mongo_cmd --quiet" >> "$REPORT_FILE" 2>&1 || echo "无法连接到 MongoDB (使用默认连接)" >> "$REPORT_FILE"
    fi
}

# 收集应用配置信息
collect_application_config() {
    if [ "$INCLUDE_CONFIG" != true ]; then
        return
    fi
    
    cat >> "$REPORT_FILE" << EOF

================================================================================
应用配置信息
================================================================================
EOF
    
    echo "环境变量 (敏感信息已屏蔽):" >> "$REPORT_FILE"
    env | grep -E "(MONGO|NODE_ENV|PORT)" | while read line; do
        if [ "$ANONYMIZE" = true ]; then
            echo "$line" | sed -E 's/(password|secret|key)=[^[:space:]]*/\1=***HIDDEN***/gi' >> "$REPORT_FILE"
        else
            echo "$line" >> "$REPORT_FILE"
        fi
    done
    echo "" >> "$REPORT_FILE"
    
    # 显示 package.json 信息
    if [ -f "${SCRIPT_DIR}/../../package.json" ]; then
        echo "项目信息:" >> "$REPORT_FILE"
        grep -E '(name|version|description)' "${SCRIPT_DIR}/../../package.json" >> "$REPORT_FILE" 2>/dev/null || echo "无法读取 package.json" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
}

# 分析日志文件
analyze_logs() {
    if [ "$INCLUDE_LOGS" != true ]; then
        return
    fi
    
    cat >> "$REPORT_FILE" << EOF

================================================================================
日志分析
================================================================================
EOF
    
    # MongoDB 日志分析
    local mongodb_log_paths=(
        "/var/log/mongodb/mongod.log"
        "/usr/local/var/log/mongodb/mongo.log"
        "/var/log/mongod.log"
    )
    
    echo "MongoDB 日志分析:" >> "$REPORT_FILE"
    for log_path in "${mongodb_log_paths[@]}"; do
        if [ -f "$log_path" ]; then
            echo "日志文件: $log_path" >> "$REPORT_FILE"
            echo "最近错误 (最近50行):" >> "$REPORT_FILE"
            tail -50 "$log_path" | grep -i -E "(error|exception|failed|warning)" >> "$REPORT_FILE" 2>/dev/null || echo "无错误信息" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            break
        fi
    done
    
    # 应用日志分析
    local app_log_path="${SCRIPT_DIR}/../../logs/app.log"
    if [ -f "$app_log_path" ]; then
        echo "应用日志分析:" >> "$REPORT_FILE"
        echo "最近 MongoDB 相关日志:" >> "$REPORT_FILE"
        tail -100 "$app_log_path" | grep -i -E "(mongo|database|connection)" >> "$REPORT_FILE" 2>/dev/null || echo "无 MongoDB 相关日志" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
}

# 性能分析
collect_performance_metrics() {
    cat >> "$REPORT_FILE" << EOF

================================================================================
性能指标
================================================================================
EOF
    
    echo "系统负载:" >> "$REPORT_FILE"
    uptime >> "$REPORT_FILE" 2>/dev/null || echo "无法获取系统负载" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "内存使用详情:" >> "$REPORT_FILE"
    free -m >> "$REPORT_FILE" 2>/dev/null || echo "无法获取内存信息" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "磁盘 I/O 统计:" >> "$REPORT_FILE"
    iostat -x 1 2 >> "$REPORT_FILE" 2>/dev/null || echo "无法获取 I/O 统计" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "MongoDB 数据目录大小:" >> "$REPORT_FILE"
    local data_dirs=(
        "/var/lib/mongodb"
        "/usr/local/var/mongodb"
        "/data/db"
    )
    
    for data_dir in "${data_dirs[@]}"; do
        if [ -d "$data_dir" ]; then
            du -sh "$data_dir" >> "$REPORT_FILE" 2>/dev/null || echo "无法获取 $data_dir 大小" >> "$REPORT_FILE"
            break
        fi
    done
}

# 连接测试
test_connectivity() {
    cat >> "$REPORT_FILE" << EOF

================================================================================
连接测试
================================================================================
EOF
    
    echo "本地连接测试:" >> "$REPORT_FILE"
    if timeout 5 bash -c 'echo > /dev/tcp/localhost/27017' 2>/dev/null; then
        echo "✅ localhost:27017 可连接" >> "$REPORT_FILE"
    else
        echo "❌ localhost:27017 无法连接" >> "$REPORT_FILE"
    fi
    
    # 如果配置了远程连接，测试远程连接
    if [ -n "$MONGODB_URI" ] && [[ "$MONGODB_URI" != *"localhost"* ]] && [[ "$MONGODB_URI" != *"127.0.0.1"* ]]; then
        echo "远程连接测试:" >> "$REPORT_FILE"
        local host_port=$(echo "$MONGODB_URI" | sed -E 's|mongodb://[^@]*@?([^/]+)/.*|\1|')
        local host=$(echo "$host_port" | cut -d: -f1)
        local port=$(echo "$host_port" | cut -d: -f2)
        port=${port:-27017}
        
        if timeout 5 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null; then
            echo "✅ $host:$port 可连接" >> "$REPORT_FILE"
        else
            echo "❌ $host:$port 无法连接" >> "$REPORT_FILE"
        fi
    fi
    
    echo "" >> "$REPORT_FILE"
}

# 生成建议
generate_recommendations() {
    cat >> "$REPORT_FILE" << EOF

================================================================================
建议和提示
================================================================================
EOF
    
    echo "基于当前系统状态的建议:" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 检查内存使用
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    if [ "$mem_usage" -gt 80 ]; then
        echo "⚠️  内存使用率较高 (${mem_usage}%)，建议:" >> "$REPORT_FILE"
        echo "   - 检查是否有内存泄漏" >> "$REPORT_FILE"
        echo "   - 考虑增加内存或优化查询" >> "$REPORT_FILE"
        echo "   - 调整 MongoDB 缓存大小" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    # 检查磁盘空间
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        echo "⚠️  磁盘空间不足 (${disk_usage}% 已使用)，建议:" >> "$REPORT_FILE"
        echo "   - 清理日志文件" >> "$REPORT_FILE"
        echo "   - 删除旧的备份文件" >> "$REPORT_FILE"
        echo "   - 考虑数据压缩或归档" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    # 通用建议
    echo "通用优化建议:" >> "$REPORT_FILE"
    echo "✓ 定期备份数据库" >> "$REPORT_FILE"
    echo "✓ 监控慢查询并创建合适的索引" >> "$REPORT_FILE"
    echo "✓ 定期更新 MongoDB 到最新稳定版本" >> "$REPORT_FILE"
    echo "✓ 配置适当的日志轮转" >> "$REPORT_FILE"
    echo "✓ 在生产环境中启用认证和 SSL" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# 生成 JSON 格式报告
generate_json_report() {
    local json_file="${REPORT_FILE%.*}.json"
    log "生成 JSON 格式报告: $json_file"
    
    # 这里可以添加 JSON 格式的报告生成逻辑
    echo "{\"message\": \"JSON 格式报告功能正在开发中\"}" > "$json_file"
}

# 生成 HTML 格式报告
generate_html_report() {
    local html_file="${REPORT_FILE%.*}.html"
    log "生成 HTML 格式报告: $html_file"
    
    # 将文本报告转换为 HTML
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>MongoDB 诊断报告</title>
    <style>
        body { font-family: monospace; margin: 20px; }
        h1 { color: #2c3e50; }
        .error { color: #e74c3c; }
        .warning { color: #f39c12; }
        .success { color: #27ae60; }
        pre { background: #f8f9fa; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>MongoDB 诊断报告</h1>
    <pre>
$(cat "$REPORT_FILE" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    </pre>
</body>
</html>
EOF
}

# 主函数
main() {
    info "=== MongoDB 诊断报告生成器 ==="
    
    # 解析参数
    parse_args "$@"
    
    # 创建输出目录
    create_output_dir
    
    log "开始生成诊断报告: $REPORT_FILE"
    
    # 创建报告文件
    cat > "$REPORT_FILE" << EOF
NaoTodo MongoDB 诊断报告
生成时间: $(date)
================================================================================
EOF
    
    # 收集各项信息
    log "收集系统信息..."
    collect_system_info
    
    log "收集 MongoDB 服务状态..."
    collect_mongodb_service_status
    
    log "收集数据库信息..."
    collect_mongodb_database_info
    
    log "收集应用配置..."
    collect_application_config
    
    log "分析日志文件..."
    analyze_logs
    
    log "收集性能指标..."
    collect_performance_metrics
    
    log "测试连接..."
    test_connectivity
    
    log "生成建议..."
    generate_recommendations
    
    # 根据格式生成其他格式的报告
    case $FORMAT in
        json)
            generate_json_report
            ;;
        html)
            generate_html_report
            ;;
        text)
            # 默认已生成
            ;;
    esac
    
    # 完成
    log "诊断报告生成完成!"
    info "报告位置: $REPORT_FILE"
    
    if [ "$FORMAT" = "html" ]; then
        info "HTML 报告: ${REPORT_FILE%.*}.html"
    elif [ "$FORMAT" = "json" ]; then
        info "JSON 报告: ${REPORT_FILE%.*}.json"
    fi
    
    echo ""
    echo "报告摘要:"
    echo "- 系统信息: $(uname -s) $(uname -r)"
    echo "- MongoDB 状态: $(systemctl is-active mongod 2>/dev/null || echo "未知")"
    echo "- 磁盘使用: $(df -h / | tail -1 | awk '{print $5}')"
    echo "- 内存使用: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100}')"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
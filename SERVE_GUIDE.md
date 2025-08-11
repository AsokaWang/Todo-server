# 📦 serve 包使用指南

## 🎯 概述

serve 包是一个零配置的静态文件服务器，非常适合用于开发环境、构建产物预览和快速原型开发。

## ✅ 安装完成

```bash
# serve 包已安装
✅ serve ^14.2.4

# 相关依赖
✅ express ^4.21.1
✅ cors ^2.8.5  
✅ dotenv ^16.6.1
```

## 🚀 可用脚本

### serve 包命令

```bash
# 基础命令
pnpm run serve                 # 直接使用 serve CLI

# 静态文件服务
pnpm run serve:static         # 服务 ./public 目录 (端口 3001, 启用 CORS)
pnpm run serve:dist          # 服务构建产物 (端口 3003, SPA 模式)
pnpm run serve:docs          # 服务文档文件 (端口 3004, SPA 模式)

# 高级配置
pnpm run serve:config        # 使用 serve.json 配置文件
pnpm run serve:https         # HTTPS 服务器 (需要 SSL 证书)
```

### 内置工具

```bash
# 使用示例和信息
pnpm run serve:example       # 查看 serve 包使用示例
pnpm run serve:example --info # 显示详细信息

# 简单静态服务器 (Node.js 内置)
pnpm run serve:simple        # 启动内置静态服务器 (端口 3001)
pnpm run serve:simple:8080   # 启动内置静态服务器 (端口 8080)
```

## 📁 文件结构

```
nao-todo-server/
├── public/                  # 静态文件目录
│   └── index.html          # 主页文件 (已创建)
├── serve.json              # serve 配置文件 (已创建)
└── scripts/
    ├── serve-example.js     # serve 使用示例 (已创建)
    └── simple-static-server.js # 内置静态服务器 (已创建)
```

## ⚙️ 配置说明

### serve.json 配置文件

```json
{
  "public": "./public",
  "directoryListing": false,
  "rewrites": [
    {
      "source": "/api/**", 
      "destination": "http://localhost:3002/api/$1"
    }
  ],
  "headers": [
    {
      "source": "**/*",
      "headers": [
        { "key": "X-Served-By", "value": "NaoTodo-Serve" },
        { "key": "Cache-Control", "value": "public, max-age=3600" }
      ]
    }
  ]
}
```

### 环境变量支持

```bash
# .env 文件中的相关配置
PORT=3002                    # 主服务器端口
CORS_ORIGIN=http://localhost:5173
SSL_CERT_PATH=./certs/fullchain.pem
SSL_KEY_PATH=./certs/privkey.pem
```

## 🔧 serve 包主要功能

### ✨ 核心特性

- ✅ **零配置**: 开箱即用，无需复杂设置
- ✅ **SPA 支持**: `--single` 参数支持单页应用
- ✅ **CORS 支持**: `--cors` 启用跨域请求  
- ✅ **GZIP 压缩**: 自动压缩静态文件
- ✅ **HTTPS 支持**: SSL/TLS 证书支持
- ✅ **自定义端口**: `-p` 参数指定端口
- ✅ **路径重写**: 支持 API 代理和路径映射
- ✅ **缓存控制**: ETag 和 Last-Modified 支持

### 🎯 使用场景

1. **开发环境**
   - 快速启动静态文件服务
   - 前端开发时的资源服务
   - API Mock 和代理

2. **构建预览**
   - 预览构建后的应用
   - 生产环境模拟
   - 性能测试

3. **文档服务**
   - 项目文档本地预览
   - API 文档服务
   - 开发指南展示

4. **快速原型**
   - 快速搭建演示环境
   - 静态网站托管
   - 文件分享服务

## 📝 使用示例

### 1. 基础使用

```bash
# 服务当前目录
serve

# 服务指定目录和端口
serve ./public -p 3001

# 启用 CORS
serve ./public -p 3001 --cors

# SPA 模式 (所有路由返回 index.html)
serve ./dist -p 3000 --single
```

### 2. HTTPS 服务

```bash
# 使用 SSL 证书
serve ./public -p 3001 \
  --ssl-cert ./certs/cert.pem \
  --ssl-key ./certs/key.pem
```

### 3. 配置文件使用

```bash
# 使用 serve.json 配置
serve -c serve.json

# 使用自定义配置文件
serve -c custom-serve.json
```

## 🔍 故障排除

### 常见问题

#### 1. 端口被占用
```bash
Error: listen EADDRINUSE :::3001

# 解决方案:
# 1. 更换端口
serve ./public -p 3002

# 2. 查找并终止占用进程
lsof -i :3001
kill -9 <PID>
```

#### 2. CORS 错误
```bash
# 问题: 跨域请求被阻止
# 解决方案: 启用 CORS
serve ./public -p 3001 --cors
```

#### 3. SPA 路由问题
```bash
# 问题: 前端路由返回 404
# 解决方案: 启用 SPA 模式
serve ./dist -p 3000 --single
```

#### 4. 文件权限问题
```bash
# 问题: 无法读取文件
# 解决方案: 检查文件权限
chmod -R 755 ./public
```

## 🎮 快速测试

### 1. 测试静态服务器

```bash
# 启动 serve 静态服务器
pnpm run serve:static

# 访问: http://localhost:3001
# 应该看到 NaoTodo Server 首页
```

### 2. 测试内置服务器

```bash  
# 启动简单静态服务器
pnpm run serve:simple

# 访问: http://localhost:3001
# 功能相同但使用 Node.js 内置模块
```

### 3. 查看使用示例

```bash
# 查看 serve 包信息
pnpm run serve:example --info

# 查看帮助信息
pnpm run serve:example --help
```

## 🌟 最佳实践

### 1. 开发环境
- 使用 `--cors` 启用跨域支持
- 设置合适的端口避免冲突
- 利用配置文件统一管理

### 2. 生产预览
- 使用 `--single` 支持 SPA 路由
- 启用 HTTPS 模拟生产环境
- 配置适当的缓存策略

### 3. 性能优化
- 启用压缩 (默认开启)
- 设置合理的缓存头部
- 使用 CDN 分发静态资源

### 4. 安全考虑
- 不要暴露敏感目录
- 使用 HTTPS 传输敏感数据
- 限制目录遍历功能

## 📚 相关资源

- [serve 包官方文档](https://github.com/vercel/serve)
- [Express.js 静态文件服务](https://expressjs.com/en/starter/static-files.html)
- [Node.js HTTP 模块](https://nodejs.org/api/http.html)
- [HTTPS 配置指南](https://nodejs.org/api/https.html)

---

🎉 **serve 包已成功集成到 NaoTodo 项目中，可以开始使用各种静态文件服务功能！**
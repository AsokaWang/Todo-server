# NaoTodo

## 🚀 项目简介

NaoTodo 是一个仿滴答清单的待办任务管理平台，旨在为用户提供简洁高效的任务管理体验。该平台基于 Vue3、Vite、NueUI、Pinia、Axios
以及 TypeScript 构建，确保了现代前端开发的性能和可维护性。通过 NaoTodo，用户可以轻松创建、编辑、删除任务，并设置任务的优先级和截止日期，从而有效管理日常待办事项。

<!-- ## 🌐 站点地址

- [NaoTodo](https://nathan33.site/) -->

## 👨‍💻 开发者信息

- **当前维护者**：Asoka Wang
- **GitHub 仓库**：[Todo GitHub 仓库](https://github.com/AsokaWang/Todo.git)
- **原作者**：Nathan Lee（感谢原项目的创建和贡献）

## 🛠️ 技术栈

### 前端技术栈
- **前端框架**：Vue 3
- **构建工具**：Vite
- **UI 框架**：NueUI
- **状态管理**：Pinia
- **HTTP 请求**：Axios
- **编程语言**：TypeScript

### 后端技术栈
- **运行环境**：Node.js
- **Web 框架**：Express.js
- **数据库**：MongoDB
- **ODM**：Mongoose
- **身份认证**：JWT
- **包管理器**：pnpm

## 📈 项目进度

### 🎯 当前版本：v1.0.0 (开发中)

### ✅ 已完成功能

#### 后端服务 (90% 完成)
- ✅ **用户认证系统**：JWT 登录/注册/登出
- ✅ **任务管理 API**：CRUD 操作、批量操作、软删除
- ✅ **项目管理**：项目创建、更新、删除
- ✅ **标签系统**：标签创建、管理、分类
- ✅ **评论系统**：任务评论的增删改查
- ✅ **事件日志**：操作历史记录和审计
- ✅ **文件上传**：用户头像上传功能
- ✅ **AI 集成**：OpenAI API 集成基础框架
- ✅ **数据库设计**：MongoDB 模型和索引优化
- ✅ **中间件**：认证、错误处理、日志记录

#### 前端应用 (85% 完成)

**Web 应用**
- ✅ **用户界面**：登录/注册页面
- ✅ **任务管理**：创建、编辑、删除任务
- ✅ **多视图支持**：表格视图、看板视图
- ✅ **项目管理**：项目创建和管理界面
- ✅ **标签系统**：标签管理和筛选
- ✅ **用户设置**：个人资料、密码修改
- ✅ **响应式设计**：适配各种屏幕尺寸
- ✅ **状态管理**：Pinia 状态管理架构

**移动端应用 (uni-app)**
- ✅ **基础框架**：uni-app 项目结构
- ✅ **核心页面**：任务、日历、专注、设置页面
- ✅ **组件库**：自定义 UI 组件
- 🔄 **功能对接**：与后端 API 集成 (进行中)

**桌面应用 (Electron)**
- ✅ **基础框架**：Electron 应用结构
- 🔄 **功能开发**：核心功能实现 (进行中)

### 🔄 正在开发

1. **AI 功能增强** (30% 完成)
   - 🔄 智能任务建议
   - 🔄 任务优先级智能排序
   - 📝 自然语言任务创建

2. **高级功能** (20% 完成)
   - 📝 任务模板系统
   - 📝 任务依赖关系
   - 📝 时间统计和报表
   - 📝 团队协作功能

3. **性能优化** (40% 完成)
   - 🔄 前端代码分割和懒加载
   - 🔄 数据库查询优化
   - 📝 缓存策略实施
   - 📝 CDN 集成

### 📋 待开发功能

#### 近期计划 (v1.1.0)
- 📝 **离线支持**：PWA 和本地存储
- 📝 **通知系统**：任务提醒和推送通知
- 📝 **数据导入导出**：支持多种格式
- 📝 **主题系统**：深色模式和自定义主题
- 📝 **快捷键支持**：键盘快捷操作

#### 中期计划 (v1.2.0)
- 📝 **团队功能**：多用户协作、权限管理
- 📝 **日历集成**：与第三方日历同步
- 📝 **API 开放**：第三方集成支持
- 📝 **移动应用发布**：iOS/Android 应用商店上架

#### 长期计划 (v2.0.0)
- 📝 **企业版功能**：高级分析、管理面板
- 📝 **插件系统**：第三方扩展支持
- 📝 **国际化**：多语言支持
- 📝 **性能监控**：全链路监控系统

### 📊 开发统计

| 模块 | 完成度 | 核心功能 | 测试覆盖率 |
|------|--------|----------|------------|
| 后端 API | 90% | ✅ 完成 | 70% |
| Web 前端 | 85% | ✅ 完成 | 60% |
| 移动端 | 60% | 🔄 开发中 | 30% |
| 桌面端 | 40% | 🔄 开发中 | 20% |
| AI 集成 | 30% | 📝 计划中 | 10% |
| 文档 | 80% | ✅ 完成 | - |

### 🐛 已知问题
- 移动端部分 API 集成未完成
- 桌面应用性能需要优化
- AI 功能还在早期开发阶段
- 部分边缘情况的错误处理需要完善

### 🤝 贡献机会
欢迎开发者参与以下领域的开发：
- 🎨 UI/UX 改进和设计
- 🔧 性能优化和代码重构
- 🧪 测试用例编写
- 📖 文档完善和翻译
- 🤖 AI 功能开发
- 📱 移动端功能完善

## 🎨 功能特性

1. **任务管理**：支持任务的创建、编辑、删除及查看详情。
2. **优先级设置**：可为任务设置高、中、低、紧急四种优先级。
3. **进度设置**：可为任务设置待办、正在进行、已完成三种进度。
4. **截止日期**：为任务添加截止日期，提醒用户按时完成。
5. **任务收藏**：标记重要任务，快速访问。
6. **评论任务**：为任务添加评论，记录任务进度、状态以及过程中的一些想法。
7. **清单和标签**：可以创建清单和标签，以分类和标记任务。
8. **多视图**：提供多视图，包括表格和看板视图。
9. **软删除**：安全的删除机制，支持回收站功能。
10. **事件记录**：完整的操作历史追踪。
11. **多端支持**：Web、移动端、桌面端统一体验。
12. **用户友好**：尽量简化操作步骤，减少用户学习成本。

## 📁 项目结构

```
Todo/
├── nao-todo-server/          # 后端服务
│   ├── apps/
│   │   ├── web/              # Express Web 服务器
│   │   └── field-reshape/    # 数据重构工具
│   └── packages/             # 共享包
│       ├── apis/             # API 业务逻辑
│       ├── models/           # 数据模型
│       ├── hooks/            # 通用钩子
│       ├── pipelines/        # 数据处理管道
│       └── utils/            # 工具函数
└── nao-todo/                 # 前端应用
    ├── apps/
    │   ├── web/              # Web 应用
    │   ├── mobile/           # 移动端应用 (uni-app)
    │   └── desktop/          # 桌面应用 (Electron)
    └── packages/             # 前端共享包
```

## ⚙️ 环境要求

- Node.js >= 18.0.0
- pnpm >= 8.0.0
- MongoDB >= 4.4

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone https://github.com/AsokaWang/Todo.git
cd Todo
```

### 2. 安装依赖
```bash
# 安装后端依赖
cd nao-todo-server
pnpm install

# 安装前端依赖
cd ../nao-todo
pnpm install
```

### 3. 配置环境变量
```bash
# 复制环境变量模板
cd nao-todo-server
cp .env.example .env

# 编辑 .env 文件，配置 MongoDB 连接等信息
# 最少需要配置：
# MONGODB_URI=mongodb://localhost:27017/naotodo
# JWT_SECRET=your-secure-secret-key
```

### 4. 启动 MongoDB
确保 MongoDB 服务在本地运行（默认端口 27017）

### 5. 安装依赖并启动后端服务
```bash
cd nao-todo-server
pnpm install
pnpm run websrv dev
```
后端服务将在 http://localhost:3002 启动

### 6. 启动前端应用
```bash
cd nao-todo
pnpm run webapp dev
```
Web 应用将在 http://localhost:5173 启动

## ⚙️ 配置说明

### 环境变量配置
项目使用环境变量进行配置管理，确保敏感信息安全。

#### 必需配置
```bash
# MongoDB 数据库连接
MONGODB_URI=mongodb://localhost:27017/naotodo

# JWT 密钥（必须至少32个字符）
JWT_SECRET=your-super-secure-jwt-secret-at-least-32-characters-long
```

#### 可选配置
```bash
# 服务器配置
NODE_ENV=development
PORT=3002

# CORS 配置
CORS_ORIGIN=http://localhost:5173

# 文件上传配置
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=5242880

# OpenAI API（AI 功能）
OPENAI_API_KEY=your-openai-api-key
OPENAI_MODEL=gpt-3.5-turbo

# 生产环境 SSL 配置
SSL_CERT_PATH=./certs/fullchain.pem
SSL_KEY_PATH=./certs/privkey.pem
```

### 安全最佳实践
1. **绝不提交** `.env` 文件到 Git
2. **使用强密码** 设置 JWT_SECRET
3. **生产环境** 启用 HTTPS
4. **限制 CORS** 域名范围
5. **定期轮换** API 密钥

### MongoDB 连接配置
支持多种连接方式：

```bash
# 本地开发
MONGODB_URI=mongodb://localhost:27017/naotodo

# 带认证
MONGODB_URI=mongodb://username:password@host:port/naotodo

# 生产环境（推荐）
MONGODB_URI=mongodb://username:password@host:port/naotodo?authSource=admin&ssl=true&retryWrites=true&w=majority
```

## 🔧 开发命令

### 后端开发
```bash
cd nao-todo-server
pnpm run websrv dev      # 启动开发服务器
pnpm run lint           # 代码检查
pnpm run format         # 代码格式化

# 静态文件服务 (serve 包)
pnpm run serve:static   # 启动静态文件服务器 (端口 3001)
pnpm run serve:dist     # 服务构建产物 (端口 3003, SPA 模式)
pnpm run serve:docs     # 服务文档文件 (端口 3004, SPA 模式)
pnpm run serve:config   # 使用 serve.json 配置文件
pnpm run serve:https    # HTTPS 静态服务器 (需要证书)

# 简单静态服务器 (内置)
pnpm run serve:simple   # 启动简单静态服务器 (端口 3001)
pnpm run serve:example  # 查看 serve 包使用示例
```

### 前端开发
```bash
cd nao-todo
pnpm run webapp dev     # 启动 Web 应用
pnpm run webapp build   # 构建 Web 应用
pnpm run mobile dev     # 启动移动端开发
pnpm run desktop dev    # 启动桌面应用
```

## 📝 贡献指南

欢迎对 NaoTodo 做出贡献！在提交代码之前，请确保：

1. 提交 Pull Request 前，先确保所有的测试通过。
2. 详细描述你的更改内容和目的。

## 📜 许可证

NaoTodo 项目遵循 [MIT 许可证](https://github.com/NathanLee/NaoTodo/blob/main/LICENSE)。你可以自由地使用、复制、修改和分发该项目，但请保留原作者和版权信息。

## 💡 鸣谢

感谢所有参与 NaoTodo 项目开发、测试、反馈的用户和贡献者！

**特别感谢：**
- **Nathan Lee** - 原项目的创建者和主要贡献者，为这个优秀的待办任务管理平台奠定了坚实的基础
- **Vue、Vite、Pinia、Axios 以及 TypeScript 开发团队** - 为前端开发提供了强大的工具和框架
- **所有社区贡献者** - 为项目的持续改进和发展做出的贡献

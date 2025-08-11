# CLAUDE.md

这个文件为在此代码库中工作的Claude Code (claude.ai/code) 提供指导。

## 常用命令

### 服务端开发 (nao-todo-server)
```bash
cd nao-todo-server
pnpm install
pnpm run websrv dev      # 启动Web服务器
pnpm run lint           # 代码检查
pnpm run format         # 代码格式化
```

### 前端开发 (nao-todo)
```bash
cd nao-todo
pnpm install
pnpm run webapp dev     # 启动Web应用
pnpm run mobile dev     # 启动移动应用开发环境
pnpm run desktop dev    # 启动桌面应用
```

## 项目架构

### 整体结构
这是一个仿滴答清单的待办任务管理平台，使用分离式架构：

- `nao-todo-server/`: Node.js/Express/MongoDB后端服务
- `nao-todo/`: Vue3前端应用（支持Web、移动端和桌面端）

### 后端架构 (nao-todo-server)
基于Express.js + MongoDB + Mongoose的单体架构：

- `apps/web/`: Express Web服务器主应用
- `packages/`: 共享包结构
  - `apis/`: API业务逻辑层，按功能模块划分
  - `models/`: Mongoose数据模型定义
  - `hooks/`: JWT认证等通用钩子
  - `pipelines/`: 数据处理管道
  - `utils/`: 通用工具函数

服务器监听3002端口，生产环境使用HTTPS。

### 前端架构 (nao-todo)
基于Vue3 + Vite + Pinia的现代前端架构：

**技术栈：**
- Vue 3 + TypeScript
- Pinia状态管理
- Vue Router路由
- NueUI组件库
- Axios HTTP客户端

**多端支持：**
- `apps/web/`: Web应用（Vite）
- `apps/mobile/`: uni-app移动应用
- `apps/desktop/`: Electron桌面应用

**核心功能模块：**
- 任务管理：创建、编辑、删除、设置优先级和截止日期
- 项目和标签管理：任务分类和标记
- 多视图：表格视图和看板视图
- 用户认证和个人资料管理
- 评论和事件记录系统
- AI集成功能

### 状态管理结构
前端使用Pinia进行状态管理，按功能模块划分：
- `use-todo-store`: 任务状态管理
- `use-project-store`: 项目管理
- `use-tag-store`: 标签管理  
- `use-user-store`: 用户状态
- `use-comment-store`: 评论系统
- `use-event-store`: 事件记录

### 数据库设计
MongoDB数据模型：
- `User`: 用户账户和个人资料
- `Todo`: 任务实体（支持优先级、状态、截止日期）
- `Project`: 项目清单
- `Tag`: 标签系统
- `Comment`: 任务评论
- `Event`: 操作事件记录

## 开发环境要求

- Node.js（项目使用pnpm作为包管理器）
- MongoDB数据库
- TypeScript支持
- 生产环境需要SSL证书用于HTTPS
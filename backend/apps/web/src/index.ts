import dotenv from 'dotenv';
import express from 'express';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import https from 'https';
import { fileURLToPath } from 'url';
import { connectToMongoDB, isMongoDBHealthy, getMongoDBStats } from '@nao-todo-server/utils';
import aiRoutes from './routes/ai';
import authRoutes from './routes/auth';
import projectRoutes from './routes/project';
import todoRoutes from './routes/todo';
import eventRoutes from './routes/event';
import tagRoutes from './routes/tag';
import userRoutes from './routes/user';
import commentRoutes from './routes/comment';

// 加载环境变量
dotenv.config({ path: path.resolve(process.cwd(), '../../.env') });

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const uploadDir = path.join(process.env.UPLOAD_PATH || path.join(__dirname, 'avatars'));

const app = express();

// CORS 配置
const corsOptions = {
  origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  credentials: process.env.CORS_CREDENTIALS === 'true' || true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 静态文件服务
app.use('/statics/avatars', express.static(uploadDir, { 
  maxAge: 31536000,
  etag: true,
  lastModified: true
}));

// 健康检查端点
app.get(process.env.HEALTH_CHECK_PATH || '/health', (_, res) => {
  const health = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    mongodb: {
      connected: isMongoDBHealthy(),
      stats: getMongoDBStats()
    },
    memory: process.memoryUsage()
  };

  const statusCode = health.mongodb.connected ? 200 : 503;
  res.status(statusCode).json(health);
});

// API 路由
app.use('/api', aiRoutes);
app.use('/api', authRoutes);
app.use('/api', projectRoutes);
app.use('/api', todoRoutes);
app.use('/api', eventRoutes);
app.use('/api', tagRoutes);
app.use('/api', userRoutes);
app.use('/api', commentRoutes);

// 根路径
app.use('/', (_, res) => {
  res.json({ 
    message: 'NaoTodo Server API',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString()
  });
});

// 服务器启动函数
async function startServer() {
  try {
    // 连接数据库
    console.log('🚀 正在启动 NaoTodo Server...');
    await connectToMongoDB();

    const port = parseInt(process.env.PORT || '3002', 10);
    const isProduction = process.env.NODE_ENV === 'production';

    if (isProduction && process.env.SSL_CERT_PATH && process.env.SSL_KEY_PATH) {
      // 生产环境 HTTPS 服务器
      const sslOptions = {
        key: fs.readFileSync(process.env.SSL_KEY_PATH),
        cert: fs.readFileSync(process.env.SSL_CERT_PATH)
      };

      https.createServer(sslOptions, app).listen(port, '0.0.0.0', () => {
        console.log(`✅ NaoTodo Server (HTTPS) 运行在端口 ${port}`);
        console.log(`🌍 环境: ${process.env.NODE_ENV}`);
        console.log(`🔒 SSL: 已启用`);
      });
    } else {
      // 开发环境或无 SSL 的生产环境
      app.listen(port, '0.0.0.0', () => {
        console.log(`✅ NaoTodo Server (HTTP) 运行在端口 ${port}`);
        console.log(`🌍 环境: ${process.env.NODE_ENV}`);
        if (isProduction) {
          console.log('⚠️ 生产环境未配置 SSL 证书');
        }
      });
    }

  } catch (error) {
    console.error('❌ 服务器启动失败:', error);
    process.exit(1);
  }
}

// 错误处理
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ 未处理的 Promise 拒绝:', reason);
  console.error('Promise:', promise);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('❌ 未捕获的异常:', error);
  process.exit(1);
});

// 启动服务器
startServer();

import mongoose from 'mongoose';
import type { ConnectOptions } from 'mongoose';

/**
 * MongoDB 连接配置接口
 */
interface MongoDBConfig {
  uri: string;
  dbName: string;
  options: ConnectOptions;
}

/**
 * 环境变量接口
 */
interface EnvConfig {
  NODE_ENV: string;
  MONGODB_URI: string;
  MONGODB_DB_NAME: string;
  MONGODB_MAX_POOL_SIZE: string;
  MONGODB_MIN_POOL_SIZE: string;
  MONGODB_MAX_IDLE_TIME_MS: string;
  MONGODB_SERVER_SELECTION_TIMEOUT_MS: string;
  MONGODB_SOCKET_TIMEOUT_MS: string;
  DEV_SHOW_MONGOOSE_DEBUG: string;
}

/**
 * 获取环境变量配置
 */
const getEnvConfig = (): EnvConfig => {
  // 在构建时，环境变量可能不存在，使用默认值
  if (typeof process === 'undefined' || !process.env) {
    return {
      NODE_ENV: 'development',
      MONGODB_URI: 'mongodb://111.170.131.53:27017/naotodo',
      MONGODB_DB_NAME: 'naotodo',
      MONGODB_MAX_POOL_SIZE: '100',
      MONGODB_MIN_POOL_SIZE: '5',
      MONGODB_MAX_IDLE_TIME_MS: '30000',
      MONGODB_SERVER_SELECTION_TIMEOUT_MS: '5000',
      MONGODB_SOCKET_TIMEOUT_MS: '45000',
      DEV_SHOW_MONGOOSE_DEBUG: 'false'
    };
  }

  return {
    NODE_ENV: process.env.NODE_ENV || 'development',
    MONGODB_URI: process.env.MONGODB_URI || 'mongodb://localhost:27017/naotodo',
    MONGODB_DB_NAME: process.env.MONGODB_DB_NAME || 'naotodo',
    MONGODB_MAX_POOL_SIZE: process.env.MONGODB_MAX_POOL_SIZE || '100',
    MONGODB_MIN_POOL_SIZE: process.env.MONGODB_MIN_POOL_SIZE || '5',
    MONGODB_MAX_IDLE_TIME_MS: process.env.MONGODB_MAX_IDLE_TIME_MS || '30000',
    MONGODB_SERVER_SELECTION_TIMEOUT_MS: process.env.MONGODB_SERVER_SELECTION_TIMEOUT_MS || '5000',
    MONGODB_SOCKET_TIMEOUT_MS: process.env.MONGODB_SOCKET_TIMEOUT_MS || '45000',
    DEV_SHOW_MONGOOSE_DEBUG: process.env.DEV_SHOW_MONGOOSE_DEBUG || 'false'
  };
};

/**
 * 创建 MongoDB 连接配置
 */
export const createMongoDBConfig = (): MongoDBConfig => {
  const env = getEnvConfig();
  const isProduction = env.NODE_ENV === 'production';

  // 基础连接选项
  const baseOptions: ConnectOptions = {
    // 连接池配置
    maxPoolSize: parseInt(env.MONGODB_MAX_POOL_SIZE, 10),
    minPoolSize: parseInt(env.MONGODB_MIN_POOL_SIZE, 10),
    maxIdleTimeMS: parseInt(env.MONGODB_MAX_IDLE_TIME_MS, 10),
    
    // 服务器选择和超时配置
    serverSelectionTimeoutMS: parseInt(env.MONGODB_SERVER_SELECTION_TIMEOUT_MS, 10),
    socketTimeoutMS: parseInt(env.MONGODB_SOCKET_TIMEOUT_MS, 10),
    
    // 连接管理
    bufferCommands: false, // 禁用 mongoose 缓冲
    
    // 写入关注
    retryWrites: true,
    w: 'majority',
    
    // 读取偏好
    readPreference: 'primaryPreferred',
    
    // 心跳检测
    heartbeatFrequencyMS: 10000,
    
    // 应用程序名称（用于 MongoDB 日志和监控）
    appName: `naotodo-server-${env.NODE_ENV}`,
  };

  // 生产环境额外配置
  if (isProduction) {
    Object.assign(baseOptions, {
      // 启用压缩
      compressors: ['snappy', 'zlib'],
      
      // SSL 配置（如果 URI 中包含 ssl=true）
      ssl: env.MONGODB_URI.includes('ssl=true'),
      
      // 连接超时配置
      connectTimeoutMS: 10000,
      
      // 重试配置
      retryReads: true,
      
      // 监控
      monitorCommands: true,
    });
  }

  return {
    uri: env.MONGODB_URI,
    dbName: env.MONGODB_DB_NAME,
    options: baseOptions
  };
};

/**
 * 连接状态管理器
 */
class MongoDBConnection {
  private static instance: MongoDBConnection;
  private isConnected = false;
  private connectionPromise: Promise<typeof mongoose> | null = null;

  private constructor() {}

  static getInstance(): MongoDBConnection {
    if (!MongoDBConnection.instance) {
      MongoDBConnection.instance = new MongoDBConnection();
    }
    return MongoDBConnection.instance;
  }

  /**
   * 连接到 MongoDB
   */
  async connect(): Promise<typeof mongoose> {
    if (this.isConnected) {
      return mongoose;
    }

    if (this.connectionPromise) {
      return this.connectionPromise;
    }

    const config = createMongoDBConfig();
    const env = getEnvConfig();

    this.connectionPromise = this.performConnection(config, env);
    return this.connectionPromise;
  }

  private async performConnection(config: MongoDBConfig, env: EnvConfig): Promise<typeof mongoose> {
    try {
      console.log(`🔌 正在连接 MongoDB: ${this.maskSensitiveInfo(config.uri)}`);
      
      // 设置调试模式
      if (env.NODE_ENV === 'development' && env.DEV_SHOW_MONGOOSE_DEBUG === 'true') {
        mongoose.set('debug', true);
      }

      // 连接数据库
      const connection = await mongoose.connect(config.uri, config.options);
      
      this.isConnected = true;
      console.log(`✅ MongoDB 连接成功: ${config.dbName}`);
      
      // 设置连接事件监听器
      this.setupEventListeners();
      
      return connection;
    } catch (error) {
      console.error('❌ MongoDB 连接失败:', error);
      this.connectionPromise = null;
      throw error;
    }
  }

  /**
   * 设置连接事件监听器
   */
  private setupEventListeners(): void {
    mongoose.connection.on('error', (error) => {
      console.error('🚨 MongoDB 连接错误:', error);
    });

    mongoose.connection.on('disconnected', () => {
      console.warn('⚠️ MongoDB 连接断开');
      this.isConnected = false;
    });

    mongoose.connection.on('reconnected', () => {
      console.log('🔄 MongoDB 重新连接成功');
      this.isConnected = true;
    });

    mongoose.connection.on('close', () => {
      console.log('🔐 MongoDB 连接已关闭');
      this.isConnected = false;
    });

    // 进程退出时优雅关闭连接
    process.on('SIGINT', this.gracefulShutdown.bind(this));
    process.on('SIGTERM', this.gracefulShutdown.bind(this));
  }

  /**
   * 优雅关闭连接
   */
  private async gracefulShutdown(): Promise<void> {
    try {
      await mongoose.connection.close();
      console.log('🛑 MongoDB 连接已优雅关闭');
      process.exit(0);
    } catch (error) {
      console.error('❌ 关闭 MongoDB 连接时出错:', error);
      process.exit(1);
    }
  }

  /**
   * 遮罩敏感信息
   */
  private maskSensitiveInfo(uri: string): string {
    return uri.replace(/\/\/([^:]+):([^@]+)@/, '//****:****@');
  }

  /**
   * 检查连接状态
   */
  isConnectionHealthy(): boolean {
    return this.isConnected && mongoose.connection.readyState === 1;
  }

  /**
   * 获取连接统计信息
   */
  getConnectionStats() {
    if (!this.isConnected) {
      return null;
    }

    return {
      readyState: mongoose.connection.readyState,
      name: mongoose.connection.name,
      host: mongoose.connection.host,
      port: mongoose.connection.port,
      collections: Object.keys(mongoose.connection.collections),
    };
  }
}

/**
 * 导出单例实例
 */
export const mongoDBConnection = MongoDBConnection.getInstance();

/**
 * 连接数据库的便捷函数
 */
export const connectToMongoDB = async (): Promise<typeof mongoose> => {
  return mongoDBConnection.connect();
};

/**
 * 检查连接健康状态
 */
export const isMongoDBHealthy = (): boolean => {
  return mongoDBConnection.isConnectionHealthy();
};

/**
 * 获取连接统计信息
 */
export const getMongoDBStats = () => {
  return mongoDBConnection.getConnectionStats();
};

// 向后兼容的默认导出
export default connectToMongoDB;
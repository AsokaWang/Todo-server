import { connectToMongoDB } from './mongodb-config';

/**
 * @deprecated 请使用新的 MongoDB 配置模块
 * 此函数保留用于向后兼容，建议迁移到新的连接方式
 */
const connectAndRun = async (fn: () => Promise<void>) => {
    console.warn('⚠️ connect-and-run 已废弃，请使用新的 MongoDB 配置模块');
    await connectToMongoDB();
    await fn();
};

export default connectAndRun;

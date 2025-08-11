#!/usr/bin/env node

/**
 * NaoTodo Server - serve 包使用示例
 * 演示如何在 Node.js 中程序化使用 serve 包
 */

// import { serve } from 'serve';  // serve 是 CLI 工具，不支持程序化 API
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startStaticServer() {
  console.log('🚀 启动 NaoTodo 静态文件服务器...');

  const config = {
    // 静态文件目录
    public: path.join(__dirname, '../public'),
    
    // 服务器配置
    port: 3001,
    host: '127.0.0.1',
    
    // 功能选项
    cors: true,           // 启用 CORS
    compression: true,    // 启用压缩
    etag: true,          // 启用 ETag
    single: false,       // 不是 SPA 模式
    
    // 安全选项
    dotfiles: 'ignore',  // 忽略点文件
    
    // 自定义头部
    headers: {
      'X-Powered-By': 'NaoTodo Server',
      'X-Served-By': 'serve',
      'Cache-Control': 'public, max-age=3600'
    }
  };

  try {
    // 启动服务器 (注意: serve 包可能不支持程序化 API)
    // 这里展示概念，实际使用建议用 CLI
    console.log(`📁 静态文件目录: ${config.public}`);
    console.log(`🌐 服务器地址: http://${config.host}:${config.port}`);
    console.log('✅ 服务器配置:');
    console.log(`   - CORS: ${config.cors ? '启用' : '禁用'}`);
    console.log(`   - 压缩: ${config.compression ? '启用' : '禁用'}`);
    console.log(`   - ETag: ${config.etag ? '启用' : '禁用'}`);
    
    // 实际项目中应该使用 CLI 命令
    console.log('\n📝 推荐使用 CLI 命令:');
    console.log('   pnpm run serve:static');
    console.log('   # 或');
    console.log(`   npx serve ${config.public} -p ${config.port} --cors`);
    
  } catch (error) {
    console.error('❌ 启动服务器失败:', error.message);
    process.exit(1);
  }
}

// 命令行参数处理
const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) {
  console.log(`
📖 NaoTodo Server - serve 包使用示例

用法:
  node serve-example.js [选项]

选项:
  -h, --help     显示帮助信息
  --info         显示配置信息

示例:
  node serve-example.js
  node serve-example.js --info

更多信息:
  https://github.com/vercel/serve
  `);
  process.exit(0);
}

if (args.includes('--info')) {
  console.log(`
📊 serve 包信息:

功能特点:
  ✅ 零配置静态文件服务
  ✅ 支持 SPA (--single)
  ✅ 内置 CORS 支持
  ✅ 自动 GZIP 压缩
  ✅ HTTPS 支持
  ✅ 自定义端口
  ✅ 路径重写
  ✅ 缓存控制

常用命令:
  serve                    # 服务当前目录，端口 3000
  serve folder -p 8080     # 服务指定目录和端口
  serve --single           # SPA 模式
  serve --cors             # 启用 CORS
  serve --ssl-cert cert.pem --ssl-key key.pem  # HTTPS

配置文件:
  serve.json - 项目根目录的配置文件
  支持重写规则、头部设置、目录列表等
  `);
  process.exit(0);
}

// 启动示例
if (import.meta.url === `file://${process.argv[1]}`) {
  startStaticServer();
}
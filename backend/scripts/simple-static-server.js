#!/usr/bin/env node

/**
 * 简单的静态文件服务器
 * 使用 Node.js 内置模块，作为 serve 包的补充
 */

import http from 'http';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class SimpleStaticServer {
  constructor(options = {}) {
    this.port = options.port || 3001;
    this.host = options.host || '127.0.0.1';
    this.publicDir = options.publicDir || path.join(__dirname, '../public');
    this.cors = options.cors || true;
  }

  async start() {
    const server = http.createServer(async (req, res) => {
      try {
        await this.handleRequest(req, res);
      } catch (error) {
        console.error('Request error:', error);
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Internal Server Error');
      }
    });

    server.listen(this.port, this.host, () => {
      console.log(`🚀 简单静态服务器运行在 http://${this.host}:${this.port}`);
      console.log(`📁 静态文件目录: ${this.publicDir}`);
      console.log(`🔧 CORS: ${this.cors ? '启用' : '禁用'}`);
      console.log('⚡ 使用 Ctrl+C 停止服务器');
    });

    // 优雅关闭
    process.on('SIGINT', () => {
      console.log('\n🛑 收到停止信号，正在关闭服务器...');
      server.close(() => {
        console.log('✅ 服务器已关闭');
        process.exit(0);
      });
    });
  }

  async handleRequest(req, res) {
    const url = new URL(req.url, `http://${req.headers.host}`);
    let filePath = path.join(this.publicDir, url.pathname);

    // 设置 CORS 头部
    if (this.cors) {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    }

    // 处理 OPTIONS 请求
    if (req.method === 'OPTIONS') {
      res.writeHead(204);
      res.end();
      return;
    }

    // 只处理 GET 请求
    if (req.method !== 'GET') {
      res.writeHead(405, { 'Content-Type': 'text/plain' });
      res.end('Method Not Allowed');
      return;
    }

    try {
      const stat = await fs.stat(filePath);
      
      if (stat.isDirectory()) {
        filePath = path.join(filePath, 'index.html');
      }

      const content = await fs.readFile(filePath);
      const ext = path.extname(filePath).toLowerCase();
      const mimeType = this.getMimeType(ext);

      // 设置缓存头部
      res.setHeader('Cache-Control', 'public, max-age=3600');
      res.setHeader('Last-Modified', stat.mtime.toUTCString());
      res.setHeader('Content-Type', mimeType);
      res.setHeader('X-Powered-By', 'NaoTodo Simple Static Server');

      res.writeHead(200);
      res.end(content);

      console.log(`✅ ${req.method} ${req.url} - ${mimeType}`);

    } catch (error) {
      if (error.code === 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end(`
          <!DOCTYPE html>
          <html>
          <head>
            <title>404 - File Not Found</title>
            <style>
              body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
              .error { color: #e74c3c; }
            </style>
          </head>
          <body>
            <h1 class="error">404 - File Not Found</h1>
            <p>The requested file <code>${req.url}</code> was not found.</p>
            <p><a href="/">返回首页</a></p>
          </body>
          </html>
        `);
        console.log(`❌ ${req.method} ${req.url} - 404 Not Found`);
      } else {
        throw error;
      }
    }
  }

  getMimeType(ext) {
    const mimeTypes = {
      '.html': 'text/html',
      '.htm': 'text/html',
      '.js': 'application/javascript',
      '.css': 'text/css',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml',
      '.ico': 'image/x-icon',
      '.txt': 'text/plain',
      '.xml': 'application/xml',
      '.pdf': 'application/pdf'
    };

    return mimeTypes[ext] || 'application/octet-stream';
  }
}

// CLI 运行
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
📖 简单静态文件服务器

用法:
  node simple-static-server.js [选项]

选项:
  -p, --port <port>    指定端口 (默认: 3001)
  --no-cors           禁用 CORS
  -h, --help          显示帮助信息

示例:
  node simple-static-server.js
  node simple-static-server.js -p 8080
  node simple-static-server.js --no-cors
    `);
    process.exit(0);
  }

  const options = {};
  
  // 解析端口
  const portIndex = args.findIndex(arg => arg === '-p' || arg === '--port');
  if (portIndex !== -1 && args[portIndex + 1]) {
    options.port = parseInt(args[portIndex + 1], 10);
  }

  // 解析 CORS
  if (args.includes('--no-cors')) {
    options.cors = false;
  }

  const server = new SimpleStaticServer(options);
  server.start().catch(console.error);
}
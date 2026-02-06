#!/bin/bash

# Markdown 渲染器安装脚本
# 用于 OpenNanos Platform UI

set -e

echo "🚀 开始安装 Markdown 渲染器依赖..."

# 修复 npm 权限问题（如果需要）
if [ ! -w "$HOME/.npm" ]; then
  echo "⚠️  检测到 npm 缓存权限问题，尝试修复..."
  echo "请输入密码以修复 npm 权限："
  sudo chown -R $(id -u):$(id -g) "$HOME/.npm"
fi

# 切换到 UI 目录
cd "$(dirname "$0")"

echo "📦 安装 React Markdown 和相关依赖..."

# 安装核心依赖
npm install \
  react-markdown@^9.0.1 \
  remark-gfm@^4.0.0 \
  rehype-raw@^7.0.0 \
  rehype-sanitize@^6.0.0 \
  react-syntax-highlighter@^15.6.1 \
  github-markdown-css@^5.8.1

# 安装类型定义
npm install --save-dev \
  @types/react-syntax-highlighter@^15.5.13

echo "✅ 依赖安装完成！"
echo ""
echo "📋 已安装的包："
echo "  - react-markdown: Markdown 渲染核心"
echo "  - remark-gfm: GitHub Flavored Markdown 支持"
echo "  - rehype-raw: HTML 原始内容支持"
echo "  - rehype-sanitize: HTML 安全清理"
echo "  - react-syntax-highlighter: 代码高亮"
echo "  - github-markdown-css: GitHub 官方样式"
echo ""
echo "🎨 Markdown 渲染器已配置完成！"
echo ""
echo "▶️  运行以下命令启动开发服务器："
echo "   npm run dev"
echo ""
echo "📚 功能特性："
echo "  ✓ GitHub Flavored Markdown 支持"
echo "  ✓ 代码语法高亮（100+ 语言）"
echo "  ✓ 表格、任务列表、删除线"
echo "  ✓ 自动深色/浅色主题切换"
echo "  ✓ 安全的 HTML 清理"
echo "  ✓ 响应式设计"
echo "  ✓ 优雅的动画效果"

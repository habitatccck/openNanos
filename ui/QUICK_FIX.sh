#!/bin/bash

# 快速修复脚本 - 一次性复制粘贴执行

set -e

echo "🔧 修复 npm 权限并安装依赖..."
echo ""
echo "请复制以下命令到终端执行："
echo ""
echo "====================================="
echo ""

cat << 'COMMANDS'
# 一键执行所有命令
sudo chown -R $(id -u):$(id -g) "$HOME/.npm" && \
cd /Users/mac/Desktop/openNanos/opennanos-platform/ui && \
npm install react-markdown remark-gfm rehype-raw rehype-sanitize react-syntax-highlighter github-markdown-css @types/react-syntax-highlighter && \
echo "" && \
echo "✅ 安装完成！开发服务器会自动刷新" && \
echo ""
COMMANDS

echo ""
echo "====================================="
echo ""
echo "或者分步执行："
echo ""
echo "1️⃣  sudo chown -R \$(id -u):\$(id -g) \"\$HOME/.npm\""
echo ""
echo "2️⃣  cd /Users/mac/Desktop/openNanos/opennanos-platform/ui"
echo ""
echo "3️⃣  npm install react-markdown remark-gfm rehype-raw rehype-sanitize react-syntax-highlighter github-markdown-css @types/react-syntax-highlighter"
echo ""

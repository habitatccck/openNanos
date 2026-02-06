#!/bin/bash

# OpenAria 项目初始化脚本
# 自动完成所有准备工作

set -e

echo "🎵 OpenAria 项目初始化"
echo "======================================"
echo ""

PROJECT_ROOT="/Users/mac/Desktop/openaria"
cd "$PROJECT_ROOT"

# 检查目录结构
echo "✓ 检查项目结构..."
if [ ! -d "Platform/macOS" ]; then
    echo "❌ 错误: Platform/macOS 目录不存在"
    exit 1
fi

# 创建 UI 项目
echo ""
echo "📦 步骤 1: 创建 React UI 项目"
echo "======================================"

if [ ! -f "UI/package.json" ]; then
    echo "正在创建 Vite + React 项目..."
    cd UI
    npm create vite@latest . -- --template react-ts --force

    echo "正在安装依赖..."
    npm install

    echo "正在安装额外的包..."
    npm install zustand

    echo "✓ UI 项目创建完成"
else
    echo "✓ UI 项目已存在，跳过创建"
fi

cd "$PROJECT_ROOT"

# 列出 Swift 文件
echo ""
echo "📝 步骤 2: Xcode 项目设置"
echo "======================================"
echo ""
echo "请按照以下步骤操作:"
echo ""
echo "1. 打开 Xcode:"
echo "   open -a Xcode"
echo ""
echo "2. 创建新项目:"
echo "   - File → New → Project"
echo "   - 选择 macOS → App"
echo "   - Product Name: OpenAria"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - 保存到: $PROJECT_ROOT/Platform/macOS/"
echo ""
echo "3. 导入以下 Swift 文件:"
ls -1 Platform/macOS/*.swift | while read file; do
    echo "   - $(basename "$file")"
done
echo ""
echo "4. 配置权限:"
echo "   - Signing & Capabilities → Add Capability → App Sandbox"
echo "   - 勾选 Outgoing Connections (Client)"
echo ""
echo "5. 配置 Info.plist:"
echo "   - 添加 NSAppTransportSecurity 允许本地网络"
echo ""
echo "详细步骤请查看: NEXT_STEPS.md"
echo ""

# 询问是否继续
echo "完成 Xcode 设置后，按回车继续..."
read

# 检查是否创建了 Xcode 项目
if [ ! -f "Platform/macOS/OpenAria.xcodeproj/project.pbxproj" ]; then
    echo "⚠️  未检测到 Xcode 项目文件"
    echo "请先完成 Xcode 项目创建，然后重新运行此脚本"
    exit 1
fi

echo "✓ Xcode 项目已创建"

# 启动开发服务器
echo ""
echo "🚀 步骤 3: 启动开发服务器"
echo "======================================"
echo ""
echo "即将启动 UI 开发服务器..."
echo "按 Ctrl+C 可以停止服务器"
echo ""

cd UI
npm run dev &
UI_PID=$!

echo ""
echo "✓ UI 开发服务器已启动: http://localhost:5173"
echo ""
echo "======================================"
echo "🎉 初始化完成！"
echo "======================================"
echo ""
echo "下一步:"
echo "1. 在 Xcode 中运行项目 (⌘R)"
echo "2. 应该看到 OpenAria 启动并加载 UI"
echo "3. 查看 NEXT_STEPS.md 了解如何测试完整流程"
echo ""
echo "开发服务器正在后台运行 (PID: $UI_PID)"
echo "要停止服务器，运行: kill $UI_PID"
echo ""

# 等待用户按键
echo "按任意键退出..."
read

echo "脚本完成"

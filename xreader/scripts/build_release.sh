#!/bin/bash

# XReader 发布构建脚本

set -e

echo "🚀 开始构建 XReader 发布版本..."

# 检查Flutter环境
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装或未添加到 PATH"
    exit 1
fi

# 检查当前目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 清理之前的构建
echo "🧹 清理之前的构建文件..."
flutter clean

# 获取依赖
echo "📦 获取项目依赖..."
flutter pub get

# 生成代码
echo "⚙️  生成必要代码..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# 运行测试
echo "🧪 运行测试..."
flutter test

# 构建 Android APK
echo "📱 构建 Android APK..."
flutter build apk --release --split-per-abi

# 构建 Android App Bundle (用于 Google Play)
echo "📦 构建 Android App Bundle..."
flutter build appbundle --release

# 如果在 macOS 上，构建 iOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 构建 iOS..."
    flutter build ios --release --no-codesign
fi

# 创建发布目录
RELEASE_DIR="release/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RELEASE_DIR"

# 复制构建产物
echo "📋 复制构建产物..."
cp build/app/outputs/flutter-apk/*.apk "$RELEASE_DIR/"
cp build/app/outputs/bundle/release/app-release.aab "$RELEASE_DIR/"

# 生成版本信息
echo "📝 生成版本信息..."
cat > "$RELEASE_DIR/build_info.txt" << EOF
XReader 构建信息
================

构建时间: $(date)
Flutter 版本: $(flutter --version | head -1)
Dart 版本: $(dart --version)
构建类型: Release

文件说明:
- app-arm64-v8a-release.apk: ARM64 设备 APK
- app-armeabi-v7a-release.apk: ARM32 设备 APK  
- app-x86_64-release.apk: x86_64 设备 APK
- app-release.aab: Google Play App Bundle

安装说明:
1. 在 Android 设备上安装对应架构的 APK
2. 或将 AAB 文件上传到 Google Play Console

注意事项:
- 首次安装需要允许"未知来源"应用安装
- 应用需要存储权限来导入电子书文件
EOF

echo "✅ 构建完成！"
echo "📁 发布文件位于: $RELEASE_DIR"
echo ""
echo "🎉 XReader 发布版本构建成功！"

# 显示文件大小
echo ""
echo "📊 构建产物大小:"
du -h "$RELEASE_DIR"/*

# 可选：自动打开发布目录
if command -v open &> /dev/null; then
    read -p "是否打开发布目录? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$RELEASE_DIR"
    fi
fi
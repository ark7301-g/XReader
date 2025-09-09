# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

XReader 是一个基于 Flutter 的极简电子书阅读器，支持 EPUB 和 PDF 格式。项目设计理念强调极简、沉浸式的阅读体验。

## 常用开发命令

### 基础命令
```bash
# 进入Flutter项目目录
cd xreader

# 获取依赖
flutter pub get

# 生成代码文件
flutter packages pub run build_runner build --delete-conflicting-outputs

# 运行开发版本
flutter run

# 运行发布版本
flutter run --release
```

### 测试命令
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/features/bookshelf/bookshelf_provider_test.dart

# 运行Widget测试
flutter test test/features/bookshelf/widgets/book_card_test.dart

# 生成测试覆盖率
flutter test --coverage
```

### 代码质量检查
```bash
# 运行代码分析
flutter analyze

# 格式化代码
dart format .

# 检查代码风格（通过analysis_options.yaml配置）
flutter analyze
```

### 构建命令
```bash
# 使用构建脚本（推荐）
chmod +x scripts/build_release.sh
./scripts/build_release.sh

# 手动构建Android
flutter build apk --release --split-per-abi
flutter build appbundle --release

# 构建iOS（仅macOS）
flutter build ios --release --no-codesign
```

## 项目架构

### 整体架构模式
- **Clean Architecture**: 分层架构设计，分离关注点
- **Feature-Based**: 按功能模块组织代码结构
- **Riverpod**: 状态管理使用 Riverpod 进行依赖注入和状态管理
- **Isar Database**: 本地数据存储使用 Isar 数据库

### 核心架构层次

```
lib/
├── main.dart                 # 应用入口，初始化数据库服务
├── app.dart                 # 主应用配置，包含主页面导航
├── core/                    # 核心服务层
│   ├── services/           # 核心服务（数据库、文件管理）
│   ├── themes/            # 主题配置（支持明亮/夜间模式）
│   └── utils/             # 工具类（错误处理、性能优化）
├── features/               # 功能模块
│   ├── bookshelf/         # 书架功能（书籍管理）
│   ├── reader/           # 阅读器功能（核心阅读体验）
│   └── settings/         # 设置功能（个性化配置）
├── shared/                # 共享组件
│   ├── widgets/          # 通用UI组件
│   └── models/           # 共享数据模型
└── data/                 # 数据层
    ├── models/           # 数据模型（Book, SimpleBook等）
    ├── repositories/     # 数据仓库抽象
    └── datasources/      # 数据源实现
```

### 状态管理模式
每个功能模块遵循相同的状态管理模式：
- `providers/xxx_provider.dart` - Riverpod状态管理
- `providers/xxx_state.dart` - 状态数据类定义
- `pages/xxx_page.dart` - 页面UI实现
- `widgets/` - 功能相关的UI组件

### 关键服务

#### DatabaseService (core/services/database_service.dart)
- 使用 Isar 数据库管理书籍数据
- 提供书籍增删改查操作
- 管理阅读进度和书签数据

#### FileService (core/services/file_service.dart)  
- 处理电子书文件导入
- 支持 EPUB 和 PDF 格式解析
- 管理文件存储和访问

### 电子书解析服务
- EPUB: 使用 epubx 包解析 (reader/services/epub_reader_service.dart)
- PDF: 使用 syncfusion_flutter_pdfviewer 包 (reader/services/pdf_reader_service.dart)

## 开发约定

### 代码风格
- 使用 `flutter_lints` 进行代码规范检查
- 中文注释和变量名，英文函数名
- 使用 Google Fonts (Noto Sans 和 Source Serif 4)
- 响应式设计使用 ScreenUtil

### 主题设计
- 明亮主题：白色背景，深色文字
- 夜间主题：黑色背景，浅色文字
- 阅读器特殊配色：米白色护眼背景
- 主色调：蓝色 (#4A90E2)

### 命名约定
- 页面：`XxxPage`
- 提供者：`xxxProvider`
- 状态类：`XxxState`
- 服务类：`XxxService`
- Widget：`XxxWidget` 或描述性名称

### 重要实现细节
- 阅读器界面：点击屏幕中央切换工具栏显示/隐藏
- 分页阅读：使用 PageView 实现
- 进度保存：实时保存阅读进度到数据库
- 文件管理：导入的书籍文件存储在应用私有目录

## 测试策略
- 单元测试：Provider和Service逻辑
- Widget测试：UI组件交互
- 集成测试：端到端用户流程

项目目前处于开发阶段，核心架构已搭建完成，主要功能模块（书架、阅读器、设置）的基础结构已就位。
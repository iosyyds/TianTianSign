<div align="center">

<img src="https://aka.doubaocdn.com/s/8Vv3LGCSep" width="140" alt="甜甜签图标">

# 甜甜签 · TianTianSign

**一款免费、开源、甜丝丝的 iOS IPA 重签名工具**

像甜甜圈一样简单，像盖章一样可靠 —— 拖入 IPA，选好证书，一键签名。

[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B-brightgreen)]()
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()
[![Build](https://img.shields.io/badge/build-WIP-red)]()

</div>

---

## 这是什么？

甜甜签（TianTianSign）是一款跑在 **iOS 设备本机**上的 IPA 重签名工具，对标 [全能签]、[轻松签]、Feather、Sideloadly 等同类软件。

你只需要准备好自己的 **开发者证书（.p12）** 和 **描述文件（.mobileprovision）**，把 IPA 文件导入甜甜签，它就会在设备本地完成解包、替换描述文件、修改 entitlements、（可选）注入 dylib、修改 Bundle ID，然后重新打包成一个可以直接安装的新 IPA。

> 🍩 **甜甜的，才是好用的。**

## 功能特性

- 📦 **IPA 重签名** — 导入 .p12 + .mobileprovision，一键对任意 IPA 重签名
- 🪪 **证书管理** — 本地维护多份证书，自动识别证书名称、过期时间、UDID 绑定
- 📝 **描述文件管理** — 自动解析 embedded.mobileprovision，展示 AppID、过期时间、设备列表
- 🧩 **Dylib 插件注入 / 移除** — 拖拽 Tweak 的 .dylib 进 IPA，或移除已注入的动态库
- 🎭 **Bundle ID 修改 & 多开** — 改包名实现同机多开，不改原图标也能跑
- 🖼️ **应用图标 / 显示名替换** — 自定义替换 AppIcon 和 CFBundleDisplayName
- ⚙️ **Entitlements 编辑器** — 可视化开关 get-task-allow、aps-environment、app-groups 等
- 📜 **签名日志** — 每一步操作都有详细日志，出错可直接复制反馈
- 🔒 **本地处理** — 所有签名都在你的设备上完成，证书和 IPA 不上传任何服务器

## 界面预览

> 截图将在首个 TestFlight 内测版放出后补充。

```
┌─────────────────────────────┐
 │  🍩 甜甜签                   │
 │─────────────────────────────│
 │                             │
 │   [ 拖入 IPA 文件 ]          │
 │                             │
 │   证书:  Apple Develop...  ▾│
 │   描述文件:  embedded...   ▾│
 │                             │
 │   ☑ 修改 Bundle ID: com.xx  │
 │   ☑ 注入 dylib (2 个)       │
 │   ☐ 替换图标 / 显示名        │
 │                             │
 │   [   开始签名  🍩   ]      │
 │                             │
 └─────────────────────────────┘
```

## 工作原理

```
  .ipa ──▶ 解压缩 ──▶ 删除旧 _CodeSignature
                          │
                          ▼
              替换 embedded.mobileprovision
                          │
                          ▼
              修改 Info.plist / entitlements
                          │
                          ▼
              (可选) 注入 / 移除 dylib + 修改 LC_LOAD_DYLIB
                          │
                          ▼
              使用 .p12 证书对 Mach-O 重签名
                          │
                          ▼
              重新 zip 打包 ──▶ signed.ipa
```

底层签名核心基于 [zhlynn/zsign](https://github.com/zhlynn/zsign)（纯 C++ 跨平台 codesign 实现）静态编译进 App，无需 macOS、无需 Xcode、无需越狱。

## 目录结构

```
TianTianSign/
├── TianTianSign/                 # iOS App (SwiftUI)
│   ├── TianTianSignApp.swift
│   ├── Models/                   # Certificate / Profile / IPAFile / SigningTask
│   ├── Views/                     # Home / Certificates / Profiles / Library / Sign
│   ├── ViewModels/                # AppState / Store / SigningViewModel
│   ├── Services/                  # SigningEngine / IPAParser / ProfileParser ...
│   └── Resources/
├── SigningCore/                   # C++ 签名核心 (vendored zsign 封装)
├── scripts/
│   └── resign.sh                  # 命令行参考脚本
├── docs/
│   ├── architecture.md             # 架构与模块说明
│   └── usage.md                    # 用户使用手册
└── repo.json                      # AltStore / SideStore 源
```

## 快速开始

### 从源码构建

```bash
git clone https://github.com/iosyyds/TianTianSign.git
cd TianTianSign
# 用 Xcode 打开 TianTianSign.xcodeproj（首次克隆后由 XcodeGen 生成）
xed .
```

依赖：
- Xcode 15+
- iOS 15.0+ 真机（模拟器无法调用钥匙串和真实签名）
- 你的开发者账号（个人免费账号即可签 7 天，付费账号 1 年）

### 作为 AltStore 源安装

在 AltStore / SideStore / Panda 里添加源：

```
https://raw.githubusercontent.com/iosyyds/TianTianSign/main/repo.json
```

## 路线图

- [x] 项目初始化 / UI 原型
- [ ] 证书导入（.p12 + 密码）钥匙串存储
- [ ] 描述文件解析（openssl CMS 解密）
- [ ] IPA 解包 / 重打包
- [ ] 集成 zsign 静态库完成重签名
- [ ] Dylib 注入 +Mach-O load command 修改
- [ ] Bundle ID / 显示名 / 图标替换
- [ ] 签名完成后调起系统分享安装
- [ ] AltStore 源发布

## 免责声明

本项目仅供学习 iOS 代码签名机制、测试自己开发的 App 之用。

- 请使用 **你自己合法拥有** 的开发者证书和描述文件；
- 不要用于重签名、分发盗版或破解他人付费应用；
- 因不当使用造成的证书封禁、设备封禁等后果由使用者自行承担。

## 开源许可

[MIT](./LICENSE) © 甜甜签 Contributors

底层签名引擎 [zsign](https://github.com/zhlynn/zsign) 采用 GPL-3.0，本项目以静态链接方式使用，分发时将遵循其许可。

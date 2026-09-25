# SigningCore

甜甜签底层签名引擎。

本目录通过 git submodule 引入 [zhlynn/zsign](https://github.com/zhlynn/zsign)，再用一层 C 薄壳暴露给 Swift：

```c
// tts_bridge.h
int tsign_resign_app(const char* app_dir,
                     const char* p12_path,
                     const char* p12_password,
                     const char* profile_path);
int tsign_inject_dylib(const char* app_dir, const char* dylib_path);
int tsign_remove_dylib(const char* app_dir, const char* dylib_name);
```

Swift 侧 `SigningEngine.zsign_execute(...)` 直接调上面的函数。

## 编译为 iOS 静态库

```bash
cd SigningCore
git submodule update --init
# 在 Xcode 里把 zsign 源文件加进 target，Arch 选 arm64，Signing 选 automatic
# 产物：libSigningCore.a
```

## 为什么不直接调 codesign

iOS 设备上没有 `/usr/bin/codesign`，也没有公共 API 能给外部 Mach-O 做完整 CMS 签名。zsign 是少数纯 C++ 实现这件事的开源项目，能在 iOS 上直接跑。

## 许可

zsign 本体 GPL-3.0。甜甜签以静态链接方式使用它，因此整个 App 分发时必须开源，且许可证保持 GPL-3.0 兼容。

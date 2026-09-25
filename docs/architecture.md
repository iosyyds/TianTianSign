# 甜甜签 架构说明

## 总体分层

```
┌──────────────────────────────────────────────┐
│                  SwiftUI UI 层               │
│  HomeView / CertList / ProfileList / Lib     │
└──────────────────┬───────────────────────────┘
                   │ ObservableObject
┌──────────────────▼───────────────────────────┐
│              ViewModels / Stores             │
│  AppState · CertificateStore · SigningVM     │
└──────────────────┬───────────────────────────┘
                   │
┌──────────────────▼───────────────────────────┐
│              Services (Swift)                 │
│  IPAParser / ProfileParser / Entitlements    │
└──────────────────┬───────────────────────────┘
                   │  C ABI
┌──────────────────▼───────────────────────────┐
│      SigningCore (C++, 静态库 libzsign.a)     │
│  Mach-O 解析 · CMS 解析 · 重签名 · dylib 注入 │
└──────────────────────────────────────────────┘
```

## 数据流

1. **导入证书**：用户选 .p12 → `CertificateImporter.inspect(p12:password:)` 调 `SecPKCS12Import` 解密，读出 CN / TeamID / 有效期；密码写 Keychain，p12 本体拷到 `Documents/Certificates/`。
2. **导入描述文件**：选 .mobileprovision → `ProfileParser.parse()` 用 OpenSSL `d2i_PKCS7_bio` 解出里面的 XML plist，读 UUID / AppID / ExpirationDate / ProvisionedDevices / Entitlements。
3. **导入 IPA**：选 .ipa → `IPAParser.parse()` 解压到临时目录，读 `Payload/*.app/Info.plist`，扫 Mach-O 头拿架构，缓存 AppIcon。
4. **签名**：`SigningEngine.run(_:)`
   - unzip IPA
   - 删 `_CodeSignature`
   - 替换 `embedded.mobileprovision`
   - 改 `Info.plist` 的 `CFBundleIdentifier` / `CFBundleDisplayName`
   - 对每个要注入的 dylib：拷进 `.app/Frameworks/`，改主二进制的 `LC_LOAD_DYLIB`
   - 调 `zsign_execute(app_dir, p12, pwd, profile)` 对 `PlugIns/`、`Frameworks/`、主二进制逐个重签
   - 重新 zip 成 `.ipa`

## 为什么用 zsign 做底层

iOS 上没有 `codesign` 命令，也没有 `Security.framework` 的公共 API 能给一个外部 Mach-O 重新做 CMS 签名。开源圈里已经把这件事做透的是 [zsign](https://github.com/zhlynn/zsign)（纯 C++，无 macOS 依赖，能在 iOS 本机编译成静态库），所以甜甜签直接 vendoring 它。

## 安全设计

- 证书密码只进 Keychain（kSecClassGenericPassword），不写 UserDefaults、不进日志。
- 所有文件操作都在 App 沙盒内；不申请 `Documents` 外部共享容器以外的权限。
- 不内置任何第三方证书 / 描述文件 / 企业号；用户必须自己导入。

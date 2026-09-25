# 甜甜签 使用手册

## 你需要准备什么

| 文件 | 说明 | 哪里拿 |
|---|---|---|
| `.p12` | 开发者证书（含私钥），导出时设一个密码 | 钥匙串访问 → 导出证书 |
| `.mobileprovision` | 描述文件，要和 p12 是同一个 Team | developer.apple.com → Certificates, IDs & Profiles |
| 要签的 `.ipa` | 你自己有权重签的 IPA | — |

> 个人免费账号：签出来的 App 7 天掉签，且只能绑 3 个 UDID。
> 付费个人账号：1 年有效，最多 100 台 UDID。
> 企业账号（In-House）：不需要绑 UDID，可以无限设备，但滥用会被苹果封。

## 操作步骤

1. 打开「证书」 tab → 右上角 + → 选 .p12 → 输密码。
2. 打开「描述文件」 tab → 右上角 + → 选 .mobileprovision。
3. 回到「签名」 tab → 点「从文件 App 导入 IPA」选 IPA。
4. 选刚导入的证书和描述文件。
5. （可选）填新的 Bundle ID 做应用多开；填新的显示名。
6. 点「开始签名 🍩」，等日志跑完。
7. 完成后点「分享 / 安装签名后的 IPA」，用「分享到「甜甜签」安装」或者存到文件再用其他安装器装。

## 常见问题

**Q: 签完的 App 提示"未受信任的企业级开发者"？**
A: 到 设置 → 通用 → VPN 与设备管理 里点信任。

**Q: 启动就闪退？**
A: 99% 是 entitlements 对不上。确保你选的描述文件 AppID 通配符（`*` 或 `com.xxx.*`）覆盖了原 App 的 Bundle ID；或者在「可选修改」里把 Bundle ID 改成描述文件允许的值。

**Q: 提示 "A valid provisioning profile for this executable was not found"？**
A: 描述文件里没绑你这台设备的 UDID（开发 / Ad Hoc profile 才有这个限制）。换一个企业 In-House profile，或者把自己的 UDID 加到开发者后台再重新生成描述文件。

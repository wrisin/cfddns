以下是适合放在 GitHub 仓库的 README 描述：

---

# CloudFlare DDNS for Koolshare Merlin

[![Platform](https://img.shields.io/badge/platform-Merlin%20(Koolshare)-blue.svg)](https://koolshare.cn)
[![License](https://img.shields.io/badge/license-GPLv3-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0-red.svg)](https://github.com/yourname/cfddns)

一个专为 Koolshare 梅林固件优化的 CloudFlare DDNS 插件，支持 IPv4/IPv6 双栈，具备多源 IP 检测、自动重试、内网 IP 过滤等增强功能。

## ✨ 功能特性

- **智能 IP 获取** - 自动轮询 7+ 个公开 IP 检测服务，任一源可用即成功
- **双栈支持** - 同时支持 IPv4 (A记录) 和 IPv6 (AAAA记录) 更新
- **内网 IP 过滤** - 自动识别并过滤 192.168.x.x、10.x.x.x、172.16-31.x.x 等内网地址
- **失败重试机制** - API 请求失败自动重试 3 次，递增等待时间
- **多接口兼容** - 自动适配 ppp0/ppp1/ppp1.2 等不同 PPPoE 接口
- **详细日志输出** - 记录 IP 来源、错误详情，便于排查问题
- **定时更新** - 支持自定义间隔时间自动检查更新

## 📦 安装要求

- Koolshare 梅林固件（RT-AC86U / RT-AX88U / GT-AC5300 等 hnd/axhnd 平台）
- CloudFlare 账号及域名
- 已在 CloudFlare 后台预先添加 A/AAAA 记录

## 🚀 快速开始

1. 下载离线安装包
2. 在软件中心选择「离线安装」
3. 上传并安装插件
4. 在插件配置页面填写 CloudFlare 信息：
   - Email（账号邮箱）
   - API Key（全局 API Key）
   - Zone ID（域名区域 ID）
   - 域名信息
5. 开启插件并保存

## ⚙️ 配置说明

| 配置项 | 说明 |
|--------|------|
| Email | CloudFlare 账号登录邮箱 |
| API KEY | CloudFlare 全局 API Key（需获取） |
| Zone ID | 域名对应的区域 ID |
| 子域名 | 需要 DDNS 的子域名，根域名填 @ |
| 主域名 | 你的主域名 |
| TTL | 解析生效时间，1 为自动 |
| Cloudflare代理 | 是否开启 CDN 代理 |
| 获得IP命令 | 留空自动检测，或自定义命令 |

## 🔧 命令示例

自定义 IP 获取命令（可选）：

```bash
# 指定接口（多拨环境）
curl -s --interface ppp0 ifconfig.me

# 使用其他服务商
curl -s ip.sb
curl -s myip.ipip.net
```

## 📝 更新日志

### v2.0 (2026-06-08)
- 重构 IP 获取模块，支持多源自动切换
- 修复 JSON 解析错误导致的更新失败问题
- 修复变量污染导致的请求体无效错误
- 增加内网 IP 自动过滤功能
- 增加 API 请求超时控制（10s 连接 / 15s 传输）
- 增加失败重试机制（3 次）
- 优化 IPv6 获取源，增加本地接口 fallback
- 改善日志输出，显示 IP 来源和错误详情
- 修复定时任务功能（原版被注释）

### v1.0
- 初始版本

## ⚠️ 注意事项

1. **使用前需在 CloudFlare 后台预先添加 DNS 记录**（A 记录或 AAAA 记录）
2. API Key 请使用 **Global API Key**，而非 API Token
3. 开启 CloudFlare 代理后，域名解析显示为 CF 节点 IP，所有流量经 CF 转发
4. 本插件仅适用于 Koolshare 梅林固件，其他平台请勿尝试安装

## 🔒 隐私说明

- 所有配置保存在路由器本地（dbus），不上传任何服务器
- 仅与 CloudFlare 官方 API（api.cloudflare.com）通信
- IP 检测使用公开服务商（ifconfig.me / icanhazip.com 等）
- 不包含任何跟踪代码、统计上报或后门

## 📄 开源协议

基于 GPL v3 协议开源。

原版作者：koolshare 社区  
优化改进：社区贡献

## 🙏 致谢

- [KoolShare](https://koolshare.cn) 提供的软件中心框架
- CloudFlare 提供的免费 DNS API

## 📧 反馈与贡献

如有问题请提交 Issue，欢迎 PR 贡献代码。

---

如果还需要其他格式（如简短版、英文版），请告诉我。

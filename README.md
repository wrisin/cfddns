# CloudFlare DDNS for Koolshare Merlin (增强修复版)

[![Platform](https://img.shields.io/badge/platform-Merlin%20(Koolshare)-blue.svg)](https://koolshare.cn)
[![License](https://img.shields.io/badge/license-GPLv3-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0-red.svg)](https://github.com/yourname/cfddns)

一个专为 Koolshare 梅林固件优化的 CloudFlare DDNS 插件，支持 IPv4/IPv6 双栈，具备多源 IP 检测、自动重试、内网 IP 过滤等增强功能。

> **本项目基于 [koolshare/armsoft](https://github.com/koolshare/armsoft) 项目中的 [cfddns](https://github.com/koolshare/armsoft/tree/master/cfddns) 原版插件进行深度优化和修复。**

---

## 📌 致谢与声明

- **原作者**: KoolShare 开发组及 armsoft 项目贡献者
- **原项目仓库**: [https://github.com/koolshare/armsoft](https://github.com/koolshare/armsoft)
- **原插件路径**: `koolshare/armsoft/cfddns`
- **遵循协议**: GNU General Public License v3.0

**尊重开源，致敬原作！**

---

## ✨ 功能特性

| 特性 | 说明 |
|------|------|
| **智能 IP 获取** | 自动轮询 7+ 个公开 IP 检测服务，任一源可用即成功 |
| **双栈支持** | 同时支持 IPv4 (A记录) 和 IPv6 (AAAA记录) 更新 |
| **内网 IP 过滤** | 自动识别并过滤 192.168.x.x、10.x.x.x、172.16-31.x.x 等内网地址 |
| **失败重试机制** | API 请求失败自动重试 3 次，递增等待时间 |
| **多接口兼容** | 自动适配 ppp0/ppp1/ppp1.2 等不同 PPPoE 接口 |
| **详细日志输出** | 记录 IP 来源、错误详情，便于排查问题 |
| **定时更新** | 支持自定义间隔时间自动检查更新 |
| **API 超时控制** | 连接超时 10 秒，传输超时 15 秒 |

---

## 🆚 与原版对比

| 优化项 | 原版 | 本版 |
|--------|------|------|
| IP 获取源 | 单一命令，失败即退出 | 7+ 个公开服务自动轮换 |
| 内网 IP 过滤 | ❌ 无 | ✅ 自动过滤 |
| 变量污染问题 | ❌ 存在（换行符导致） | ✅ 已修复 |
| JSON 解析 | `awk` 依赖字段顺序 | `sed` + 正则，按类型匹配 |
| API 重试机制 | ❌ 无 | ✅ 3 次重试 |
| 超时控制 | ❌ 无 | ✅ 连接/传输超时 |
| 错误详情 | 仅显示"失败" | 显示具体错误信息 |
| 定时任务 | 被注释 | ✅ 已实现 |

---

## 📦 安装要求

- Koolshare 梅林固件（RT-AC86U / RT-AX88U / GT-AC5300 / K3 等 hnd/axhnd 平台）
- CloudFlare 账号及域名
- 已在 CloudFlare 后台预先添加 A/AAAA 记录

---

## 🚀 快速开始

### 1. 下载安装
- 下载离线安装包
- 在软件中心选择「离线安装」
- 上传并安装插件

### 2. 配置插件

在插件配置页面填写以下信息：

| 配置项 | 说明 |
|--------|------|
| Email | CloudFlare 账号登录邮箱 |
| API KEY | CloudFlare 全局 API Key（需获取） |
| Zone ID | 域名对应的区域 ID |
| 子域名 | 需要 DDNS 的子域名，根域名填 `@` |
| 主域名 | 你的主域名 |
| TTL | 解析生效时间，`1` 为自动 |
| Cloudflare代理 | 是否开启 CDN 代理 |
| 获得IP命令 | **留空自动检测**，或自定义命令 |

### 3. 开启插件
- 打开「开启 CloudFlare DDNS」开关
- 点击「提交」保存

---

## ⚙️ 自定义 IP 获取命令（可选）

如果需要指定网络接口（如多拨环境），可以填写自定义命令：

```bash
# 指定 ppp0 接口
curl -s --interface ppp0 ifconfig.me

# 指定其他接口
curl -s --interface ppp1.2 icanhazip.com

# 使用其他 IP 检测服务
curl -s ip.sb
curl -s myip.ipip.net
curl -s api.ipify.org
```

**注意**：留空则使用自动检测模式（推荐）。

---

## 📝 更新日志

### v2.0 (2026-06-08)

**核心优化**：
- 重构 IP 获取模块，支持多源自动切换
- 增加内网 IP 自动过滤功能

**问题修复**：
- 修复 JSON 解析错误导致的更新失败
- 修复变量污染导致的请求体无效 (CF Error 9207)
- 修复 IPv6 获取失败问题

**功能增强**：
- 增加 API 请求超时控制（10s 连接 / 15s 传输）
- 增加失败重试机制（3 次，递增等待）
- 改善日志输出，显示 IP 来源和错误详情
- 实现被注释的定时任务功能

### v1.0 (原版)
- 初始版本 by KoolShare 开发组

---

## 🔧 故障排查

### 常见问题及解决方法

| 错误信息 | 可能原因 | 解决方案 |
|----------|----------|----------|
| `Request body is invalid` (9207) | IP 值包含换行符或内网地址 | 更新到 v2.0 版本，或清空自定义命令 |
| `获取本地IP错误` | 网络不通或 IP 检测服务失效 | 检查网络，或修改自定义命令 |
| `获取IPV6解析记录错误` | 路由器未获取 IPv6 | 检查 IPv6 网络设置 |
| `更新失败` | API Key 错误或域名不匹配 | 检查 CloudFlare 配置信息 |

### 查看日志
- 在插件 Web 界面点击「查看日志」标签
- 或 SSH 执行：`cat /tmp/upload/cfddns_log.txt`

---

## 🔒 隐私说明

本插件**不收集任何用户信息**：

- ✅ 所有配置保存在路由器本地（dbus），不上传任何服务器
- ✅ 仅与 CloudFlare 官方 API（api.cloudflare.com）通信
- ✅ IP 检测使用公开服务商（ifconfig.me / icanhazip.com / ipinfo.io 等）
- ✅ 不包含任何跟踪代码、统计上报或后门
- ✅ 日志仅存储在本地临时目录 `/tmp/upload/`

---

## 📄 开源协议

本项目基于 **GNU General Public License v3.0** 协议开源。

```
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
```

---

## 🙏 致谢

- [KoolShare](https://koolshare.cn) 社区及 armsoft 项目提供的软件中心框架
- CloudFlare 提供的免费 DNS API
- 所有参与测试和反馈的用户

---

## 📧 反馈与贡献

- **Issue 提交**: [GitHub Issues 页面](https://github.com/yourname/cfddns/issues)
- **PR 贡献**: 欢迎 Pull Request
- **讨论交流**: KoolShare 论坛对应板块

---

## 📁 项目文件结构

```
cfddns/
├── cfddns_config.sh      # 核心功能脚本（已优化）
├── Module_cfddns.asp     # Web 前端配置界面
├── install.sh            # 安装脚本
├── uninstall.sh          # 卸载脚本
└── README.md             # 说明文档
```

---

**如果本项目对你有帮助，请给个 Star ⭐ 支持一下！**

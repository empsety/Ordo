# Ordo

Ordo 是一款开源的 macOS 菜单栏窗口管理器，通过修饰键和鼠标移动来移动、缩放和排布窗口。使用 Swift 开发，无第三方依赖。

需要 macOS 14 或更高版本，支持 Apple Silicon 和 Intel Mac。

## 安装

1. 从 [Releases](https://github.com/empsety/Ordo/releases) 下载 DMG，将 Ordo 拖入“应用程序”。
2. 打开 Ordo，在“功能”页点击“授权”，按提示启用辅助功能权限。
3. 返回 Ordo，开启“启用窗口管理”。

## 使用

将鼠标放在目标窗口上，按住组合键并移动鼠标。

| 操作 | 默认组合键 | 说明 |
| --- | --- | --- |
| 移动 | `⌃⇧`（Control + Shift） | 窗口随鼠标移动 |
| 缩放 | `⌥⇧`（Option + Shift） | 固定左上角，调整右下角 |
| 排布 | `⌘⌃`（Command + Control） | 移动选择方向，松键应用；移回中心取消选择 |

排布方向对应以下布局：

- 左、右：半屏。
- 上：铺满屏幕可见区域。
- 下：宽、高各为可见区域的 75%，居中。
- 四个斜向：对应角落的四分之一屏。

排布避开菜单栏和 Dock，不进入原生全屏。移动和缩放可跨显示器；切换桌面会取消当前手势。

<details>
<summary>功能演示</summary>

<img src="Artwork/Demos/move.apng" width="800" alt="移动：按住 Control 和 Shift，窗口随鼠标移动">
<img src="Artwork/Demos/resize.apng" width="800" alt="缩放：按住 Option 和 Shift，固定左上角调整窗口尺寸">
<img src="Artwork/Demos/snap.apng" width="800" alt="排布：按住 Command 和 Control 选择方向，松键应用布局">

</details>

## 设置

“基础”页可设置登录自启、菜单栏图标和静默启动。“功能”页可修改快捷键、开关窗口管理和排布动画。每组快捷键至少包含两个修饰键，三组不能相同；重置只恢复默认快捷键。

关闭窗口后 Ordo 继续在后台运行。隐藏菜单栏图标后，可通过 Finder 或 Spotlight 重新打开主窗口。

当前源码支持简体中文、繁体中文、英语、日语和韩语，可在“基础 → 语言”切换，默认跟随系统。

## 隐私与兼容性

Ordo 只申请辅助功能权限，不读取普通按键，不拦截输入，不发送网络请求或采集遥测。设置和日志保存在本机，日志不包含窗口身份、几何或输入内容。

目前不支持原生全屏、跨 Space、Split View 或 Stage Manager 的专门适配。固定尺寸窗口或不支持辅助功能控制的应用可能无法调整。

## 开发与贡献

使用 Xcode 26+ 打开 [Ordo.xcodeproj](Ordo.xcodeproj)，选择 `Ordo` Scheme 和 `My Mac`。自行构建需为 App 与测试 target 配置有效的开发签名；本机更新脚本仅适用于维护者团队。

单元测试位于 `OrdoTests/`，构建与开发辅助脚本位于 `scripts/`。

欢迎提交 Issue 或 Pull Request。报告问题时，请提供 macOS 版本、目标应用、操作步骤和实际结果。

## 许可证

[MIT](LICENSE)

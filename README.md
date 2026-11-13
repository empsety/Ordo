<p align="center">
  <img src="Artwork/app-icon.png" width="128" height="128" alt="Ordo App 图标">
</p>

<h1 align="center">Ordo</h1>

Ordo 是一款开源的 macOS 菜单栏窗口管理器，通过修饰键和鼠标移动来移动、缩放和排布窗口。使用 Swift 开发，无第三方依赖。

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

## 功能演示

### 移动 `⌃⇧`

<img src="Artwork/Demos/move.apng" width="800" alt="移动：按住 Control 和 Shift，窗口随鼠标移动">

---

### 缩放 `⌥⇧`

<img src="Artwork/Demos/resize.apng" width="800" alt="缩放：按住 Option 和 Shift，固定左上角调整窗口尺寸">

---

### 排布 `⌘⌃`

<img src="Artwork/Demos/snap.apng" width="800" alt="排布：按住 Command 和 Control 选择方向，松键应用布局">

## 开发与贡献

使用 Xcode 26+ 打开 [Ordo.xcodeproj](Ordo.xcodeproj)，选择 `Ordo` Scheme 和 `My Mac`。自行构建需为 App 与测试 target 配置有效的开发签名。

单元测试位于 `OrdoTests/`。

欢迎提交 Issue 或 Pull Request。报告问题时，请提供 macOS 版本、目标应用、操作步骤和实际结果。

## 许可证

[MIT](LICENSE)

# QuitCue

<p align="center">
  <img src="design/assets/icon.png" width="120" alt="QuitCue app icon">
</p>

<h3 align="center">别再让一次手滑的 Command-Q 打断你的工作流。</h3>

<p align="center">
  QuitCue 是一款原生 macOS 效率工具，用来保护你最不想误退出的应用。选择需要保护的 App，设置确认方式，然后让它安静地常驻后台，只在真正按下 <kbd>⌘Q</kbd> 时出现。
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-111111?logo=apple&logoColor=white" alt="macOS 14+">
  <img src="https://img.shields.io/badge/SwiftUI-native-0A84FF?logo=swift&logoColor=white" alt="SwiftUI native">
  <img src="https://img.shields.io/badge/status-MVP-2F855A" alt="MVP status">
</p>

<p align="center">
  <a href="https://quitcue.app">quitcue.app</a>
</p>

![QuitCue protecting a desktop session](design/rendered/desktop-live-intercept-interactive.png)

## 为什么需要 QuitCue

每个 Mac 重度用户都经历过这种瞬间：IDE 正在跑任务，设计文件还没保存，终端里挂着长命令，手指却习惯性按下了 <kbd>⌘Q</kbd>。真正的问题不是退出，而是“不小心退出”发生得太快、代价太高。

QuitCue 只在高价值应用上增加一个轻量确认步骤。未受保护的应用照常退出，受保护的应用需要你明确确认。它不改变 macOS 的使用习惯，只把最容易误触的那一下变得可挽回。

QuitCue 的产品原则很简单：

- **只保护值得保护的应用。** IDE、设计软件、写作工具、终端、浏览器，都可以按需加入保护列表。
- **平时尽量没有存在感。** 常驻后台，只有受保护应用收到 <kbd>⌘Q</kbd> 时才显示确认浮层。
- **必须像系统功能一样自然。** 基于 SwiftUI、AppKit、macOS 材质、辅助功能权限和系统级事件监听构建。

## 产品体验

### 选择关键应用

QuitCue 会扫描本机安装的 macOS 应用，在一个紧凑的控制面板里管理保护列表。已保护应用会优先显示，方便快速确认当前守护范围。

![QuitCue control panel](design/rendered/control-panel-default.png)

### 两种确认方式

根据自己的肌肉记忆选择更顺手的防误触方式：

- **长按 Command-Q**：按住直到进度环完成，再真正退出。
- **连续按两次 Command-Q**：第一次触发提醒，短时间内第二次确认退出。

<p align="center">
  <img src="design/rendered/hold-default.png" width="48%" alt="Hold Command-Q confirmation">
  <img src="design/rendered/double-press.png" width="48%" alt="Double press Command-Q confirmation">
</p>

### 为真实 macOS 行为设计

QuitCue 使用 `CGEventTap` 监听并拦截受保护应用的普通 <kbd>⌘Q</kbd>。它会放行未保护应用，保留带有 Shift、Option、Control 等修饰键的其他快捷键，并在确认退出目标应用后继续保持 QuitCue 自身运行。

## 功能亮点

- 以 Bundle ID 持久化的应用级保护列表。
- 首次启动引导辅助功能权限和初始保护应用选择。
- 支持长按确认和双击确认两种模式。
- 可调节长按时长与双击确认窗口。
- 原生控制面板：保护应用网格、确认方式、开机启动等核心设置。
- 系统级确认浮层，只在受保护应用触发退出时出现。
- 支持生成发布 DMG，并可接入 Developer ID 签名与 notarization。
- 单元测试、UI 测试和 Tart VM 隔离测试覆盖不同风险层级。

## 安装

QuitCue 目前处于 MVP 开发阶段。你可以在本地构建发布包：

```bash
xcodegen generate
scripts/package-release-dmg.sh
```

生成的安装镜像会输出到 `dist/QuitCue-<version>.dmg`。如果需要从发布 tag
注入版本，可传入 `--marketing-version` 和 `--build-number`。

安装后，需要在 macOS 中授予 QuitCue 辅助功能权限，应用才能拦截 <kbd>⌘Q</kbd>：

`系统设置` -> `隐私与安全性` -> `辅助功能` -> 启用 `QuitCue`。

## 开发

开发前需要准备：

- Xcode 26 或更新版本
- XcodeGen
- create-dmg，用于本地安装镜像打包
- Tart，用于隔离 UI 和 EventTap 测试

常规入口：

```bash
xcodegen generate
open QuitCue.xcodeproj
```

`project.yml` 是项目结构的来源；生成出的 Xcode project 只作为构建产物使用。

## 测试策略

QuitCue 同时涉及普通 UI、macOS 辅助功能权限和底层键盘事件，因此测试按风险分层：

- 单元测试覆盖白名单判断、确认状态机、设置持久化、应用扫描和开机启动。
- UI 测试覆盖 onboarding、控制面板、浮层和非 EventTap 流程。
- EventTap 端到端测试放在 Tart VM 中运行，并依赖已授权的辅助功能与输入监控快照，避免影响宿主机。
- 发布包路径通过 DMG 脚本测试和已安装 App 的实际行为验证来确认。

## 设计资料

产品设计资料集中在 `design/`：

- `design/QuitCue Prototype.html`：交互原型。
- `design/Design Doc.html`：视觉和状态说明。
- `design/rendered/`：当前实现对齐时使用的渲染参考图。

调整 UI 时，应对照设计源文件和实际 App 效果，不要只依赖旧截图。

## 当前状态

QuitCue 仍处于 1.0 前的 MVP 阶段。核心应用、首次引导、控制面板、确认浮层、DMG 打包路径和测试框架已经具备，后续重点是视觉打磨、发布硬化和更多真实场景验证。

## License

License 信息尚未发布。

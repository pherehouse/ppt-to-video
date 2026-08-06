<p align="center">
  <h1 align="center">PPT to Video - AI Agent Skill</h1>
  <p align="center">
    🎬 一键将 PPT/PPTX 演示文稿转换为带 AI 配音和精准字幕的解说视频
    <br />
    支持 Trae、Claude Desktop、Codex、OpenCode 及所有支持 Markdown 格式的 AI Agent
    <br />
    <br />
    <a href="#功能特性">功能特性</a>
    ·
    <a href="#安装依赖">安装依赖</a>
    ·
    <a href="#安装方法">安装方法</a>
    ·
    <a href="#使用方法">使用方法</a>
    ·
    <a href="#命令行使用">命令行使用</a>
    ·
    <a href="#自定义配置">自定义配置</a>
    ·
    <a href="https://github.com/pherehouse/ppt-to-video">GitHub</a>
    ·
    <a href="README.md">English</a>
  </p>
</p>

---

<div align="center">
  <table>
    <tr>
      <td align="center"><a href="README.md">🌐 English</a></td>
      <td align="center">🇨🇳 <strong>简体中文</strong></td>
    </tr>
  </table>
</div>

---

## ✨ 功能特性

- 📁 **直接支持 PPTX 文件** - 自动转换，无需手动导出图片
- 🎙️ **AI 智能配音** - 使用微软 Edge TTS，多种中文音色可选，默认优化语速 1.15 倍，适合演示场景
- 🧠 **大模型语义字幕拆分** - 由宿主AI在润色文案时按自然语音停顿拆分为短句，字幕断句自然符合说话节奏
- 🧹 **YouTube 风格清爽字幕** - 自动去掉逗号句号等不必要标点，只保留问号感叹号表达语气，字幕干净易读
- 📝 **精确帧同步** - 基于 VTT 时间轴实现字幕与音频帧级精确同步
- 🎬 **专业转场效果** - 平滑交叉溶解转场，完整显示幻灯片内容 `object-fit: contain`，不裁剪、不晃动、不缩放
- 👁️ **多模态大模型理解** - 如果宿主AI支持视觉能力，会直接看图理解每页PPT内容（包括图表、流程图、示意图等OCR无法识别的内容），效果远超纯文字识别
- 🔍 **内置OCR兜底** - 使用 macOS 原生 Vision 框架提取文字，给不支持多模态的Agent作为起点
- 🆕 **零项目基础** - 在任意空目录运行即可，自动从零创建完整 Remotion 项目，不需要提前准备任何文件
- 🎞️ **1080p 30fps 输出** - 标准高清 MP4 格式，可直接分享上传
- 🔌 **通用兼容** - 支持 Trae、Claude Desktop、Codex、OpenCode 以及任何支持 Markdown 技能格式的 AI 客户端

## 📦 安装依赖

首先安装系统依赖：

```bash
# 所有场景都需要的基础依赖
brew install node ffmpeg
pip install edge-tts
xcode-select --install  # Swift 编译器（用于 OCR，大部分 macOS 已预装）

# 直接转换 PPTX 文件需要额外依赖（如果只传图片目录可跳过）
brew install --cask libreoffice
brew install poppler
```

| 工具 | 用途 |
|------|------|
| Node.js 16+ | Remotion 视频渲染运行时 |
| edge-tts | 免费微软 AI 文字转语音 |
| ffmpeg | 音频处理和时长测量 |
| Xcode CLI | Swift 编译器用于 OCR 文字识别 |
| LibreOffice | 将 PPTX 转换为 PDF |
| poppler | 将 PDF 拆分为单张 PNG 图片 |

> **Linux/Windows 用户注意**：内置 OCR 使用 macOS Vision 框架。在其他平台上，可以直接让用户提供解说文案，或将 `scripts/ocr.swift` 替换为 Tesseract OCR 脚本。

## 🚀 安装方法

根据你使用的 AI 客户端选择安装方式：

<details open>
<summary><strong>Trae IDE</strong></summary>

```bash
git clone https://github.com/pherehouse/ppt-to-video.git
cp -r ppt-to-video ~/.trae/skills/ppt-to-video
```
安装完成后重启 Trae 即可。
</details>

<details>
<summary><strong>Claude Desktop</strong></summary>

```bash
git clone https://github.com/your-username/ppt-to-video.git
mkdir -p ~/.claude/skills
cp -r ppt-to-video ~/.claude/skills/ppt-to-video
```
安装完成后重启 Claude Desktop 即可。
</details>

<details>
<summary><strong>Codex / OpenCode</strong></summary>

按照你使用平台的约定，将仓库克隆到对应的技能目录即可。标准 Markdown 格式的 SKILL.md 是通用兼容的。
</details>

<details>
<summary><strong>纯手动 / 命令行使用</strong></summary>

直接克隆仓库到任意位置，可以直接运行 shell 脚本。
</details>

## 🤖 在 AI 客户端中使用

安装完成后，直接对你的 AI 助手说自然语言即可：

```
把 ~/Desktop/第三季度汇报.pptx 转成视频，输出到 out/report.mp4
```

```
我有个 PPT 在 /Documents/产品介绍.pptx，用云希音色做一个解说视频
```

```
用 ~/slides-export 文件夹里的图片做一个带配音和字幕的视频
```

AI 会自动执行以下完整流程：
1. 检测并调用这个技能
2. 检查所有依赖是否安装
3. 将 PPT 转换为图片
4. 运行 OCR 提取内容
5. 将文案润色为自然口语
6. 生成 AI 配音
7. 渲染最终 MP4 视频

## 💻 命令行手动使用

不通过 AI 也可以直接运行脚本：

```bash
# 创建工作目录
mkdir my-video && cd my-video

# 运行初始化脚本
/path/to/ppt-to-video/ppt-to-video.sh <输入路径> <输出MP4路径> [音色] [语速]

# 示例：
~/skills/ppt-to-video/ppt-to-video.sh ~/talk.pptx out/video.mp4
```

### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `<输入路径>` | `.pptx` 文件路径 或 存放 PNG/JPG 图片的文件夹路径 | 必填 |
| `<输出MP4路径>` | 最终视频输出路径 | 必填 |
| `[音色]` | TTS 音色 ID | `zh-CN-YunxiNeural` |
| `[语速]` | 说话语速 | `+15%` (1.15倍) |

### 可用音色

| 音色 ID | 性别 | 风格 |
|---------|------|------|
| `zh-CN-YunxiNeural` | 男声 | 年轻、有活力 **(默认推荐)** |
| `zh-CN-YunjianNeural` | 男声 | 低沉、专业、正式 |
| `zh-CN-XiaoxiaoNeural` | 女声 | 温暖、自然、亲切 |
| `zh-CN-XiaoyiNeural` | 女声 | 轻柔、清晰、舒缓 |

## ⚙️ 完整手动流程

运行初始化脚本后，按以下步骤操作：

1. **润色解说文案**：编辑生成的 `gen-audio.sh` 中的 `SCRIPTS` 数组
2. **生成音频**：`bash gen-audio.sh`
3. **生成时间轴数据**：`node gen-slides-data.js $(ls public/slides | wc -l | tr -d ' ')`
4. **渲染视频**：`npx remotion render SlideshowVideo out/output.mp4 --concurrency=4`

### 浏览器预览

```bash
npx remotion studio
```
在浏览器打开 http://localhost:3000 即可交互式预览。

## 🔧 自定义配置

| 配置项 | 修改文件 | 默认值 |
|--------|----------|--------|
| 字幕字号 | `src/SlideshowVideo.tsx` | 30px |
| 单行字幕最大字数 | `gen-slides-data.js` | 14字 |
| 转场交叉淡入淡出时长 | `gen-slides-data.js` / `SlideshowVideo.tsx` | 15帧 (0.5秒) |
| 解说前后留白静音 | `gen-slides-data.js` / `SlideshowVideo.tsx` | 18帧 (0.6秒) |
| 分辨率 | `gen-slides-data.js` | 1920×1080 |
| 帧率 | `gen-slides-data.js` | 30fps |

## 📁 技能目录结构

```
ppt-to-video/
├── SKILL.md               # AI 可读取的技能定义和工作流指南
├── README.md              # 英文文档
├── README.zh-CN.md        # 本文档（中文）
├── LICENSE                # MIT 开源协议
├── .gitignore
├── ppt-to-video.sh        # 主初始化脚本
└── scripts/
    ├── ocr.swift          # macOS Vision OCR 辅助脚本
    └── gen-slides-data.js # 时间轴数据生成模板
```

## 🛠️ 技术栈

- [Remotion](https://www.remotion.dev/) - 基于 React 的视频渲染框架
- [Microsoft Edge TTS](https://github.com/rany2/edge-tts) - 免费 AI 语音生成
- [LibreOffice](https://www.libreoffice.org/) - 开源 PPTX 转换
- [macOS Vision](https://developer.apple.com/documentation/vision) - 原生 OCR 文字识别

## 📝 注意事项

- **内置 OCR 仅支持 macOS**：Windows/Linux 用户可以替换为 Tesseract
- PPT 动画不会保留：幻灯片导出为静态图片，技能会添加专业交叉淡化转场
- 文案质量决定最终效果：OCR 识别结果只是草稿，一定要润色后再生成音频
- 图片排序：如果使用图片目录输入，请命名为 `slide-01.png`、`slide-02.png` 以保证正确顺序

## 📄 开源协议

MIT License - 详见 [LICENSE](LICENSE) 文件。

---

<p align="center">
Made with ❤️ for AI agents everywhere
</p>

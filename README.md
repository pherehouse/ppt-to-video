<p align="center">
  <h1 align="center">PPT to Video - AI Agent Skill</h1>
  <p align="center">
    🎬 One-click convert PPT/PPTX presentations to narrated videos with AI voiceover and frame-accurate subtitles
    <br />
    Works with Trae, Claude Desktop, Codex, OpenCode, and all Markdown-based AI agents
    <br />
    <br />
    <a href="#features">Features</a>
    ·
    <a href="#installation">Installation</a>
    ·
    <a href="#usage">Usage</a>
    ·
    <a href="#cli-usage">CLI Usage</a>
    ·
    <a href="#customization">Customization</a>
    ·
    <a href="https://github.com/pherehouse/ppt-to-video">GitHub</a>
    ·
    <a href="README.zh-CN.md">中文</a>
  </p>
</p>

---

<div align="center">
  <table>
    <tr>
      <td align="center">🌐 <strong>English</strong></td>
      <td align="center"><a href="README.zh-CN.md">🇨🇳 简体中文</a></td>
    </tr>
  </table>
</div>

---

## ✨ Features

- 📁 **Direct PPTX support** - Automatic conversion, no manual image export needed
- 🎙️ **AI Voiceover** - Microsoft Edge TTS with multiple Chinese voices, optimized 1.15x default speed
- 📝 **Smart subtitles** - Auto-split at punctuation for readability, perfectly synced to audio
- 🎬 **Professional transitions** - Smooth cross-dissolve, full-slide display without cropping or shaking
- 🔍 **Built-in OCR** - macOS Vision framework extracts text to generate narration draft
- 🤖 **AI-assisted workflow** - AI agent automatically polishes OCR text into natural narration
- 🎞️ **1080p 30fps output** - Standard HD MP4 ready for sharing
- � **Universal compatibility** - Works with Trae, Claude Desktop, Codex, OpenCode, and any custom agent that supports Markdown skills

## 📦 Prerequisites

Install these dependencies first:

```bash
# Required for all functionality
brew install node ffmpeg
pip install edge-tts
xcode-select --install  # For Swift OCR (pre-installed on most macOS)

# Required for direct PPTX conversion
brew install --cask libreoffice
brew install poppler
```

| Tool | Purpose |
|------|---------|
| Node.js 16+ | Runtime for Remotion video rendering |
| edge-tts | Free Microsoft AI text-to-speech |
| ffmpeg | Audio processing and duration measurement |
| Xcode CLI | Swift compiler for OCR |
| LibreOffice | Convert PPTX → PDF |
| poppler | Split PDF → PNG images |

> **Linux/Windows note**: Built-in OCR uses macOS Vision. On other platforms, either provide narration text directly or replace `scripts/ocr.swift` with Tesseract.

## 🚀 Installation

### Install for your AI agent

<details open>
<summary><strong>Trae IDE</strong></summary>

```bash
git clone https://github.com/pherehouse/ppt-to-video.git
cp -r ppt-to-video ~/.trae/skills/ppt-to-video
```
Restart Trae after installation.
</details>

<details>
<summary><strong>Claude Desktop</strong></summary>

```bash
git clone https://github.com/pherehouse/ppt-to-video.git
mkdir -p ~/.claude/skills
cp -r ppt-to-video ~/.claude/skills/ppt-to-video
```
Restart Claude Desktop after installation.
</details>

<details>
<summary><strong>Codex / OpenCode</strong></summary>

Clone the repository to your agent's skill directory following your platform's conventions. The standard Markdown-based SKILL.md format is universally compatible.
</details>

<details>
<summary><strong>Manual / CLI only</strong></summary>

Just clone the repository anywhere on your system, you can run the shell script directly.
</details>

## 🤖 Usage with AI Agent

After installation, just talk to your AI assistant naturally:

```
Convert ~/Desktop/q3-report.pptx to video, save as out/report.mp4
```

```
I have a PPT at /Documents/talk.pptx, make a narrated video with Yunxi voice
```

```
Use the images in ~/slides-export folder to make a video with voiceover and subtitles
```

The AI agent will automatically:
1. Detect and invoke this skill
2. Check all dependencies
3. Convert PPT to images
4. Run OCR to extract content
5. Polish narration into natural speech
6. Generate AI voiceover
7. Render the final MP4 video

## 💻 Command Line Usage

You can also run the script directly without an AI agent:

```bash
# Create a working directory
mkdir my-video && cd my-video

# Run initialization
/path/to/ppt-to-video/ppt-to-video.sh <input-path> <output-mp4> [voice] [rate]

# Example:
~/skills/ppt-to-video/ppt-to-video.sh ~/talk.pptx out/video.mp4
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `<input-path>` | `.pptx` file OR folder of PNG/JPG images | Required |
| `<output-mp4>` | Output MP4 path | Required |
| `[voice]` | TTS voice ID | `zh-CN-YunxiNeural` |
| `[rate]` | Speech rate | `+15%` (1.15x) |

### Available Voices

| Voice ID | Gender | Style |
|----------|--------|-------|
| `zh-CN-YunxiNeural` | Male | Young, energetic **(default)** |
| `zh-CN-YunjianNeural` | Male | Deep, professional |
| `zh-CN-XiaoxiaoNeural` | Female | Warm, natural |
| `zh-CN-XiaoyiNeural` | Female | Gentle, clear |

## ⚙️ Complete Manual Workflow

After running the initialization script:

1. **Polish narration**: Edit the `SCRIPTS` array in generated `gen-audio.sh`
2. **Generate audio**: `bash gen-audio.sh`
3. **Generate timing data**: `node gen-slides-data.js $(ls public/slides | wc -l | tr -d ' ')`
4. **Render video**: `npx remotion render SlideshowVideo out/output.mp4 --concurrency=4`

### Preview in browser

```bash
npx remotion studio
```
Opens interactive preview at http://localhost:3000

## 🔧 Customization

| Setting | File | Default |
|---------|------|---------|
| Subtitle font size | `src/SlideshowVideo.tsx` | 30px |
| Max chars per subtitle | `gen-slides-data.js` | 14 |
| Crossfade duration | `gen-slides-data.js` / `SlideshowVideo.tsx` | 15 frames (0.5s) |
| Silence padding | `gen-slides-data.js` / `SlideshowVideo.tsx` | 18 frames (0.6s) |
| Resolution | `gen-slides-data.js` | 1920×1080 |
| FPS | `gen-slides-data.js` | 30 |

## 📁 Skill Structure

```
ppt-to-video/
├── SKILL.md               # AI-readable skill definition and workflow guide
├── README.md              # This file (English)
├── README.zh-CN.md        # Chinese documentation
├── LICENSE                # MIT License
├── .gitignore
├── ppt-to-video.sh        # Main initialization script
└── scripts/
    ├── ocr.swift          # macOS Vision OCR helper
    └── gen-slides-data.js # Timing data generator template
```

## 🛠️ Built With

- [Remotion](https://www.remotion.dev/) - React-based video rendering framework
- [Microsoft Edge TTS](https://github.com/rany2/edge-tts) - Free AI voice generation
- [LibreOffice](https://www.libreoffice.org/) - Open source PPTX conversion
- [macOS Vision](https://developer.apple.com/documentation/vision) - Native OCR text recognition

## 📝 Notes

- **macOS required for built-in OCR**: Windows/Linux can use Tesseract replacement
- PPT animations not preserved: Slides are static images with added crossfade transitions
- Narration quality matters: OCR text is a draft, always polish for best results
- File ordering: For image folder input, name files `slide-01.png`, `slide-02.png` for correct order

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
Made with ❤️ for AI agents everywhere
</p>

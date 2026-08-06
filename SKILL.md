---
name: "ppt-to-video"
display_name: "PPT to Video Converter"
description: "Convert PPT/PPTX files or slide image folders to narrated video with AI voiceover and precisely synchronized subtitles. Invoke when user provides a .pptx/.ppt file path or folder of slide images and asks to make a video, convert presentation/keynote/slides/powerpoint to a narrated video, add voiceover to slides, or turn PPT into video."
version: "1.0.0"
author: "ppt-to-video contributors"
license: "MIT"
compatibility: ["trae", "claude-desktop", "codex", "opencode", "custom-agents"]
tags: ["video", "ppt", "pptx", "text-to-speech", "tts", "remotion", "presentation", "narration", "subtitles"]
---

# PPT to Video - AI Agent Skill

One-click convert PPT/PPTX presentations or exported slide images into professional narrated MP4 videos with AI voiceover and frame-accurate subtitles. Works with Trae, Claude Desktop, Codex, OpenCode, and other AI agents that support Markdown-based skill definitions.

## 🎯 Trigger Conditions

Invoke this skill **automatically** when the user:
- Provides a path to a `.pptx` or `.ppt` file and asks to convert it to video
- Provides a path to a folder containing PNG/JPG slide images and asks to create a video
- Uses phrases like: "convert PPT to video", "make video from slides", "add voiceover to my presentation", "PPT转视频", "把PPT做成视频", "生成解说视频"
- Mentions converting PowerPoint/Keynote/slides into a narrated video with subtitles

## ✨ Features

- 📁 Direct PPTX input - Automatic conversion, no manual image export required
- 🎙️ AI voiceover - Microsoft Edge TTS, multiple voices available, default Chinese male voice (Yunxi) at 1.15x speed optimized for presentations
- 📝 Smart subtitles - Automatically splits long sentences at punctuation (commas/periods) for readability, perfectly synced to audio
- 🎬 Professional transitions - Smooth cross-dissolve between slides, full-slide display using `object-fit: contain` (no cropping, no panning, no shaking)
- 🔍 Built-in OCR - Uses macOS native Vision framework to extract text from slides and generate a narration draft
- 🤖 AI-assisted script writing - Agent can automatically polish raw OCR text into natural conversational narration
- 🎞️ Professional output - 1920×1080 @ 30fps MP4, ready for sharing, uploading, or presentations
- 🔧 Fully configurable - Adjust subtitle size, speed, transitions, voices, and more

## 📋 Prerequisites / Dependencies

**Check that these tools are installed before running the workflow. If any are missing, instruct the user to install them using the commands below.**

### Required for all input types
| Tool | Installation | Purpose |
|------|--------------|---------|
| Node.js 16+ | `brew install node` | JavaScript runtime for Remotion |
| edge-tts | `pip install edge-tts` | Free Microsoft AI text-to-speech |
| ffmpeg/ffprobe | `brew install ffmpeg` | Audio processing and duration measurement |
| Xcode Command Line Tools | `xcode-select --install` | Swift compiler for OCR (pre-installed on most macOS systems) |

### Additional required for direct PPTX conversion (not needed if user provides image folder)
| Tool | Installation | Purpose |
|------|--------------|---------|
| LibreOffice | `brew install --cask libreoffice` | Convert PPTX → PDF |
| poppler (pdftoppm) | `brew install poppler` | Split PDF → individual PNG slide images |

> **Note for Linux/Windows users**: The built-in OCR uses macOS Vision framework. On other platforms, either ask the user to provide narration text directly, or replace `scripts/ocr.swift` with a Tesseract-based OCR script.

## 🔄 Standard Workflow

Follow this exact sequence of steps when executing the skill:

---

### Step 1: Gather Input from User

Ask the user for:
1. **Input path**: Absolute path to either a `.pptx`/`.ppt` file OR a folder containing slide images (PNG/JPG)
2. **Output path**: Where to save the final MP4 file (e.g., `~/Desktop/presentation-video.mp4` or `out/output.mp4`)
3. (Optional) Voice selection - default is `zh-CN-YunxiNeural` (Chinese male Yunxi)
4. (Optional) Speech rate - default is `+15%` which equals 1.15x speed

If user provides a PPTX file but LibreOffice/poppler are not installed, offer two options:
1. Install the required dependencies
2. Export slides as images manually from PowerPoint and provide the folder path

---

### Step 2: Locate Skill Directory and Run Initialization

First, determine where this skill is installed. Common paths:
- Trae: `~/.trae/skills/ppt-to-video/`
- Claude Desktop: `~/.claude/skills/ppt-to-video/`
- Codex: Follow your agent's skill directory convention
- Manual: Wherever the user cloned the repository

Run the main initialization script from the user's desired working directory:
```bash
# Create a working directory for this video project (do NOT run inside the skill directory)
mkdir -p <work-dir> && cd <work-dir>

# Run initialization
bash <skill-dir>/ppt-to-video.sh <input-path> <output-mp4> [voice] [rate]
```

**Example:**
```bash
mkdir -p ~/video-projects/my-talk && cd ~/video-projects/my-talk
bash ~/.trae/skills/ppt-to-video/ppt-to-video.sh ~/Desktop/q3-report.pptx out/final.mp4
```

This script will automatically:
1. ✅ Check all required dependencies
2. 📦 Initialize a minimal Remotion project if one doesn't exist (installs npm dependencies automatically)
3. 🖼️ Convert PPTX → PDF → PNG images (if input is PPTX) OR copy/sort/convert images from folder (if input is directory)
4. 🔍 Run OCR on every slide to extract text content
5. 📝 Generate `gen-audio.sh` with placeholder narration populated from OCR results
6. 📋 Copy necessary data generation templates to working directory
7. Print OCR text preview for reference when writing narration

---

### Step 3: Polish the Narration Script (CRITICAL - DO NOT SKIP)

The auto-generated `gen-audio.sh` contains raw OCR text which is usually choppy, incomplete, and sounds robotic. **You must polish this into natural, flowing narration before proceeding.**

**IMPORTANT: Semantic line breaks for subtitles**
When writing narration, split each slide's script **directly into short complete sentences/phrases**, one per line in the `SCRIPTS` array. Use your LLM semantic understanding to break text at natural speech pauses - each line will become one subtitle.
- Each line should be a natural phrase, 8-25 characters, complete semantic unit
- Break at natural pauses (after clauses, between thoughts), like how people actually speak
- Lines don't need to end with periods/commas (they get stripped automatically, YouTube style)
- Only keep `?` `!` for questions/exclamations
- Automatic punctuation splitting is only a fallback - good line breaks by you produce much better results

Guidelines for good narration:
- Write each line as a short, complete natural phrase, one subtitle per line
- Add smooth transitional phrases between slides (e.g., "接下来我们看...", "首先...", "最后...")
- Balance narration length across slides - avoid 3-second pages followed by 30-second pages
- Fix any obvious OCR recognition errors
- Keep language conversational, like a real presenter speaking
- You don't need trailing commas/periods at the end of each line (they will be cleaned up)

After polishing (or confirming the script is acceptable), proceed. You can either:
- Edit the `SCRIPTS` array directly in `gen-audio.sh`, with one short natural phrase per line
- Present the polished script to the user for review/approval

---

### Step 4: Generate AI Voiceover and Subtitles

Run the audio generation script:
```bash
bash gen-audio.sh
```

This generates:
- One MP3 audio file per slide in `public/slides-audio/voice-NN.mp3`
- One VTT subtitle file per slide in `public/slides-audio/voice-NN.vtt` with word-level timing
- Prints duration for each audio file at the end

**Troubleshooting**: If edge-tts fails to generate audio for any individual slide (rare network issues or problematic punctuation), regenerate that slide manually:
```bash
edge-tts --voice zh-CN-YunxiNeural --rate=+15% --text "Corrected narration text here" \
  --write-media public/slides-audio/voice-05.mp3 \
  --write-subtitles public/slides-audio/voice-05.vtt
```
Replace `05` with the slide number that failed.

---

### Step 5: Generate Timing Data and Video Components

Count the number of slides (count PNG files in `public/slides/`), then run:
```bash
SLIDE_COUNT=$(ls public/slides | wc -l | tr -d ' ')
node gen-slides-data.js $SLIDE_COUNT
```

This automatically generates three files:
1. `src/slidesData.ts` - Frame-accurate timing data for all slides, audio durations, subtitle cues
2. `src/SlideshowVideo.tsx` - Remotion React component with crossfade transitions, image display, and synchronized subtitle rendering
3. `src/Root.tsx` - Remotion composition entry point

The default settings are:
- 1920×1080 resolution
- 30 FPS
- 0.5 second crossfade between slides
- 0.6 second silence padding before/after narration
- 14 characters maximum per subtitle line (auto-split at punctuation)
- 30px white subtitle text with text shadow, positioned near bottom

---

### Step 6: Render Final MP4 Video

Create output directory and render:
```bash
mkdir -p out
npx remotion render SlideshowVideo <output-mp4> --concurrency=4
```

Rendering tips:
- Use `--concurrency=4` for balanced speed/stability on most machines
- Use `--concurrency=8` on powerful Macs/PCs for faster rendering
- For a quick preview render at lower quality, add `--quality=low`

If the user wants to preview before full render, run the Remotion Studio:
```bash
npx remotion studio
```
This opens an interactive browser preview at http://localhost:3000 where you can scrub through the video and check subtitle timing.

---

### Step 7: Deliver Result

Inform the user when rendering completes:
- Provide the absolute path to the final MP4 file
- Mention total duration of the video
- Offer to make adjustments if they want changes (see Customization section below)

## ⚙️ Customization Guide

If user requests changes after seeing the first render, use this reference:

| User Request | What to modify |
|--------------|----------------|
| Subtitles too big/small | Edit `fontSize` in `src/SlideshowVideo.tsx` (default: 30px), then re-render |
| Too many words per subtitle line | Change `MAX_CHARS_PER_CUE` constant in `gen-slides-data.js` (default: 14), re-run steps 5-6 |
| Transitions too fast/slow | Change `OVERLAP` constant in `gen-slides-data.js` and `SlideshowVideo.tsx` (default: 15 frames = 0.5s), re-run steps 5-6 |
| Pacing feels too tight/too much empty space | Change `PAD` constant in `gen-slides-data.js` and `SlideshowVideo.tsx` (default: 18 frames = 0.6s silence before/after narration), re-run steps 5-6 |
| Change narration content/script | Edit the `SCRIPTS` array in `gen-audio.sh`, then re-run steps 4-6 |
| Change voice or speed | Edit `VOICE` and `RATE` variables in `gen-audio.sh`, then re-run steps 4-6 |
| Change subtitle color/position/font | Edit the subtitle `<div>` style in `src/SlideshowVideo.tsx`, then re-render |
| Add background music | Add an `<Audio src={staticFile('bgm.mp3')} volume={0.15} />` component to `SlideshowVideo.tsx`, place BGM file in `public/`, re-render |
| Change video resolution/FPS | Edit constants in `gen-slides-data.js`, re-run steps 5-6 |

## 🎤 Available Voices (Chinese)

| Voice ID | Gender | Style | Best for |
|----------|--------|-------|----------|
| `zh-CN-YunxiNeural` | Male | Young, energetic, clear | **Default**, most presentations, business, tech |
| `zh-CN-YunjianNeural` | Male | Deep, authoritative, mature | Formal reports, executive presentations |
| `zh-CN-XiaoxiaoNeural` | Female | Warm, natural, friendly | Education, marketing, explainers |
| `zh-CN-XiaoyiNeural` | Female | Gentle, soft, clear | Training, customer-facing content |

English voices are also available if requested (e.g., `en-US-GuyNeural`, `en-US-JennyNeural`).

## ⏱️ Speech Rate Reference

Edge TTS uses percentage offset from normal speaking rate. 1.0x = `+0%`.

| Value | Multiplier | Typical use case |
|-------|------------|------------------|
| `-20%` | 0.8x | Slow, training material, easy to follow |
| `-10%` | 0.9x | Slightly slower, clear for non-native speakers |
| `+0%` | 1.0x | Original natural speed, formal/keynote presentations |
| `+10%` | 1.1x | Slightly faster, natural conversational pace |
| `+15%` | **1.15x** | **Default**, optimized for most business/tech presentations |
| `+25%` | 1.25x | Fast, dense information, summary videos |

## 📁 Project Structure After Running

When you run the script in a working directory, it creates:
```
your-working-dir/
├── public/
│   ├── slides/              # slide-01.png, slide-02.png... extracted/converted slides
│   └── slides-audio/        # voice-NN.mp3 + voice-NN.vtt per slide
├── src/
│   ├── slidesData.ts        # Auto-generated timing data
│   ├── SlideshowVideo.tsx   # Video component (transitions + subtitles)
│   └── Root.tsx             # Remotion composition entry
├── gen-audio.sh             # Editable narration script (MODIFY THIS TO CHANGE SCRIPT)
├── gen-slides-data.js       # Data generation script (copied from skill)
├── package.json             # Auto-generated npm dependencies
├── remotion.config.ts       # Remotion configuration
├── tsconfig.json            # TypeScript configuration
└── out/                     # Final rendered MP4 output
```

## 🚀 One-Line Pipeline (After Script is Finalized)

Once the narration in `gen-audio.sh` is approved, you can run the entire remaining pipeline in one command:
```bash
bash gen-audio.sh && node gen-slides-data.js $(ls public/slides | wc -l | tr -d ' ') && npx remotion render SlideshowVideo out/final.mp4 --concurrency=4
```

## 💡 Important Notes for Agents

1. **Always run in an empty working directory**, never directly inside the skill installation folder. The script creates project files in the current working directory.
2. **Narration quality is the most important factor** for a good final video. Spend time polishing the script instead of accepting raw OCR output.
3. **macOS is required for the built-in OCR**. On other platforms, either ask user to provide narration text, or modify the OCR step.
4. **PPT animations are not preserved**. Slides are exported as static images; the skill adds crossfade transitions instead.
5. **Check audio generation output** - if you see "Failed to find two consecutive MPEG audio frames" for any slide, regenerate that audio file manually.
6. **File ordering matters**: When user provides an image folder, files are sorted using natural version sort (`sort -V`). Naming files `1.png`, `2.png` or `slide-01.png`, `slide-02.png` guarantees correct order. PPTX conversion always preserves page order correctly.

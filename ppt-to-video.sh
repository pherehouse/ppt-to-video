#!/bin/bash
# ppt-to-video: Convert PPT/PPTX to narrated video with voiceover and subtitles
# Repository: https://github.com/your-username/ppt-to-video
#
# Usage:
#   ./ppt-to-video.sh <PPTX_FILE_OR_IMAGE_FOLDER> <OUTPUT_MP4> [VOICE] [RATE]
#
# Examples:
#   ./ppt-to-video.sh ~/Desktop/presentation.pptx out/video.mp4
#   ./ppt-to-video.sh ~/Desktop/slides-folder out/video.mp4 zh-CN-YunxiNeural +15%
#
# Rate parameter explanation:
#   +0%   = 1.0x (original speed)
#   +15%  = 1.15x (default, good for presentations)
#   -20%  = 0.8x (slower, easier to follow)

set -e

# ========== Configuration ==========
INPUT_PATH="${1:?Usage: $0 <PPTX file or image folder> <Output MP4> [Voice] [Rate]
  Example: $0 ~/my-slides.pptx out/output.mp4}"
OUTPUT_MP4="${2:?Please specify output MP4 path}"
VOICE="${3:-zh-CN-YunxiNeural}"
RATE="${4:-+15%}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(pwd)"

# ========== Color Output ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ========== Dependency Check ==========
info "Checking dependencies..."

# Required for all modes
REQUIRED_COMMON="edge-tts ffprobe swift node npm npx"
for cmd in $REQUIRED_COMMON; do
  if ! command -v $cmd &>/dev/null; then
    error "Missing dependency: $cmd
Please install required dependencies first. See README for instructions."
  fi
done

# Required for PPTX conversion
REQUIRED_PPTX="soffice pdftoppm"
MISSING_PPTX=""

# ========== Initialize Remotion Project ==========
info "Setting up project structure..."
mkdir -p public/slides public/slides-audio out src .tmp-ocr .tmp-convert

# Check if package.json exists, if not initialize Remotion project
if [ ! -f "package.json" ]; then
  warn "No package.json found, initializing Remotion project..."
  # Create minimal package.json with Remotion dependencies
  cat > package.json << 'PKGEOF'
{
  "name": "ppt-to-video-project",
  "version": "1.0.0",
  "description": "PPT to Video generated project",
  "scripts": {
    "start": "remotion studio",
    "build": "remotion render SlideshowVideo"
  },
  "dependencies": {
    "@remotion/cli": "^4.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "remotion": "^4.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "typescript": "^5.0.0"
  }
}
PKGEOF
  info "Installing npm dependencies..."
  npm install
fi

# Create remotion.config.ts if missing
if [ ! -f "remotion.config.ts" ]; then
  cat > remotion.config.ts << 'CFGEOF'
import { Config } from "@remotion/cli/config";

Config.setVideoImageFormat("jpeg");
Config.setConcurrency(4);
CFGEOF
fi

# Create tsconfig.json if missing
if [ ! -f "tsconfig.json" ]; then
  cat > tsconfig.json << 'TSEOF'
{
  "compilerOptions": {
    "target": "ES2018",
    "module": "ESNext",
    "moduleResolution": "node",
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist"
  },
  "include": ["src/**/*"]
}
TSEOF
fi

# ========== Process Input: PPTX file or Image folder ==========
rm -f public/slides/* public/slides-audio/* .tmp-ocr/* .tmp-convert/*

if [ -f "$INPUT_PATH" ]; then
  # ========== PPTX/PPT File Input ==========
  EXT="${INPUT_PATH##*.}"
  EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
  
  if [[ "$EXT_LOWER" != "pptx" && "$EXT_LOWER" != "ppt" ]]; then
    error "Unsupported file format: .$EXT. Please provide .pptx/.ppt file or image folder."
  fi

  for cmd in $REQUIRED_PPTX; do
    if ! command -v $cmd &>/dev/null; then
      MISSING_PPTX="$MISSING_PPTX $cmd"
    fi
  done
  
  if [ -n "$MISSING_PPTX" ]; then
    error "Missing dependencies for PPTX conversion:$MISSING_PPTX

Please install:
  - LibreOffice: brew install --cask libreoffice
  - poppler:     brew install poppler

Or export slides as images manually and provide the folder path."
  fi

  info "Converting PPT to images..."
  PPTX_ABS="$(cd "$(dirname "$INPUT_PATH")" && pwd)/$(basename "$INPUT_PATH")"
  
  info "  Converting to PDF..."
  soffice --headless --convert-to pdf --outdir "$WORK_DIR/.tmp-convert" "$PPTX_ABS" >/dev/null 2>&1
  PDF_FILE=$(ls -1 "$WORK_DIR/.tmp-convert"/*.pdf 2>/dev/null | head -1)
  if [ ! -f "$PDF_FILE" ]; then
    error "PDF conversion failed"
  fi

  info "  Splitting PDF to PNG images..."
  pdftoppm -png -r 150 "$PDF_FILE" "$WORK_DIR/.tmp-convert/slide"

  SLIDE_COUNT=0
  i=1
  for img in "$WORK_DIR"/.tmp-convert/slide-*.png; do
    if [ -f "$img" ]; then
      n=$(printf '%02d' $i)
      cp "$img" "public/slides/slide-$n.png"
      echo "    Page $i → slide-$n.png"
      SLIDE_COUNT=$i
      i=$((i+1))
    fi
  done

  if [ "$SLIDE_COUNT" -eq 0 ]; then
    error "No pages extracted from PPT"
  fi
  info "Successfully extracted $SLIDE_COUNT pages from PPT"

elif [ -d "$INPUT_PATH" ]; then
  # ========== Image Folder Input ==========
  SLIDES_DIR="$INPUT_PATH"
  
  SLIDE_COUNT=$(ls -1 "$SLIDES_DIR" | grep -E '\.(png|jpg|jpeg)$' | sort -V | wc -l | tr -d ' ')
  if [ "$SLIDE_COUNT" -eq 0 ]; then
    error "No PNG/JPG images found in $SLIDES_DIR"
  fi
  info "Found $SLIDE_COUNT slide images"

  info "Preparing images..."
  i=1
  for img in $(ls -1 "$SLIDES_DIR" | grep -E '\.(png|jpg|jpeg)$' | sort -V); do
    n=$(printf '%02d' $i)
    ext="${img##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    if [ "$ext_lower" = "png" ]; then
      cp "$SLIDES_DIR/$img" "public/slides/slide-$n.png"
    else
      sips -s format png "$SLIDES_DIR/$img" --out "public/slides/slide-$n.png" >/dev/null 2>&1
    fi
    echo "  [$i/$SLIDE_COUNT] $img → slide-$n.png"
    i=$((i+1))
  done

else
  error "Input path does not exist: $INPUT_PATH"
fi

# ========== Step 1: OCR ==========
echo ""
info "Running OCR on all slides..."
for i in $(seq 1 $SLIDE_COUNT); do
  n=$(printf '%02d' $i)
  swift "$SCRIPT_DIR/scripts/ocr.swift" "public/slides/slide-$n.png" > ".tmp-ocr/slide-$n.txt" 2>/dev/null
  echo "  [$i/$SLIDE_COUNT] OCR complete"
done

# ========== Step 2: Generate gen-audio.sh ==========
echo ""
info "Generating narration script template (gen-audio.sh)..."
warn "Generated script contains OCR text - please REVIEW and POLISH the SCRIPTS array!"

cat > gen-audio.sh << GENEOF
#!/bin/bash
# Auto-generated narration script
# EDIT THE SCRIPTS ARRAY BELOW TO POLISH YOUR NARRATION
VOICE="$VOICE"
RATE="$RATE"
OUTDIR="public/slides-audio"
mkdir -p "\$OUTDIR"

declare -a SCRIPTS=(
  ""  # 0 placeholder
GENEOF

for i in $(seq 1 $SLIDE_COUNT); do
  n=$(printf '%02d' $i)
  text=$(head -8 ".tmp-ocr/slide-$n.txt" | tr '\n' ' ' | sed 's/"/\\"/g' | sed 's/[[:space:]]\+/ /g' | cut -c 1-200)
  if [ -z "$text" ]; then
    text="Page ${i} content description"
  fi
  echo "  \"$text\"" >> gen-audio.sh
done
echo ")" >> gen-audio.sh

cat >> gen-audio.sh << 'GENEOF'

echo "=== Generating audio ==="
TOTAL_SLIDES=$((${#SCRIPTS[@]}-1))
for i in $(seq 1 $TOTAL_SLIDES); do
  n=$(printf '%02d' $i)
  text="${SCRIPTS[$i]}"
  echo "[$i/$TOTAL_SLIDES] Generating voice-$n.mp3 ..."
  edge-tts --voice "$VOICE" --rate="$RATE" --text "$text" \
    --write-media "$OUTDIR/voice-$n.mp3" \
    --write-subtitles "$OUTDIR/voice-$n.vtt" 2>/dev/null
done

echo ""
echo "=== Audio duration check ==="
for i in $(seq 1 $TOTAL_SLIDES); do
  n=$(printf '%02d' $i)
  dur=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTDIR/voice-$n.mp3" 2>/dev/null || echo "ERROR")
  echo "voice-$n.mp3: ${dur}s"
done
GENEOF
chmod +x gen-audio.sh

# Copy gen-slides-data.js template
cp "$SCRIPT_DIR/scripts/gen-slides-data.js" "$WORK_DIR/gen-slides-data.js"

# ========== Print instructions and OCR preview ==========
echo ""
info "Project initialized successfully!"
echo ""
echo "========================================================================"
echo "✅  Setup complete!"
echo ""
echo "📋  Next steps:"
echo "   1. EDIT gen-audio.sh → polish the narration in the SCRIPTS array"
echo "      (OCR preview printed below for reference)"
echo ""
echo "   2. Run:  bash gen-audio.sh"
echo "      (Generates MP3 audio + VTT subtitles)"
echo ""
echo "   3. Run:  node gen-slides-data.js $SLIDE_COUNT"
echo "      (Generates timing data + video components)"
echo ""
echo "   4. Run:  npx remotion render SlideshowVideo $OUTPUT_MP4"
echo "      (Renders final MP4 video)"
echo ""
echo "💡 Quick preview during editing: npx remotion studio"
echo "========================================================================"
echo ""
echo "=== OCR Content Preview (for writing narration) ==="
for i in $(seq 1 $SLIDE_COUNT); do
  n=$(printf '%02d' $i)
  echo ""
  echo "--- Slide $i ---"
  head -8 ".tmp-ocr/slide-$n.txt"
done

rm -rf .tmp-convert

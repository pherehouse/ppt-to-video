const fs = require('fs');
const {execSync} = require('child_process');

const slideCount = parseInt(process.argv[2], 10);
if (!slideCount) {
  console.error('Usage: node gen-slides-data.js <slide-count>');
  console.error('Example: node gen-slides-data.js 24');
  process.exit(1);
}

const FPS = 30;
const PAD = 18;
const OVERLAP = 15;
const MAX_CHARS_PER_CUE = 28; // 约1-2句话，适合阅读
const SOFT_SPLIT_CHARS = /(?<=[。！？!?；;])/; // 硬拆分：句末标点，优先在这里拆分
const HARD_SPLIT_CHARS = /(?<=[，,、：:])/; // 软拆分：中间标点，超长时才用

const slides = [];

for (let i = 1; i <= slideCount; i++) {
  const n = String(i).padStart(2, '0');
  const mp3 = `public/slides-audio/voice-${n}.mp3`;
  const vtt = `public/slides-audio/voice-${n}.vtt`;

  if (!fs.existsSync(mp3)) {
    console.error(`❌ Missing audio file: ${mp3}`);
    console.error(`   Did you run "bash gen-audio.sh" first?`);
    process.exit(1);
  }

  const durSec = parseFloat(
    execSync(`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${mp3}"`).toString().trim()
  );
  const audioFrames = Math.ceil(durSec * FPS);
  const pageFrames = PAD + audioFrames + PAD;

  const vttText = fs.readFileSync(vtt, 'utf8');
  const lines = vttText.split(/\r?\n/);
  const cues = [];
  let j = 0;
  while (j < lines.length) {
    if (lines[j].includes('-->')) {
      const [startStr, endStr] = lines[j].split('-->').map((s) => s.trim());
      const startSec = vttTimeToSec(startStr);
      const endSec = vttTimeToSec(endStr);
      let text = '';
      j++;
      while (j < lines.length && lines[j].trim() !== '') {
        text += (text ? ' ' : '') + lines[j].trim();
        j++;
      }
      const startFrame = Math.round(startSec * FPS) + PAD;
      const endFrame = Math.round(endSec * FPS) + PAD;
      const splitCues = splitLongCue(text, startFrame, endFrame);
      for (const c of splitCues) cues.push(c);
    }
    j++;
  }

  slides.push({
    index: i,
    audio: `slides-audio/voice-${n}.mp3`,
    slideImg: `slides/slide-${n}.png`,
    audioFrames,
    pageFrames,
    cues,
  });
}

let totalFrom = 0;
for (const s of slides) {
  s.from = totalFrom;
  totalFrom += s.pageFrames;
}
const totalDuration = totalFrom;

function splitLongCue(text, startFrame, endFrame) {
  const totalFrames = endFrame - startFrame;
  const totalChars = text.length;
  if (totalChars <= MAX_CHARS_PER_CUE) return [{text, startFrame, endFrame}];

  // First split by sentence-ending punctuation (。！？；) to get complete sentences
  let sentences = text.split(SOFT_SPLIT_CHARS).filter((s) => s.trim());
  
  // If any single sentence is still too long, split it by commas/colons
  const parts = [];
  for (const sent of sentences) {
    if (sent.length <= MAX_CHARS_PER_CUE) {
      parts.push(sent);
    } else {
      // Split long sentence by middle punctuation
      const subParts = sent.split(HARD_SPLIT_CHARS).filter((s) => s.trim());
      // Merge short subparts together if they fit within MAX_CHARS_PER_CUE
      let buf = '';
      for (const sp of subParts) {
        if ((buf + sp).length <= MAX_CHARS_PER_CUE) {
          buf += sp;
        } else {
          if (buf) parts.push(buf);
          buf = sp;
        }
      }
      if (buf) parts.push(buf);
    }
  }

  // Now distribute frames proportionally to character count
  const result = [];
  let accFrames = 0;
  for (let i = 0; i < parts.length; i++) {
    const p = parts[i];
    const frames = i === parts.length - 1 
      ? totalFrames - accFrames 
      : Math.round((p.length / totalChars) * totalFrames);
    const s = startFrame + accFrames;
    const e = s + frames;
    result.push({text: p.trim(), startFrame: s, endFrame: e});
    accFrames += frames;
  }
  return result;
}

function vttTimeToSec(s) {
  const m = s.match(/(\d+):(\d+):(\d+)[.,](\d+)/);
  if (!m) return 0;
  const [, h, mm, ss, ms] = m;
  return parseInt(h) * 3600 + parseInt(mm) * 60 + parseInt(ss) + parseInt(ms.padEnd(3, '0').slice(0, 3)) / 1000;
}

// 写 SlideshowVideo 组件
const componentCode = `import React from 'react';
import {
  AbsoluteFill,
  Audio,
  Img,
  Sequence,
  interpolate,
  staticFile,
  useCurrentFrame,
} from 'remotion';
import {SLIDES} from './slidesData';

const OVERLAP = ${OVERLAP};
const PAD = ${PAD};

export const SlideshowVideo: React.FC = () => {
  return (
    <AbsoluteFill style={{backgroundColor: '#111'}}>
      {SLIDES.map((slide) => (
        <Sequence
          key={slide.index}
          from={Math.max(0, slide.from - OVERLAP)}
          durationInFrames={slide.pageFrames + OVERLAP}
          layout="none"
        >
          <SlidePage slide={slide} isFirst={slide.index === 1} isLast={slide.index === SLIDES.length} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

const SlidePage: React.FC<{
  slide: (typeof SLIDES)[number];
  isFirst: boolean;
  isLast: boolean;
}> = ({slide, isFirst, isLast}) => {
  const frame = useCurrentFrame();
  const pageStart = OVERLAP;
  const pageFrame = frame - pageStart;
  const totalDuration = slide.pageFrames + OVERLAP;

  const fadeIn = isFirst
    ? 1
    : interpolate(frame, [0, OVERLAP], [0, 1], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
      });
  const fadeOut = isLast
    ? 1
    : interpolate(frame, [totalDuration - OVERLAP, totalDuration], [1, 0], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
      });
  const opacity = Math.min(fadeIn, fadeOut);

  const activeCue = slide.cues.find(
    (c) => pageFrame >= c.startFrame && pageFrame <= c.endFrame
  );

  let subtitleOpacity = 0;
  if (activeCue) {
    const dur = activeCue.endFrame - activeCue.startFrame;
    const local = pageFrame - activeCue.startFrame;
    subtitleOpacity = interpolate(
      local,
      [0, 4, dur - 4, dur],
      [0, 1, 1, 0],
      {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}
    );
  }

  const audioStart = pageStart + PAD;
  const audioDuration = slide.audioFrames;

  return (
    <AbsoluteFill style={{opacity}}>
      <Img
        src={staticFile(slide.slideImg)}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'contain',
          objectPosition: 'center',
        }}
      />

      {activeCue && (
        <div
          style={{
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0,
            padding: '22px 60px 36px',
            background: 'linear-gradient(to top, rgba(0,0,0,0.75), rgba(0,0,0,0))',
            display: 'flex',
            justifyContent: 'center',
          }}
        >
          <div
            style={{
              opacity: subtitleOpacity,
              color: '#ffffff',
              fontSize: 30,
              fontWeight: 500,
              lineHeight: 1.5,
              textAlign: 'center',
              maxWidth: 1400,
              textShadow: '0 2px 6px rgba(0,0,0,0.9)',
              letterSpacing: '0.02em',
            }}
          >
            {activeCue.text}
          </div>
        </div>
      )}

      <Sequence from={audioStart} durationInFrames={audioDuration} layout="none">
        <Audio src={staticFile(slide.audio)} volume={1} />
      </Sequence>
    </AbsoluteFill>
  );
};
`;
fs.writeFileSync('src/SlideshowVideo.tsx', componentCode, 'utf8');

// 写 Root.tsx（确保注册了 SlideshowVideo 合成）
const rootCode = `import React from 'react';
import {Composition} from 'remotion';
import {FPS, HEIGHT, WIDTH} from './slidesData';
import {SlideshowVideo} from './SlideshowVideo';
import {SLIDESHOW_DURATION} from './slidesData';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="SlideshowVideo"
        component={SlideshowVideo}
        durationInFrames={SLIDESHOW_DURATION}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
      />
    </>
  );
};
`;
fs.writeFileSync('src/Root.tsx', rootCode, 'utf8');

// Write index.ts entry point (required by Remotion)
const indexCode = `import {registerRoot} from 'remotion';
import {RemotionRoot} from './Root';

registerRoot(RemotionRoot);
`;
fs.writeFileSync('src/index.ts', indexCode, 'utf8');

// 写数据文件
const dataCode = `// AUTO-GENERATED by gen-slides-data.js
export const FPS = ${FPS};
export const WIDTH = 1920;
export const HEIGHT = 1080;

export type Cue = { text: string; startFrame: number; endFrame: number };
export type Slide = {
  index: number;
  audio: string;
  slideImg: string;
  from: number;
  audioFrames: number;
  pageFrames: number;
  cues: Cue[];
};

export const SLIDES: Slide[] = ${JSON.stringify(slides, null, 2)};

export const SLIDESHOW_DURATION = ${totalDuration};
`;
fs.writeFileSync('src/slidesData.ts', dataCode, 'utf8');

console.log(`✅ Total frames: ${totalDuration} (${(totalDuration / FPS).toFixed(1)}s)`);
console.log(`✅ Generated src/index.ts, src/slidesData.ts, src/SlideshowVideo.tsx, src/Root.tsx - ${slides.length} slides total`);
console.log(`Next step: npx remotion render SlideshowVideo <output-file.mp4>`);

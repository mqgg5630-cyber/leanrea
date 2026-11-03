# 风格配方库：16 种「治愈 / 好看 / 动漫可爱」照片转绘

每条配方 = 一个可复制的 prompt 骨架。**前缀（保真）和尾缀（禁字）是固定的，只有 `STYLE BLOCK` 换。**

```
[PREFIX]  Use the supplied photo as the base. Keep the exact composition, camera angle,
          crop, subject pose and proportions, and the recognizable identity of the subject
          (face shape, hairstyle, clothing colors, distinctive markings). Do not add,
          remove, or move major objects. Preserve the original aspect ratio.

[STYLE BLOCK]  ← 下面 R01–R16 任选一条

[SUFFIX]  No text, no letters, no watermark, no extra limbs, no deformed hands.
```

**状态**：R01–R07、R09、R10、R11、R16、R17 已实测（30 张，见 `test-log.md` / `style-scorecard.md`）；R08、R12–R15 仍为备选配方。

强度三档（写在提示词里就是一句话）：

| 档 | 说法 | 效果 | 什么时候用 |
|---|---|---|---|
| L 轻 | `restyle only the color, light and surface texture; keep shapes photographic` | 像换了滤镜/胶片 | 人像、证件、要"本人还能认出来" |
| M 中（默认） | `rebuild as <style> while keeping composition and identity` | 换画风，构图人物不变 | 绝大多数场景 |
| H 重 | `fully repaint in <style>, allow stylized proportions` | Q 版 / 大头 / 场景重画 | 头像、贴纸、封面、宠物 |

---

## R01 · 日系动漫赛璐璐（anime cel）· `s1-anime-cel/`

- **一眼识别**：细线 + 平涂 + 2–3 阶明暗 + 高光点，像当季新番截图。
- **适合**：人像、宠物、街景、食物（食物会变得很"番剧食堂"）。
- **不适合**：皱纹/皮肤质感特写（会被磨平）、复杂机械结构。
- **STYLE BLOCK**

```
Rebuild the photo as a modern Japanese TV-anime cel-shaded illustration. Clean thin dark
line art, flat cel shading with 2-3 tone steps per surface, crisp specular highlights,
soft light bloom in the highlights, warm healing color palette. Simplify the background
into a few painted shapes with gentle depth of field. Keep faces in anime proportions
that still read as the same person.
```

- **翻车点**：模型把脸换成"通用二次元脸" → 在 PREFIX 里点名 `same eye shape, same nose length, same hairstyle parting, same jawline`；背景被改成樱花/蓝天 → 加 `keep the original background elements and their positions`。
- **实测**：人像、猫、食物都很稳，猫的条纹与闭眼表情完整保留。

## R02 · 吉卜力治愈绘本（ghibli gouache）· `s2-ghibli/`

- **一眼识别**：水粉笔触、手绘云、暖午后光、奶油+赭石色板、微微纸纹。
- **适合**：风景、老房子、田园、猫、生活静物；人像也可以但容易"长大成动画配角"。
- **不适合**：夜景霓虹（见 R07）、冷调科技感场景。
- **STYLE BLOCK**

```
Repaint as a hand-painted Studio-Ghibli-inspired gouache illustration. Soft watercolor-
gouache texture with visible brushwork, layered hand-painted clouds, warm late-afternoon
sunlight, gentle nostalgic summer atmosphere, palette of leaf green, sky blue, cream and
terracotta, rounded gentle shapes, subtle paper grain, painterly simplification of foliage
and architecture.
```

- **翻车点**：整体发黄发脏 → 补 `fresh clean colors, no muddy brown overlay`；人像眼神变呆 → 补 `keep her calm direct gaze`。
- **实测**：人像与猫稳定；天空/云的层次明显好于普通 anime 提示词。

## R03 · 奶油蜡笔软萌简笔（cream crayon kawaii）· `s3-crayon/`

- **一眼识别**：粗深棕描边 + 奶油纸底 + 粉腮红 + 贴纸白边，就是小红书"一二布布"那一路。
- **适合**：宠物、食物、日常小物、情侣合照；人像会变 Q 版（要慎用）。
- **不适合**：需要细节的风景、建筑、多人合影的辨识。
- **STYLE BLOCK**

```
Turn it into an ultra-cute healing crayon sticker illustration. Chibi proportions with a
slightly bigger head and tiny body, thick soft dark-brown outlines, flat warm pastel fills
on cream paper texture, round pink blush cheeks, tiny dot eyes and a simple happy
expression, mascot-sticker white die-cut edge, a few tiny sparkle and heart accents,
minimal background shapes, generous empty space.
```

- **翻车点**：容易变成"幼稚涂鸦"而不是"设计过的可爱" → 加 `clean deliberate line weight, not childish scribble`；元素乱加 → `no extra props, only what is in the photo`。
- **实测**：猫的版本可直接当贴纸/头像；食物版本保留了 croissant 与拉花的辨识度；背景木纹被简化成手绘纹理，正确。

## R04 · 3D 黏土盲盒（clay blind box）· `s4-clay/`

- **一眼识别**：哑光橡皮泥质感、圆润体积、粉色/奶油背景、棚拍柔光。
- **适合**：宠物、食物、手办感小物、单人半身像；是最"出片"的一种。
- **不适合**：大场景、需要真实透视的建筑。
- **STYLE BLOCK**

```
Rebuild as a soft 3D clay / blind-box figure diorama. Matte plasticine texture with
fingerprint-level surface detail, rounded chubby forms, simplified cute face, pastel
palette (cream, dusty pink, terracotta), soft studio lighting with gentle contact shadows,
seamless pastel backdrop, miniature set feel, 50mm product-shot look.
```

- **翻车点**：人会变成"塑料感玩偶" → 想保留人味就用 L/M 档并加 `keep natural proportions, only materials change`；背景被换成纯色棚 → 加 `keep the recognizable background objects, rebuilt in clay`。
- **实测**：人像与猫最惊艳；食物略"模具感"，但很可爱。

## R05 · 透明水彩绘本（watercolor storybook）· `s5-watercolor/`

- **一眼识别**：湿画法晕染、冷水彩纸颗粒、细淡墨线、留白多。
- **适合**：风景、静物、安静的人像、老物件。
- **不适合**：夜晚高对比、动感强的照片（会糊）。
- **STYLE BLOCK**

```
Turn it into a light transparent watercolor storybook illustration. Wet-on-wet washes,
visible cold-press paper grain, soft bleeding edges, delicate thin ink lines, warm cream
paper showing through, restrained earthy palette, airy negative space, no hard gradients.
```

- **翻车点**：水痕变成"脏污" → 加 `clean washes with intentional water blooms, no muddy stains`；人像五官漂 → 见 PREFIX 补强。
- **实测**：人像与原图构图完全对齐；风景（待测）预计是本配方最强项。

## R06 · 撕纸拼贴 zine 海报（torn-paper collage）· `s6-paper-collage/`

- **一眼识别**：一半真实照片 + 一半抽象纸插画 + 手撕白纤维边 + 一个高饱和色当结构，3:5 竖版。
- **适合**：食物、街景、植物、旅行照片做封面。
- **不适合**：人脸特写（撕边会切到脸）、需要完整叙事的多人照。
- **STYLE BLOCK**

```
Turn it into a tactile torn-paper zine collage poster, vertical 3:5. Keep a truthful
photographic fragment of the scene as the anchor, then let a larger calm abstract
paper-illustration field reinterpret the main objects into a few big quiet shapes. One
high-chroma hue carries the composition. Visible hand-torn white fibrous paper edge where
photo becomes paper, warm cream paper grain, generous negative space, flat scanned look,
no mockup framing, no micro-text.
```

- **翻车点**：照片被整张"画一遍" → 强调 `one area remains visibly photographic`；撕边像剪的锯齿 → `irregular fibrous torn edge, not scissors-cut`；**照片里的印刷字会被原样保留**（实测：餐巾上的 "Usar en" 留下来了）→ PREFIX 之后追加 `remove all printed text, packaging copy, logos and labels from the photographic fragment`.
- **实测（1 张，食物）**：构图与蓝色结构成立，但插画场没真正长大，且文字泄漏 → 见 `style-scorecard.md` 的「修配方」判定。
- **来源**：`xiaoou-waou/zhaopianfengge-skill`（见 `github-skills.md`）。

## R07 · 新海诚式夜景动画（anime night）· `s7-anime-night/`

- **一眼识别**：青紫高饱和、霓虹与路灯的光晕、湿地面反射、密集手绘背景。
- **适合**：夜晚街道、便利店、雨天、车站。
- **不适合**：白天风景（会变得不合理）、食物（颜色会脏）。
- **STYLE BLOCK**

```
Cinematic anime night illustration inspired by modern Japanese animated films. Saturated
blue-magenta palette, glowing neon and streetlight bokeh, wet reflective pavement, dense
hand-painted urban background detail, lens flare and light bloom, romantic lonely
atmosphere. Keep the exact street layout, sign positions and subject placement, but do not
render legible lettering on any sign.
```

- **翻车点**：招牌文字变乱码 → SUFFIX 之外再加 `signs are abstract glowing shapes, no readable characters`；路面反射过强 → `moderate reflections, keep ground texture visible`。
- **实测（1 张，东京夜巷）**：霓虹、湿地面反光、密集街景全部到位；但招牌仍生成了"像日文又不是日文"的伪字（本次实测最主要缺陷）。真正的文案要后期脚本叠字。

## R08 · 日系柔光胶片（jp film photo）· `s8-jp-film/`

- **一眼识别**：低对比、奶油高光、轻微青绿阴影、颗粒，**不换画风只换质感**。属于 L 档。
- **适合**：人像、日常、咖啡店、宠物；也是"我不想要二次元，只想好看一点"的默认答案。
- **STYLE BLOCK**

```
Keep the photograph photographic. Apply a soft Japanese film look: gentle lifted blacks,
creamy highlight roll-off, slight green-cyan shadow tint, low contrast, fine grain, soft
natural light, clean healthy skin texture without plastic smoothing. Do not redraw or
beautify the person; keep every detail of the original scene.
```

- **翻车点**：变成"过度磨皮"→ 明确 `keep skin pores and flyaway hair`；变灰 → `keep colors fresh, not washed out`。
- **替代**：真正要做到"零幻觉"，用 ffmpeg 调色（`qq939/muse-photo-color-grading` 的配方）比生成模型更靠谱。

---

## R11 · 韩系厚涂（korean painterly）· `s11-korean-painterly/`

- **一眼识别**：半写实、厚涂柔和过渡、水润眼睛、侧逆光轮廓光，像韩剧海报/网漫封面。
- **适合**：单人像、情侣图、情侣头像；人物会被"美化"，年龄感更年轻。
- **不适合**：要求"就是我"的证件/纪念用途；老人、皮肤质感特写。
- **STYLE BLOCK**

```
Rebuild as a semi-realistic Korean webtoon-style romantic illustration. Soft painterly
blending, delicate facial features, dewy eyes, warm rim light from one side, gentle warm
skin tones, softly simplified background with a clean warm gradient, romantic gentle mood.
Keep their exact proportions, height difference and the clothing colors.
```

- **翻车点**：会"自动加手"（实测多出一条搂腰手臂）→ 加 `keep the original pose and limb positions exactly, no added arms`；两张脸被画成网红脸 → 逐项点名脸型、发型、配饰。
- **实测（1 张，情侣）**：颜值 5 分、保真 3.5 分——最好看的一张，也是最不像的一张。

## 备选 7 种（配方已写，尚未实测）

| id | 风格 | 关键 STYLE BLOCK 片段 | 最适合 |
|---|---|---|---|
| R09 | 毛毡玩偶 felt ✅已测 | `needle-felted wool toy, visible fiber fuzz, stitched seams, stitched seams, soft rim light, cream backdrop` | 宠物、食物、情侣（实测很出彩） |
| R10 | 彩铅绘本 colored pencil ✅已测 | `soft colored-pencil hatching, warm cream paper, gentle wobbly outlines, muted friendly palette` | 人像（实测保真第一）、植物、静物 |
| R12 | 像素画 pixel art | `16-bit pixel art, limited 24-color palette, dithered shading, crisp pixel edges, 1px outline` | 街景、食物、宠物 |
| R13 | 浮世绘 ukiyo-e | `Japanese ukiyo-e woodblock print, flat color areas, bold outlines, wave/cloud patterns, washi texture` | 风景、建筑 |
| R14 | 复古漫画网点 retro manga | `black-and-white screentone manga, hatching, high contrast, vintage print grain` | 人像、街景 |
| R15 | 玻璃彩绘 stained glass | `stained-glass panel, thick dark leading lines, jewel-tone translucent panes, backlit glow` | 建筑、窗景、花卉 |
| R16 | 3D 动画（Pixar-ish）✅已测 | `soft 3D animated-film still, subsurface-scattering skin, big expressive eyes, cinematic warm light, shallow depth of field` | 人像、情侣、宠物（最"迪士尼"的一种） |
| R17 | 少女漫画 shoujo manga ✅已测 | `delicate thin lines, big sparkle eyes, pink-lavender screentone, stars and petals, airy white space` | 情侣、少女头像（最梦幻） |

## 选风格速查

| 你的照片 | 第一选择 | 第二选择 | 别选 |
|---|---|---|---|
| 单人像（室内/暗光） | R05 / R01 | R11、R04 | R06、R12 |
| 情侣 / 双人 | R05 / R02 | R01、R11 | R03（手会糊）、R04（换脸） |
| 情侣头像（分头转） | R01 / R11 | R03、R02 | R05（太小看不出水彩） |
| 宠物 | R03 / R04 | R01、R09 | R13 |
| 食物 / 咖啡 | R04 / R03 | R06、R02 | R07、R14 |
| 风景（白天） | R02 / R05 | R13、R01 | R07 |
| 夜景街道 | R07 | R01（L 档） | R05、R02 |
| 想要"只变好看" | R08 或 ffmpeg 调色 | — | 任何 H 档重绘 |

> 去留判断见 `style-scorecard.md`：R01/R02/R05 是默认主力，R03/R04 限宠物食物，R07 限夜景，R11 限情侣头像，R06 待修。

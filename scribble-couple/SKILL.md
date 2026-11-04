---
name: scribble-couple
description: 把情侣 / 单人照片「复刻成原作者那张蜡笔涂鸦原画」——复刻 V1 重蜡笔忠实版为标准交付：纯白纸、两遍抖断的黑蜡笔线、方宽脸、黑色圆角矩形眼、整块黑刘海、彩铅斜排线露白、每侧三四道腮红、一颗小红心，右下角签名 sdldyh。当用户说「照着这张原画复刻」「画成这种手绘情侣头像」「照片转涂鸦风」「要这种糙糙的蜡笔感」，或发来抖音/小红书同款手绘情侣头像截图说「就要这种」时使用。
---

# scribble-couple：原作原画 → 同款复刻（情侣涂鸦头像）

**一句话规格：把原作者那张画 1:1 复刻成白纸上的两个方脸大头人——黑蜡笔线抖着画了两遍，颜色斜着排线涂不满，右下角 `sdldyh`。**

这个风格的全部难点只有一个字：**糙**。不是「精致的可爱」，是「手抖的人拿蜡笔随手涂的可爱」。

**本技能 = 第六轮交付那一套的固化版**（五对 × 复刻两版 + 四列对照）：
口径、提示词、验收标准全部按那一轮，别自己改口径。

> ⚠️ **最重要的一条（第六轮定稿）：任务是「把原作者那张画复刻出来」，不是「照照片重画」。**
> 参考图顺序有语义：**图 1 = 这一对的原画（唯一目标，1:1 照抄）**，**图 2 = 这一对的原片（只用来核对细节，不许反过来改构图）**。
> 原画决定一切——姿势、取景、手势、道具、配色、用线；照片只决定「细节有没有错」。顺序反了，就会得到一张「好看但不像原作」的重画版，前六轮全部栽在这里。

## 复刻②：只喂第一列（原片）也要像第二列（第十一轮定稿）

第十轮把原画也喂进 ②，出来反而像「原画的劣化版」。第十一轮改成 **② 只喂原片、原画完全不进输入**，
把第二列的舞台**写成文字**，五对全部明显好转（`examples/out-v11/`、`tests/v11/deliverable-v11.jpg`）。
成功的关键不是形容词，而是这段**舞台说明（STAGING）**，缺一项就错一项：

```
Draw a wax-crayon picture of the couple in IMAGE 1 on PURE WHITE PAPER — empty white
background, no wall, no room, no shadow. IMAGE 1 is a real photo and the only reference:
take their faces, hair, expressions, clothes and accessories from it.
Do not copy the photo's background, its lighting or its framing.

STAGING — follow exactly:
CANVAS vertical 4:5, pure white paper, cropped at <the chest / the hip / the waist>.
Two heads, big: together they fill about 80% of the width. <谁在左、谁在右、谁的头更大更高、
脸朝哪边、有没有贴脸 / 亲脸颊 / 一人在前一人半挡>.
LEFT — <发型 + 帽子/配饰 + 表情 + 上衣 + 下装 + 手放在哪里>.
RIGHT — <同上；手势一定要写死：托下巴 / 放头顶 / 举锅铲 / 双手举相机>.
<小道具与点缀：红心在哪侧、黄星、三道黄色动感线、比耶的大手在哪一角>.
```

后面接 `STYLE — heavy wax crayon` 那一整段（见附录 A.1），末尾加一句总判据：

```
If it looks like a clean digital line drawing or a thin pen sketch, it is wrong.
At 25% zoom it must still read as FAT BLACK LINES and BIG WHITE BLOCKS.
```

**第十一轮实测结论**：构图、姿势、手势、道具、红心位置 5/5 都对上；剩下的差距是**笔重**——
线偏细、脸偏圆、头发黑块像一撮撮碎线而不是一整块。补针：

```
hair must be ONE opaque black block, not many small scribbles,
outline thickness at least one eye wide, every contour drawn twice
```

**D 这种车内背景**：舞台里要写 `the whole background is dense diagonal crayon hatching, not white
paper`，否则会被洗成白底。

## 交付契约：每对两版（第十轮口径，第十一轮改法）

用户口径（原话整理）：**「复刻第二列要很像；通过第一列复刻出第二列，也要和第二列很像」**——
5 对 × 2 版 = 交付 10 张，两版都拿第二列当验收尺。第一列（原片）和第二列（原画）都是从原图里提取的，
**两张都可以喂**，区别只在谁说了算：

| 版本 | `images` | 提示词要点 | 验收 |
|---|---|---|---|
| **复刻① 照第二列** | `[干净原画]` | 原画即唯一目标，逐项照抄；不带原片 | 与第二列并排，遮住签名分不出谁是谁 |
| **复刻② 通过第一列** | `[干净原画, 原片]` | 原画仍是 target；原片只核对细节（脸、配饰、衣服图案） | 同样像第二列，且人物细节比①更贴原片（手表、涂鸦、格子、帽贴） |

两版的差别只有「原片在不在场」，**构图、取景、头身比、手势、道具一律照第二列，不许被原片拉走**。
第十轮已按此出齐（`examples/out-v10/`：01 A 复刻①…10 E 复刻②，对照 `tests/v10/deliverable-10.jpg`）。

## 交付标准：一版到位（第六轮定稿）

实测五对下来，**「复刻 V1 · 重蜡笔忠实版」始终是最像原画的那一版**，所以技能里的标准交付版本就是它，**不再默认一稿两版**。

| | 复刻 V1（标准，默认交付） | 复刻 V2（按需附加，不默认） |
|---|---|---|
| 定位 | 忠实复刻原画，什么都不改 | 同一张画，只把收尾做细 |
| 线 | 完全照原画：厚双勾、抖、断 | 同粗细，绝不软化 |
| 颜色 | 照原画的斜排线与露白 | 过渡更柔、排线更匀 |
| 何时用 | **默认，永远出这一版** | 用户明确说「再来一版软一点的」 |

- V2 **只允许动颜色段**；构图、姿势、头身比、黑线粗细、留白一律不动。踩过的坑：一句「softer」会把实心黑方块眼改成带睫毛高光的动漫眼——那已经是改结构，必须补 `same solid black rectangle eyes, no eyelash, no highlight`。
- 原作者本身有两种手感：**重蜡笔**（A / B / C / E 的派对帽、条纹衫、比耶、厨房）和**软彩铅**（D 的车内那张）。复刻时**跟着每一张原画自己的手感走**，不要把自己的偏好强加给原画。

## 第 0 步：把「原画」和「原片」对上（最容易出错，也最致命）

抖音 / 小红书的这类帖子结构是固定的：**上面一张成品画，评论区有人贴了原片并说「求求了/老师可以画吗」**。一份截图里同时有画和片，但它们分属不同情侣。

**规则：一对情侣 = 一张成品画 + 一张它自己的原片。绝对不要跨对混用。**

| 截图 | 成品画（风格参考） | 原片（内容参考） | 这对是谁 |
|---|---|---|---|
| `shot-0330713` / `-0336689` | `artwork-A` | `original-A` | 卷发男生 + 长直发齐刘海女生，白 T、双肩包、手托下巴 |
| `shot-0340796` | `artwork-B` | `original-B` | 蓝白条纹衫 + 派对帽，男生凑过去亲女生脸 |
| `shot-0345802` | `artwork-C` | `original-C` | 黄棒球帽女生比耶 + 黑 T 卷发男生从背后抱 |
| `shot-0417356` | `artwork-D` | `original-D` | 车内，双麻花辫 + 头顶墨镜 + 藏青 POLO，男生 wink + 手放头顶 |
| `shot-1236656` | `artwork-E` | `original-E` | 厨房，女生戴印着 hello 的厨师帽举锅铲、穿藏青格纹无袖；男生圆眼镜 + 粉色老鼠耳发箍、浅灰紫 T、举相机 |

**对齐的自检**：把原片和成品画并排放，逐条核对——发型（直/卷、有无刘海、绑法）、衣服（条纹？有无图案？）、配饰（墨镜、帽子、手表、背包）、手势。**四条都对上才算同一对**。只要有一条不符，就说明抓错了图。

> 教训：第一版把「D 的原片」配了「A 的画」做对照，用户一眼看出「对应错了」。原片和原画必须来自同一对，否则出来的图既不像片也不像画。

**原片提取**：原片是评论区缩略图，通常只有 300–450px。按像素框裁出后 ×4 LANCZOS + `UnsharpMask(2,70,2)`，放大到 1200–1800px 再用。裁完必须看一眼有没有 UI 残留（头像栏、评论、播放键）。

## 何时用 / 何时别用

- 用：情侣 / 闺蜜 / 单人照片 → 社交头像、朋友圈、纪念日礼物、小红书封面。
- 用：用户发来别人的手绘头像说「这种能画吗」——先裁一张他的样张当参考图，再套本技能。
- 用：用户发来**抖音 / 小红书截图**（右下角常有原作者水印）——先按像素裁出里面的成品图当样张，再找截图里的**原始照片**，两件事分开做。
- 别用：要求「像本人五官」的写真（这里脸只有 5 个零件）；要背景、要场景、要精细上色的插画。
- 别用：商用批量（先确认画风来源与授权，签名不代表版权）。

## 输出契约

```
<project>/
├── references/
│   ├── artworks/clean/        每对一张干净原画（图 1 = 复刻目标；气泡/灰边必须切掉）
│   ├── artworks/              原画原始裁切（留档，不再直接喂模型）
│   ├── originals/             每对的原始照片（图 2，只核对细节）
│   └── user-screenshots/      用户上传的截图（溯源用，只读）
├── examples/out-vN/           原始输出 01-A-v1.jpg …
├── examples/out-vN-final/     交付：中文名 01 A 复刻① 重蜡笔.jpg …
└── examples/compare-…-four-columns.jpg   四列对照（主交付物）
```

- 对照表固定四列：**原片 | 原画（=目标，红框）| 复刻 V1（蓝框）| 复刻 V2**。**不要再放「上一轮生成」那一列**。
- 取景照原画：原画裁到胸就裁到胸，裁到胯就裁到胯；**原画有背景就保留背景**（D 的车内不许改成白底）。
- 其余仍按风格 DNA：人物占放宽 75–80%，签名 `sdldyh` 右下角，小、斜、细，高度约画面 2–3%。

## 风格 DNA（v2 规格，逐条照抄，别自由发挥）

| 元素 | 规格（必须可量化） | 不合格的样子 |
|---|---|---|
| 线 | 黑蜡笔，**每条轮廓画两遍**（复线偏移 2–4px），压力不均、时粗时细；抖、断、末端出头 5–10px；拐角常留 3–5px 缺口 | 干净等宽的二次元线、矢量描边 |
| 内部线 | 少量细划痕线（头发、衣褶、下巴），不闭合 | 面面俱到的细节线 |
| 脸型 | **宽、平、略方**，颧骨到下颌几乎垂直，下巴钝平；脸宽 ≈ 脸高的 0.85；头身比 1 : 1.6（更接近大头娃娃） | 圆脸、尖下巴、标准动漫脸 |
| 眼 | **实心黑圆角矩形**（像竖着的小胶囊，无眼白），位置**偏低且间距大**，无高光、无睫毛；上眼睑另起一条更粗的短线压在眼睛上方 | 大眼、高光、睫毛、瞳孔渐变 |
| 眉 | 粗、短、平，几乎贴着上眼睑 | 细眉、挑眉、弯眉 |
| 鼻 | 一个点（偶尔一个小 v） | 画鼻梁、鼻翼 |
| 嘴 | 小张口笑（内里浅粉/白），或一条短弧 | 唇线、厚唇、写实嘴 |
| 腮红 | 每侧 **3–4 道**红色短斜排线，压在脸颊外侧，线头露白 | 高斯模糊红晕、粉扑感 |
| 头发 | **整块黑**，块内用白色蜡笔划痕透出纸色；刘海压成**一整块**黑，只在下缘切几刀；轮廓外 5–10 根乱飞线 | 一根根描发丝、上高光、棕发渐变 |
| 填色 | 彩铅**斜向排线**（约 45°），**内缩线内 3–5px 露白**，颗粒可见、压力不均；白衣服基本留纸 | 平涂填满、渐变、阴影、投影 |
| 配饰 | 只留 1–2 个（墨镜、帽子、串珠手链、手表），画成大色块 + 抖线 | 全部细节 |
| 点缀 | 小红心 1 颗 + 黄星 1–3 颗，偶尔 2 个短感叹号；都在头部上方外侧 | 满屏爱心、贴纸、水印 |
| 构图 | 人物占宽 75–80%，顶部留白约 8%，裁到胸口 | 人缩在中间一小块 |
| 签名 | `sdldyh`，右下角，斜着写，细 | 居中、变大、拼错、加框 |

### 色板（色号只是参考，关键是「涂不满」）

| 用途 | 近似 | 说明 |
|---|---|---|
| 线 / 头发 | `#171717` | 不用纯 `#000`，留一点蜡笔的涩 |
| 皮肤 | `#F6C9AC`（斜排线，空隙露白） | 不要均匀肉色 |
| 腮红 | `#E8604C` | 3–4 道短线 |
| 红心 | `#E5484D` | 一颗，实心带毛边 |
| 黄星 | `#F5C542` | 1–3 颗 |
| 深蓝（男方 POLO / 卫衣） | `#2F4470` | 斜排线，衣褶处断 |
| 白（女生上衣） | 纸白 | 只画轮廓，不填色 |

## 口径澄清：第三列为什么像（先想清楚这件事，再动手）

第六轮那张对照表是四列：

```
① 第一列 原片   |  ② 第二列 原作者原画  |  ③ 第三列 复刻 V1  |  ④ 第四列 复刻 V2
```

**第三列本身 = 「拿第二列当 target 1:1 复刻」的产物**，它像第二列是这个原因，不是因为我们从第一列推出了什么。两种需求必须分开回答：

| 用户要的 | 能不能 | 怎么做 |
|---|---|---|
| 「用第一列，画出第三列那种像第二列的效果」 | **能**，前提是**这一对的第二列原画在场** | 第二列当 `IMAGE 1`（target），第一列当 `IMAGE 2`（只核对细节）——见下节逐字提示词 |
| 「只给照片，也画成第二列那样」 | **只能做到「同一位画手画的另一对」，做不到「同一张画」** | 用别对的干净原画当画风锚（附录 A），并接受构图、姿势由照片决定 |

一句话：**构图和用笔来自第二列，长相来自第一列。缺第二列，只能换一只手，换不来这张画。**

## 第六轮第三列的原始提示词（逐字，别改写）

第三列五对（`examples/out-v7/*`）全部由这段生成，`images = [这一对的干净原画, 这一对的原片]`：

```
IMAGE 1 = the artist's original drawing. IT IS THE TARGET, NOT A REFERENCE.
Reproduce it as closely as possible — same composition, same crop, same head sizes,
same poses, same hand positions, same clothing, same props, same colour areas,
same line weight, same amount of solid black, same amount of bare white paper.
Do not redesign, do not beautify, do not re-frame.
IMAGE 2 = the real photo of the couple. Use it ONLY to confirm small details that are
hard to read in image 1. Never change the composition of image 1 to match the photo.

Output: a new hand-drawn reproduction of image 1, <upright 4:5 / square-ish>, <cropped at
the chest / at the hip>, on pure white paper.
（原画有背景的，例如 D 的车内：the frame is filled with dense diagonal hatching for the
car interior — keep it, do NOT turn it into white paper.）

Exact content to reproduce:
LEFT — <发型（直/卷、长度、刘海、绑法）+ 眼睛画法 + 表情 + 腮红/星 + 上衣 + 配饰 + 手势，逐项写>
RIGHT — <同上；一定要写手放在哪里、有没有背包带 / 手表 / 眼镜>
<小道具与原画特有的点缀：红心在哪侧、黄星、三根感叹号、比耶的大手…>
Signature bottom-right corner: small, thin, slanted handwriting "sdldyh", dark grey.

VERSION ①: faithful heavy wax-crayon reproduction — thick doubled black outlines with tiny
breaks, hair as one solid mass with a few white scratch lines, pale cream skin with only two
or three light hatch strokes, 45-degree hatching, high amount of solid black balanced by lots
of bare white paper. Keep the original's hand-shake and unevenness.

No readable words, no watermark, no border, no frame, no UI, no photo texture.
```

**每一句在管什么（改之前先看这张表）**

| 句子 | 管的是 |
|---|---|
| `IT IS THE TARGET, NOT A REFERENCE` | 抄这张画 vs 借它的风格——这句一改就前功尽弃 |
| `same composition / crop / head sizes / poses` | 构图、取景、头身比、手的位置 |
| `same amount of solid black / bare white paper` | 黑与白的比例（像不像的关键） |
| `IMAGE 2 … ONLY to confirm small details` | 保证照片不把构图拉走 |
| `Never change the composition … to match the photo` | 堵住模型「按片重画」的惯性 |
| `Exact content to reproduce` 清单 | 逐项兜底，漏一项就漏一项 |

## 实测（2026-11，v10，同一批五对 × 四条路线）

见 `tests/v10/review-sheet.jpg` 与 `tests/v10/sheet-two-stage.jpg`：

| 路线 | 输入 | 结果 | 与第二列的距离 |
|---|---|---|---|
| 3（第六轮第三列） | 原画 target + 原片核对 | 交付版 | 基准，几乎同纸 |
| 5（逐字复用同一段提示词） | 同上 | **五对全部复现第三列水平** | 接近基准，个别多出杂色笔触 |
| 4（只用照片 + 别对原画当风格锚） | 原片 + artwork-X | 内容对、手不对：线细、脸圆、眼大、太干净 | **明显不像** |
| 丙（照片→草图→再复刻一遍加粗） | 只用原片，两段 self-trace | 变粗变糙，但自己发明了条纹背景、改了道具 | 更「手绘」但**失真** |

三条结论：
1. **只要这一对的原画在场，第三列可以稳定复现**——这是唯一能达标的路。
2. **只有照片时无解**：抄得到画了什么，抄不到怎么画的（笔粗细、脸方度、眼睛纯度）。
3. 二次复刻加粗**不能当补救**：换来糙感，代价是构图和道具跑掉。

## 提示词骨架（第六轮实测最稳；换 `Exact content` 那一段即可）

**两张参考图，顺序不能反**：图 1 = 干净原画（target），图 2 = 原片（细节核对）。

``` 
IMAGE 1 = the artist's original drawing. IT IS THE TARGET, NOT A REFERENCE.
Reproduce it as closely as possible — same composition, same crop, same head sizes,
same poses, same hand positions, same clothing, same props, same colour areas,
same line weight, same amount of solid black, same amount of bare white paper.
Do not redesign, do not beautify, do not re-frame.
IMAGE 2 = the real photo of the couple. Use it ONLY to confirm small details that are
hard to read in image 1. Never change the composition of image 1 to match the photo.

Output: a new hand-drawn reproduction of image 1, <upright 4:5 / square-ish>, <cropped at
the chest / at the hip>, on pure white paper.
（D 这种原画有车内背景的：the frame is filled with dense diagonal hatching for the car
interior — keep it, do NOT turn it into white paper.）

Exact content to reproduce:
LEFT — <发型（直/卷、长度、刘海、绑法）+ 眼睛画法 + 表情 + 腮红/星 + 上衣 + 配饰 + 手势，逐项写>
RIGHT — <同上；一定要写手放在哪里、有没有背包带 / 手表 / 眼镜>
<小道具与原画特有的点缀：红心在哪侧、黄星、三根感叹号、比耶的大手…>
Signature bottom-right corner: small, thin, slanted handwriting "sdldyh", dark grey.

VERSION ① (default): faithful heavy wax-crayon reproduction — thick doubled black outlines
with tiny breaks, hair as one solid mass with a few white scratch lines, pale cream skin with
only two or three light hatch strokes, 45-degree hatching, high amount of solid black balanced
by lots of bare white paper. Keep the original's hand-shake and unevenness.

No readable words, no watermark, no border, no frame, no UI, no photo texture.
```

**V2 只在用户要第二版时追加，其余一字不动**：

```
VERSION ②: the SAME drawing with a softer coloured-pencil finish. Identical composition,
identical poses, identical head sizes, identical black line weight and identical white gaps —
only the colour transitions become softer and the hatching finer and more even.
Same small solid black rectangle eyes, no eyelash, no highlight.
```

**负面词（必须带）**：
`no readable words, no watermark, no border, no frame, no UI, no photo texture, no eyelash, no highlight in the eyes, no extra fingers`

## 工作流（7 步，按序别跳）

1. **配对**：一对情侣 = 一张原画 + 它自己的原片，绝不跨对混用（见第 0 步的表）。
2. **切干净原画（最容易毁一批的一步）**：从**无遮挡**的截图按像素框裁出原画，切掉「已滑屏」气泡、深灰边框、缩略图残角；再统一加白边。裁完 `read_file` 放大目检四条：无气泡 / 四边无灰边 / 两张脸完整 / 白纸边缘干净。
3. **写复刻清单**：左人、右人、小道具、背景、签名，逐项写死。**原画里有的全写，原画里没有的绝不加**。
4. **出 1 张试水**：`images=[干净原画, 原片]`，先出一张，和原画并排看——遮住签名，能不能一眼看出是同一张画的抄写。
5. **批量出 V1**：每对一张，提示词只换 `Exact content to reproduce` 段，头两段（target 声明）一字不动。
6. **四列对照验收**：`scripts/compare_v7_four.py` 拼 **原片 | 原画 | 复刻 V1 | 复刻 V2**，逐行检查姿势、手势、道具、取景。
7. **签名与交付**：放大看右下角；写坏了先重跑一次，连续两张都坏再用 Pillow 叠字（唯一允许的后期）。交付目录用中文名 `01 A 复刻① 重蜡笔.jpg`。

## 质检八查

| # | 查什么 | 不合格长什么样 | 只改这一项 |
|---|---|---|---|
| 1 | 白底 | 灰底、纸纹、场景色块 | `pure white paper, no background, no paper texture` |
| 2 | 线的「两遍」 | 单线、等宽、像矢量 | `every contour drawn twice, broken, skipping crayon line` |
| 3 | 色的「露白」 | 填满、渐变、有阴影 | `hatching stops 3-5px short of the outlines, white paper gaps` |
| 4 | 脸型 | 圆脸、尖下巴 | `wide flat square-ish face, blunt jaw` |
| 5 | 眼 | 有高光、有睫毛、变写实 | `solid black rounded rectangles, no highlights, no lashes` |
| 6 | 头发 | 一根根发丝、块内全是黑 | `one solid black block, scratched with white crayon lines` |
| 7 | 人 | 认不出是谁 / 多手指 | 逐项点名发型、服装色、配饰；手简化到 3 指或藏起来 |
| 8 | 签名 | 拼错、太大、位置错 | 重跑；仍错就叠字 |
| 9 | **和原画是不是同一张画的抄写** | 姿势、手势、道具、取景有一处对不上 | 重出该张；不能靠后期 |

## 失败模式（含 v1 实测教训）

| 现象 | 原因 | 修法 |
|---|---|---|
| **变精致二次元 / 贴纸感**（v1 翻车主因） | 模型默认走「好看」路线，且只给了文字描述 | 必须挂风格样张；全程 `rough, broken, unfinished, crayon, two passes` |
| 脸太圆、太可爱 | 只写「chibi / cute」 | 写死 `wide flat square-ish face, blunt jaw`，删掉所有「大眼 / 精致 / 漂亮」 |
| 头发一根根描 | 没写「整块」 | `one solid black block`，刘海写 `single black mass` |
| 颜色涂满、太干净 | 没写 hatching | `diagonal hatching, stops short of the outlines, grain` |
| 背景出现淡色 | 没写死纯白 | 负面词加 `no background color, no paper texture` |
| 两人画成同一张脸 | 只写了「a couple」 | 一人一句：发型 + 服装色 |
| 签名写成 `sdldyn` / 乱码 | 模型对短字母串不稳 | 重跑一次；再错就脚本叠字 |
| 人物太小 | 没写占比 | 写死 `fills about 80% of the width` |
| 手指粘连 / 多指 | Q 版手最难 | 手托脸、手放头顶这类「大块手」，或只露手背 |
| **像片不像画**（v1–v6 全程主因） | 把原画当「风格参考」，照照片重画 | 原画改成图 1 = target，照片只核对细节；提示词首行写 `IT IS THE TARGET, NOT A REFERENCE` |
| 复刻出来姿势/取景和原画不一样 | 用了原片来定构图 | `Never change the composition of image 1 to match the photo` |
| 画面里出现气泡 / 灰边 / 半张脸 | 原画参考图没切干净（A 的气泡、C/E 的顶边） | 见工作流第 2 步；裁完放大目检四条 |

## 变体（同一套骨架，只换 Output 构图句与 `Exact content to reproduce` 清单）

| 变体 | 构图 | 额外一句 |
|---|---|---|
| 双人半身（默认） | 4:5 头肩 | — |
| 方形双人 | 1:1 头肩 | `square canvas, fills 80% of the width` |
| 女生 / 男生单人头像 | 1:1 | `only the girl / only the boy, centered, 75% of the width` |
| 头贴头特写 | 4:5 | `cheeks almost touching, cropped just below the shoulders` |
| 坐姿半身 | 4:5 | `seated three-quarter bodies, cropped around the knees` |
| 纯线稿版 | 4:5 | `leave skin as bare paper; only blush and one red heart` |
| 比心 / 摸头 / 捏脸 | 4:5 | 换清单里的手势，手最多 3 指 |
| 节日版 | 3:4 | 加 `three yellow sparkles and two short exclamation marks` |
| 背影 | 4:5 | `seen from behind, holding hands, full body, no faces` |

## 附录 A：只有照片、没有原画时（已知不可靠，别当交付路径）

用户常常只给照片（对照表的第一列），希望直接画成第二列的样子。**两轮实测（各十对）都不行**，
用户的原话是「一点都不像」，那两轮的文件已被删掉。结论写在这里，避免再走一遍：

| 试过的做法 | 结果 |
|---|---|
| 照片 + 另一张原画当画风锚，只写「copy the style」 | 出来是「干净二次元 + 一点点蜡笔」，黑是细线堆的，没有原作者那种胖黑块的重量 |
| 再加一段笔触标定（线粗如一个眼睛、整块发、8–15 笔粗排线、1/3 黑 1/2 白） | 手感明显变近，但仍只有「像这个画风」，做不到「像这一张画」 |

笔触标定这段留着有用（当附加约束），原文如下：

```
STYLE — match image 2's hand exactly:
- every line is FAT and WAXY, about as wide as an eye; strokes are short, blunt,
  unevenly pressed and stop abruptly;
- outlines are drawn TWICE, with visible doubling and open gaps at the corners;
- hair is a SOLID OPAQUE BLACK MASS with only three or four white scratch lines;
- skin stays bare paper with only two to four light peach hatch strokes;
- three or four short red hatch strokes per cheek;
- clothing is 8 to 15 separate thick diagonal colour strokes with clear white gaps;
- hands and props are chunky and simplified, at most three fingers;
- about a third of the canvas is black or colour, half stays bare white paper.
If the result looks like a clean digital line drawing or a thin pen sketch, it is wrong.
```

**判断标准**：把成图缩小到 25%，还看得出「胖黑线 + 大白块」就对；变成灰糊糊一片细线就是错。

**实测对照（第一列原片 → 复刻，两版提示词）**

| 对 | 测试① 只写「copy the style」 | 测试② 再加笔触标定 | 目标（第二列原画） |
|---|---|---|---|
| A | 构图和手势对了，但**笔触轻、脸更圆**，女生的眼睛冒出睫毛线 | 黑块和胖线回来了，仍比原画干净 | 厚蜡笔、脸方、眼睛是纯黑方块 |
| B | 条纹衫/派对帽/亲脸颊/手臂上扬全对，线条偏细 | （本回合生成额度用尽，下轮补） | 同样构图但更重、更毛 |

结论：**第一列能抄到「画了什么」，抄不到「怎么画的」。** 差距集中在三处——
笔的粗细、脸的方度、眼睛的纯度。要交付，只能拿第二列原画。

**为什么照片路线注定差一截**：第一列和第二列不是同一张构图。原画的姿势、取景、手的落点、
道具位置都是画手重排过的；照照片重画，等于每一条都对不上，越认真越远。
**要交付，就必须拿到第二列那张原画。** 拿不到就先问用户要，不要硬画。

## 从截图复刻的完整链路（第六轮实测，可直接照做）

1. **切原画**：从**无遮挡**那张截图按像素框裁出成品画 → `references/artworks/clean/artwork-X.jpg`，去掉气泡 / 灰边 / 缩略图残角，统一加 18px 白边。裁完放大目检。
   参考框（1080×2400 截图坐标）：A `(120,300)-(930,1140)`、C `(140,345)-(1035,1215)`；B / D / E 原图无遮挡，直接转存。
2. **切原片**：截图里嵌的照片按像素框裁出，×3–4 LANCZOS 放大 + `UnsharpMask(2,60,2)` → `references/originals/original-X.jpg`（只做细节核对）。
3. **出图**：`images=[clean/artwork-X.jpg, originals/original-X.jpg]`，提示词按上面的骨架填（图 1 = target）。
4. **四列对照**：`../.venv/bin/python scripts/compare_v7_four.py` → `examples/compare-v7-four-columns.jpg`（1672×2350，原片 | 原画 | 复刻 V1 | 复刻 V2）。
5. **Drive**：新文件夹 `第N轮 · 照原画复刻`，文件名以 `00 四列对照` / `01…10 中文名` 开头，天然排序。

## 与其他模块的关系

- `photo-style/` 的 R03（奶油蜡笔）是**贴纸感、干净、可批量**；本技能是**手绘感、毛躁、带签名**。要「头像」用本技能，要「一套风格图」用 R03。
- 若用户要换签名，替换所有 `sdldyh` 即可，其余不动。

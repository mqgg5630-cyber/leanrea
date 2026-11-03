---
name: scribble-couple
description: 把情侣 / 单人照片「复刻成原作者那张蜡笔涂鸦原画」——复刻 V1 重蜡笔忠实版为标准交付：纯白纸、两遍抖断的黑蜡笔线、方宽脸、黑色圆角矩形眼、整块黑刘海、彩铅斜排线露白、每侧三四道腮红、一颗小红心，右下角签名 sdldyh。当用户说「照着这张原画复刻」「画成这种手绘情侣头像」「照片转涂鸦风」「要这种糙糙的蜡笔感」，或发来抖音/小红书同款手绘情侣头像截图说「就要这种」时使用。
---

# scribble-couple：原作原画 → 同款复刻（情侣涂鸦头像）

**一句话规格：把原作者那张画 1:1 复刻成白纸上的两个方脸大头人——黑蜡笔线抖着画了两遍，颜色斜着排线涂不满，右下角 `sdldyh`。**

这个风格的全部难点只有一个字：**糙**。不是「精致的可爱」，是「手抖的人拿蜡笔随手涂的可爱」。

> ⚠️ **最重要的一条（v7 定稿）：任务是「把原作者那张画复刻出来」，不是「照照片重画」。**
> 参考图顺序有语义：**图 1 = 这一对的原画（唯一目标，1:1 照抄）**，**图 2 = 这一对的原片（只用来核对细节，不许反过来改构图）**。
> 原画决定一切——姿势、取景、手势、道具、配色、用线；照片只决定「细节有没有错」。顺序反了，就会得到一张「好看但不像原作」的重画版，前六轮全部栽在这里。

## 交付标准：一版到位（v7 定稿）

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

## 提示词骨架（照原画复刻，v7 实测最稳）

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

## 笔触标定：像不像，八成看这一段（v9 定稿）

用户反复说「差别还是太大」，量出来的原因不是黑少，而是**黑是细线堆出来的**：
我们的图黑覆盖率 15–34%，和原画 15–30% 差不多，但原画的黑是**粗蜡笔块**，我们的是**细钢笔线**。
所以提示词里必须把「笔有多粗、块有多整」写死，这一段叫 `CRAYON HAND`，每张都要带：

```
STYLE — match image 2's hand exactly:
- every line is FAT and WAXY, about as wide as an eye; strokes are short, blunt,
  unevenly pressed and stop abruptly;
- outlines are drawn TWICE, with visible doubling and open gaps at the corners;
- hair is a SOLID OPAQUE BLACK MASS with only three or four white scratch lines —
  never individual strands;
- skin stays bare paper with only two to four light peach hatch strokes;
- three or four short red hatch strokes per cheek;
- clothing is 8 to 15 separate thick diagonal colour strokes with clearly visible
  white paper between them, never a smooth fill;
- hands and props are chunky and simplified, at most three fingers;
- about a third of the canvas is black or colour, half stays bare white paper.
If the result looks like a clean digital line drawing, a thin pen sketch or a smooth
illustration, it is wrong.
```

判断标准一句话：**把成图缩小到 25%，还看得出「胖黑线 + 大白块」，就是对的；变成灰色一片细线就是错的。**

**画风锚只借手，不借人。** 用 `artwork-A` 当锚时，实测所有男生的头发都变卷、都带胡子——
因为锚图里的人会被抄。所以每张必写：

```
The hair silhouette, face shape, clothes and pose come from image 1 ONLY.
Do not give anyone image 2's fluffy curly hair or image 2's clothes.
```

## 泛化：手上没有原画时怎么画（v8 / v9 实测）

新情侣只给了照片、找不到原作者那张画时，用**一张已定稿的干净原画当画风锚**：

```
images = [新照片, references/artworks/clean/artwork-A.jpg]
```

提示词第一段写清分工：`Take the PEOPLE from image 1` / `Copy ONLY its drawing technique from image 2 — do NOT copy its poses, props or background`，
然后照常列左人 / 右人 / 小道具 / 签名。

十对实测（P01–P10，见 `tests/v8/`）：**10/10 都稳稳落在这套风格里**，但整体比原作者**偏轻**——
衣服排线稀、头发的白划痕多过黑块，少数眼睛冒出小白点。批量时统一补三句：

```
denser black mass in the hair, denser clothing hatching,
no white glint inside the eyes, eyes are flat filled rectangles,
keep the two faces clearly different
```

记住定位：**这是扩量验证，不是复刻交付**。真交付永远按上面的口径——图 1 就是原画本身。

## 从截图复刻的完整链路（v7 实测，可直接照做）

1. **切原画**：从**无遮挡**那张截图按像素框裁出成品画 → `references/artworks/clean/artwork-X.jpg`，去掉气泡 / 灰边 / 缩略图残角，统一加 18px 白边。裁完放大目检。
   参考框（1080×2400 截图坐标）：A `(120,300)-(930,1140)`、C `(140,345)-(1035,1215)`；B / D / E 原图无遮挡，直接转存。
2. **切原片**：截图里嵌的照片按像素框裁出，×3–4 LANCZOS 放大 + `UnsharpMask(2,60,2)` → `references/originals/original-X.jpg`（只做细节核对）。
3. **出图**：`images=[clean/artwork-X.jpg, originals/original-X.jpg]`，提示词按上面的骨架填（图 1 = target）。
4. **四列对照**：`../.venv/bin/python scripts/compare_v7_four.py` → `examples/compare-v7-four-columns.jpg`（1672×2350，原片 | 原画 | 复刻 V1 | 复刻 V2）。
5. **Drive**：新文件夹 `第N轮 · 照原画复刻`，文件名以 `00 四列对照` / `01…10 中文名` 开头，天然排序。

## 与其他模块的关系

- `photo-style/` 的 R03（奶油蜡笔）是**贴纸感、干净、可批量**；本技能是**手绘感、毛躁、带签名**。要「头像」用本技能，要「一套风格图」用 R03。
- 若用户要换签名，替换所有 `sdldyh` 即可，其余不动。

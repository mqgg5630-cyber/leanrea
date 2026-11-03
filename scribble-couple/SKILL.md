---
name: scribble-couple
description: 把情侣 / 单人照片画成「蜡笔涂鸦手绘头像」——纯白纸、两遍抖断的黑蜡笔线、方宽脸、黑色圆角矩形眼、整块黑刘海、彩铅斜排线露白、每侧三四道腮红、一颗小红心，右下角签名 sdldyh。当用户说「画成这种手绘情侣头像」「照片转涂鸦风」「要这种糙糙的蜡笔感」「给我和对象画一张简笔」，或发来抖音/小红书同款手绘情侣头像参考图并说「就要这种」时使用。
---

# scribble-couple：照片 → 蜡笔涂鸦手绘头像

**一句话规格：白纸上两个方脸大头人，黑蜡笔线抖着画了两遍，颜色是斜着排线涂不满的，右下角有 `sdldyh`。**

这个风格的全部难点只有一个字：**糙**。不是「精致的可爱」，是「手抖的人拿蜡笔随手涂的可爱」。

> ⚠️ **最重要的一条：只写文字提示词一定失败。** 必须同时挂两张参考图——第 1 张是人物照片（保长相、发型、衣服），第 2 张是风格样张 `references/style-ref-sample.jpg`（保画风）。没挂样张，模型 100% 会滑向「干净二次元」。

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
│   ├── style-ref-sample.jpg   用户给的样子（裁自截图，永远是第 2 张参考图）
│   └── originals/             从截图 / 用户处拿到的原始照片（只读）
├── examples/out/
│   ├── 01-xxx.jpg             双人 4:5 半身
│   ├── 04-xxx.jpg             单人 1:1 头像
│   └── …
└── examples/contact-sheet.jpg 拼版（scripts/sheet.py 生成）
```

- 双人默认 **4:5 竖版**，单人头像 **1:1**，特写/坐姿 **3:4 或 4:5**。
- 背景**永远纯白纸**：不是浅灰、不是米色、不加纸纹。
- 人物占画面**宽度 75–80%**，裁到胸口（比「可爱贴纸」风占得更满）。
- 签名固定 `sdldyh`，右下角，小、斜、细，高度约画面 2–3%。

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

## 提示词骨架（双参考，一段都别删）

参考图顺序有语义：**图 1 = 照片（保人物），图 2 = 风格样张（保画风）**，并在提示词第一行写明各自作用。

```
[REF] Image 1 = the real photo of the couple (faces, hair, clothes, pose, expressions).
      Image 2 = the drawing style to copy exactly (line quality, color filling, face parts).
      Copy the STYLE of image 2, the PEOPLE of image 1.

[CANVAS] A hand-drawn wax-crayon couple doodle on pure white paper, vertical 4:5,
         half body, the pair fills about 80% of the width, cropped at the chest.

[LINE] Black wax crayon pressed unevenly; every contour drawn TWICE, wobbling and breaking,
       ends overshooting by 5-10px, corners left open; a few fine scratchy inner lines.

[FACE] Wide flat square-ish faces, blunt jaw, tiny chin. Eyes are SOLID BLACK ROUNDED
       RECTANGLES set low and far apart, no highlights, no lashes, no pupils;
       a separate thicker stroke above each eye as the upper lid.
       Brows: short thick dashes. Nose: one dot. Mouth: small open smile.

[HAIR] <按人物写：颜色 + 长度 + 刘海 + 绑法>; hair is ONE SOLID BLACK BLOCK scratched
       through with white crayon lines, bangs pressed into a single black mass, 5-10 loose
       strands flying outside the outline.

[COLOR] Rough diagonal colored-pencil hatching that stops 3-5px short of the outlines,
        white paper gaps, visible grain, uneven pressure, NO gradients, NO shading.

[BLUSH] Three or four short red hatch strokes on each cheek.

[KEEP] <服装主色块 1–2 个 + 一个配饰 + 手势 + 表情>

[ACCENT] One small red heart and one or two small yellow sparkles above their heads.

[BG] Pure white paper. No scenery, no props, no texture.

[SIGN] A small slanted handwritten signature "sdldyh" in the lower-right corner,
       thin black ink. No other text, no watermark.
```

**负面词（必须带）**：
`no background, no scenery, no gradient shading, no soft blending, no clean vector lines, no anime highlights, no eyelashes, no extra fingers, no text other than the signature`

## 工作流（7 步）

1. **收样张**：用户给的是截图而不是纯图时，先用 Pillow 按**像素框**裁出成品图（按百分比裁会切到 UI 文字和头像栏），存成 `references/style-ref-sample.jpg`。这张图后面每次出图都要挂。
2. **找原片**：截图里常嵌着照片（右下角/正文图）。同样按像素框裁，然后 **×3–4 LANCZOS 放大 + UnsharpMask(2,60,2)**，得到能看清发型的原片。裁完必须自己看一眼有没有 UI 残留。
3. **写角色卡（3 条，各一句）**：发型轮廓（刘海形状、长短、绑法）；服装主色块 + 领型；一个配饰或手势。**不要写五官细节**——方脸上只有 5 个零件，写了反而被拉回写实。
4. **出 1 张试水**：照片第 1、样张第 2。先只出 1 张，自己目检「糙度够不够、脸够不够方」。
5. **冻 prompt 出批量**：通过后把 [CANVAS] 和 [KEEP] 换成不同构图，一次出 5–9 张。同一批只改构图与手势，风格段一字不动——这样 10 张才是同一套。
6. **验收**：见下面「质检八查」。
7. **签名与交付**：放大看右下角。模型写坏了先重跑一次；连续两张都坏，改用 Pillow + 手写体叠字（唯一允许的后期）。

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

## 变体（同一套骨架，只换 [CANVAS] 与 [KEEP]）

| 变体 | 构图 | 额外一句 |
|---|---|---|
| 双人半身（默认） | 4:5 头肩 | — |
| 方形双人 | 1:1 头肩 | `square canvas, fills 80% of the width` |
| 女生 / 男生单人头像 | 1:1 | `only the girl / only the boy, centered, 75% of the width` |
| 头贴头特写 | 4:5 | `cheeks almost touching, cropped just below the shoulders` |
| 坐姿半身 | 4:5 | `seated three-quarter bodies, cropped around the knees` |
| 纯线稿版 | 4:5 | `leave skin as bare paper; only blush and one red heart` |
| 比心 / 摸头 / 捏脸 | 4:5 | 换 [KEEP] 里的手势，手最多 3 指 |
| 节日版 | 3:4 | 加 `three yellow sparkles and two short exclamation marks` |
| 背影 | 4:5 | `seen from behind, holding hands, full body, no faces` |

## 从截图复刻的完整链路（本次实测，可直接照做）

1. `PIL` 裁出成品图 → `references/style-ref-sample.jpg`（1080×790）。
2. `PIL` 裁出内嵌照片 → 放大锐化 → `references/originals/original-photo-car.jpg`（1328×1292）。
3. 出图：`images=[原片, 样张]`，提示词按上面的骨架填。
4. `python3 scripts/sheet.py out-v2` → `examples/contact-sheet-v2.jpg` 拼版。
5. Drive：截图、原片、样张、成品、拼版全部放**同一个文件夹**，文件名以 `00` / `01…10` / `99` 开头，天然排序。

## 与其他模块的关系

- `photo-style/` 的 R03（奶油蜡笔）是**贴纸感、干净、可批量**；本技能是**手绘感、毛躁、带签名**。要「头像」用本技能，要「一套风格图」用 R03。
- 若用户要换签名，替换所有 `sdldyh` 即可，其余不动。

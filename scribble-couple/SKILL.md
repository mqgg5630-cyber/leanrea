---
name: scribble-couple
description: 把情侣 / 单人照片画成「蜡笔涂鸦手绘头像」——纯白纸底、抖断的黑线、彩铅填不满的色块、黑豆眼、三道腮红、一颗小红心，右下角签名 sdldyh。当用户说「画成这种手绘情侣头像」「照片转涂鸦风」「要这种糙糙的蜡笔感」「给我和对象画一张简笔」或发来小红书/抖音同款手绘头像参考图时使用。
---

# scribble-couple：照片 → 蜡笔涂鸦手绘头像

**一句话规格：白纸上一对大头小人，黑线是抖的，颜色是涂不满的，脸只有五个零件，右下角有 `sdldyh`。**

风格的全部秘密在「不完美」：线要断、色要露白、边缘要毛。画得越干净，越不像。

## 何时用 / 何时别用

- 用：情侣 / 闺蜜 / 单人照片 → 社交头像、朋友圈配图、纪念日礼物、小红书封面。
- 用：用户拿手机截图问「这种能画吗」——先看截图里的构图，再按本技能复刻。
- 别用：要求「像本人五官」的写真（这是 Q 版，五官只剩 5 个零件）；要背景、要场景、要上色的插画。
- 别用：商用批量（先确认画风来源与授权，签名不代表版权）。

## 输出契约

```
<project>/
├── sources/            原图（只读）
├── out/
│   ├── 01-xxx.jpg      双人 4:5 半身
│   ├── 02-xxx.jpg      单人 1:1 头像
│   └── …               同一张图的不同构图
└── preview.html
```

- 双人默认 **4:5 竖版**；单人头像 **1:1**；背影/全身 **3:4 或 4:5**。
- 背景**永远是纯白**，不是浅灰、不是米色、不是纸张纹理（要的是白纸扫描感，不是手账）。
- 签名固定 `sdldyh`，右下角，小、斜、细。

## 风格 DNA（照这个画，不要自由发挥）

| 元素 | 规格 | 常见错误 |
|---|---|---|
| 线 | 黑色，粗细不匀（1000px 宽下 3–6px），抖、断、复线、线和线不接头、偶尔出头 | 画成干净等宽的二次元线 |
| 填色 | 彩铅/蜡笔平涂，**不填满**，留白色纸缝，颗粒可见，色块边缘比线内缩 1–3px | 填满、渐变、加阴影 |
| 脸型 | 宽而扁的圆，下巴短；头身比约 1 : 2.2 | 尖下巴、写实脸 |
| 眼 | 纯黑豆形/圆角方，**没有高光**，上眼睑一条更粗的线 | 加高光、加睫毛、画成动漫大眼 |
| 眉 | 粗、短、平，略八字 | 细眉、挑眉 |
| 鼻 | 一个点或一个小 v | 画鼻梁 |
| 嘴 | 小张口笑（内里淡粉）或一条弧线 | 厚涂唇、写实嘴 |
| 腮红 | 每侧 **3 条**短斜线，粉或橘，压在脸上 | 高斯模糊的红晕 |
| 头发 | 黑色实心团 + 乱飞线；棕发用圈状乱线；发缝留白 | 一丝丝描、上高光 |
| 配饰 | 只留 1–2 个（帽子、墨镜、耳机、手表），画成大色块 | 全部细节都画 |
| 点缀 | 小红心 1 个 + 黄色星星 1–3 个 + 少量短放射线 | 满屏爱心、贴纸、水印 |
| 构图 | 头部宽度占画面 65–70%，顶部留白 ~10%，裁到胸口 | 人物顶到边、全身缩得很小 |
| 签名 | `sdldyh`，右下角，高度约画面 2–3%，斜着写 | 居中、变大、加下划线、拼错 |

## 提示词骨架（双参考，别省任何一段）

参考图顺序有语义：**第 1 张是照片（保人物），第 2 张是风格样张（保画风）**，并在提示词里说明各自作用。

```
[REF] Image 1 = the photo (identities, clothing, pose, expressions).
      Image 2 = the drawing-style reference (line quality, color filling, face parts).

[CANVAS] Hand-drawn scribble portrait on pure white paper, vertical 4:5,
         head-and-shoulders, the two of them fill about 70% of the frame, generous white space.

[STYLE] Thick shaky black crayon outlines with double strokes, overshoots and small gaps;
        thin scratchy inner lines; flat crayon and colored-pencil filling that stops short of
        the outlines and leaves white paper showing through; visible pencil grain; grainy edges;
        no gradients, no soft shading, no background objects, no clean vector lines.

[FACE]  Chibi proportions, wide flat face, big head and tiny shoulders; solid black bean-shaped
        eyes with no highlights; thick short brows; tiny dot nose; small open smile;
        blush as three short diagonal colored-pencil strokes on each cheek.

[HAIR]  <按人物写：颜色 + 形状 + 乱飞线方向>

[KEEP]  <服装主色块 1–2 个 + 一个配饰 + 手里的东西 + 表情>

[ACCENT] One small red heart, two tiny yellow sparkles.

[SIGN]  A small slanted handwritten signature "sdldyh" in the lower-right corner, thin black ink.
        No other text, no watermark.
```

**负面词（必须带）**：`no background, no scenery, no gradient shading, no photorealistic rendering, no extra fingers, no text other than the signature`。

## 工作流（6 步）

1. **选图**：挑两人都睁眼、表情自然、光线平的一张。逆光剪影 / 强对比夜景转出来五官会丢。
2. **构图**：4:5 头肩（双人）或 1:1 头像（单人）。原图是全身的，先在心里裁到胸口再描述。
3. **写角色卡**（3 条）：发型轮廓（直/卷/长/短 + 刘海）、服装主色块、一个配饰或道具（相机、帽子、耳机）。只写这三条，别写五官细节——Q 版用不上。
4. **双参考出 1 张**：照片第一、风格样张第二。**先只出一张**，让用户确认「像不像我们」。
5. **验收**（见下表），通过后冻结整段 prompt 出整批。
6. **签名与交付**：放大看右下角 `sdldyh`。模型写坏了就重跑这张；连续两张都坏，就改用脚本叠字（Pillow + 手写体字体），不要让模型反复猜。

## 质检六查

| # | 查什么 | 不合格长什么样 | 只改这一项 |
|---|---|---|---|
| 1 | 白底 | 出现灰底、纸纹、场景色块 | 强化 `pure white paper, no background` |
| 2 | 线 | 线太干净、等宽、像矢量 | 加 `broken, doubled, skipping crayon line` |
| 3 | 色 | 填满、渐变、有阴影 | 加 `filling stops short of the outlines, white paper gaps` |
| 4 | 脸 | 眼有高光、脸变写实 | 写死 `solid black bean eyes, no highlights`；腮红写 `three strokes` |
| 5 | 人 | 认不出是谁 / 多了手指 | 逐项点名发型、服装、配饰；手简化或藏起来 |
| 6 | 签名 | 拼错、太大、位置错 | 重跑；或脚本叠字固定右下角 |

## 失败模式

| 现象 | 原因 | 修法 |
|---|---|---|
| 变成精致二次元插画 | 模型默认走「好看」路线 | 全程强调 `rough, broken, unfinished, crayon`；参考图必须挂风格样张 |
| 背景出现淡淡颜色 | 没写死纯白 | 负面词加 `no background color, no paper texture` |
| 两人被画成同一张脸 | 只写了「a couple」 | 分别写发型 + 服装色，一人一句 |
| 女生变网红脸 | Q 版脸上还写了「大眼睛」 | 删掉所有「美丽 / 精致 / 大眼」类词 |
| 签名写成 `sdldyn` / 乱码 | 模型对短字母串不稳 | 重跑；仍错就脚本叠字（这是唯一允许的后期） |
| 人物太小、留白太多 | 没写占比 | 写死 `fill about 70% of the frame` |
| 手指粘连 / 多指 | Q 版手最难 | 让道具挡手、手插兜、或只露手背 |

## 变体（同一套骨架，换 [CANVAS] 与 [KEEP]）

| 变体 | 构图 | 额外一句 |
|---|---|---|
| 双人半身（默认） | 4:5 头肩 | — |
| 单人头像 | 1:1 头肩 | `only the girl / only the boy, centered, 65% of the frame` |
| 背影全身 | 4:5 | `seen from behind, holding hands, full body, no faces` |
| 身高差拥抱 | 4:5 | `she hugs him, height difference kept, hands on his back` |
| 摸头 / 捏脸 | 4:5 | `his hand patting her head / her hand pinching his cheek` |
| 节日版 | 4:5 | 加 `two small party hats`，其余不变 |
| 生日 / 纪念日 | 4:5 | 点缀换成 `one small cake or one balloon`，仍只一个 |

## 与其他模块的关系

- `photo-style/` 的 R03（奶油蜡笔）是**贴纸感、干净、可批量**；本技能是**手绘感、毛躁、有签名**。用户要「头像」选本技能，要「一套图」选 R03。
- 署名 `sdldyh` 是本技能的固定签名；如果用户要自己的名字，替换 [SIGN] 里的字符串即可，其余不变。

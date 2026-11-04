---
name: healing-comic
description: 把长文 / PDF / 指南转成小红书式「一二布布」可爱治愈简笔情侣漫画套图（3:4 竖版、6–9 页、原创双角色、中文由脚本后期合成）。当用户说「把这份资料做成治愈漫画」「改成小红书一二布布那种简单的漫画」「文章转多格漫画」「把 20 张文字卡改成漫画」时使用。
---

# healing-comic：把长文压成一套可爱治愈漫画

一个 SKILL.md + 一个 Pillow 脚本，不需要 MCP、不需要排版服务、不需要把中文交给生图模型。

**核心原则：一页 = 一个动作 + 一句台词 + 两个角色。** 治愈感来自「少」，不是来自画得多。想塞进去的内容一律删掉，留到下一篇。

## 何时用 / 何时别用

- 用：长文、指南、PDF、课程笔记 → 小红书 6–9 页漫画套图；已有 20 张文字卡想换风格；想做轻 IP 连载。
- 别用：要精确数据表格、法律/医疗条款原文、需要逐字保留的长文；那种用知识卡片 skill，不要漫画化。
- 别用：需要 20 格以上连载剧情、复杂分镜、多角色换装。见 `references/github-skills.md` 里的条漫 / 小说转漫画方案。

## 输出契约

```
<project>/
├── storyboard.md          # 分镜表（人读、可改）
├── spec.json              # 排版输入（机器读）
├── art/00-cover.png …     # 无字底图，永不覆盖
└── pages/
    ├── 01.png …           # 1080×1440 成品
    ├── preview.html       # 整套预览（浏览器打开）
    └── preview.jpg        # 拼版缩略图（查缩略图可读性）
```

`art/` 是原件，`pages/` 是派生物。**绝不把文字直接画回 `art/`**，改文案只需重跑 compose.py。

## 固定视觉规格（一次定死，全套不换）

| 项 | 值 |
|---|---|
| 画布 | 1080×1440（3:4 竖版，小红书信息流最优） |
| 角色 A（一二） | 白色小熊猫：纯白圆身、**实心深棕圆耳**（没有眼罩）、小深棕椭圆眼、粉色圆腮红、**深棕蝴蝶结**、白色短手、深棕小脚 |
| 角色 B（布布） | 奶茶棕小熊：略大一圈、圆耳 + 深棕内耳、黑点眼、小鼻子、**浅黄圆腮红**；原作不戴围巾，别加 |
| 线条 | **粗深棕描边**（约 5px，#3B2314），无渐层、无阴影、无纹理。写 thin clean outlines 会出来细线版，和原帖对不上 |
| 色板（xhs-orig 版式） | 顶部黄标签 #FEE7A6、纸 #F5F1E8、白气泡 #FFFFFF、墨 #3B2314 / #301412 |
| 构图 | 角色居中偏下，**上 1/3 与下 1/4 必须留白**给标题和气泡；文字全部左对齐，共享 72px 左边线 |
| 版式 | **无页眉小标签、无页码、无装饰下划线**（eyebrow / index numbering / 装饰线，taste-skill 明令删除）；出处信息全部并入页脚 |
| 字号 | 一个超大 + 一个小：大标题 80px Medium（带奶油描边光环）、支持句 42px、台词 46px Medium（气泡内**左对齐**）、页脚 26px |
| 标题 | 大标题 ≤8 字一行；副标题 ≤14 字；台词 ≤18 字 × 最多 3 行；页脚一行 ≤36 字 |

> ⚠️ **版权**：「一二和布布」是黄小 B 于 2018 年创作的受保护 IP。本技能提供两种模式：**高相似版**（`examples/art/`，按原作特征重绘，个人笔记可用，注意署名与平台 AI 标识）与**原创版**（`examples/art-original/` 的「白团子 + 阿棕」，商用 / 长期做号请用这套）。

## 工作流（7 步，别跳步）

### 1. 选最小可用主题
不要「把整本书做成漫画」。13 章 104 条 → 一次只讲 **4–8 个点**。先问：读者看完这一套能记住哪一句？写不出这句话就换角度。
产出：一句「钩子」+ 4–8 个页码标题。

### 2. 建角色卡（一致性核心）
把上表两行**一字不差**写进每一页的生图 prompt。描述越具体越稳；「黑色圆耳、蝴蝶结、围巾」是三个识别锚点，任何一页都不能漏。
**先生成封面（同时挂 1–3 张一二布布原图做参考），后续每页挂「新封面 + 1 张原图」**，比纯文字重复描述稳得多。

### 3. 写分镜表
每页一行，字段固定：

| page | 源文出处 | 一个动作 | 顶部标题 ≤12字 | 气泡台词 ≤18字 | 底部金句 ≤24字 |
|---|---|---|---|---|---|

把原文的「判断 / 第一句 / 两种回应 / 红线 / 依据」压成「一个画面 + 一句能说出口的话」。**原文的长句只进正文配文，不进画面。**

### 4. 生图提示词（复制改 SCENE 即可）

生产实测版（**xhs-orig 双栏连载**用这一套，角色一致性最好）：

```
CHARACTER 1 (white panda cub, "Yi'er"): chubby pure-white round body and round head,
two solid very dark brown round ears on top of the head, small dark brown oval eyes,
tiny mouth, soft pink round blush cheeks, a small dark brown bow tie at the neck,
short white stubby arms, small dark brown feet.
CHARACTER 2 (milk-tea brown bear cub, "Bubu"): slightly bigger chubby milk-tea brown
round body and round head, small round ears with darker brown inner ear, small black
dot eyes, tiny nose, pale yellow round blush cheeks, short stubby limbs, no scarf,
no accessories.

Style: thick dark brown outlines, completely flat coloring, warm pastel interior
background, soft even lighting, no gradients, no shading, no texture, simple
rounded shapes, cozy warm healing mood, vertical portrait 3:4, one single
continuous scene, the illustration fills the entire frame edge to edge, no panel
borders, no white frame.

The illustration is a comic page split into TWO stacked panels separated by a
clean straight horizontal edge: the UPPER panel is bright and warmly lit, the
LOWER panel is dimmer and muted/greyish. No panel borders, no frames, no white
margin.

CRITICAL: absolutely no text, no Chinese characters, no letters, no numbers, no
captions, no speech balloons, no speech bubbles, no watermark, no logo, no signature.

SCENE: <一个动作、一个情绪、最多两个道具，写具体；双栏页要写 UPPER PANEL: … LOWER PANEL: …>
```

> 参考图挂法：**每次都挂 2–3 张原帖原图**（角色最完整的那几张），模型会连描边粗细、腮红位置一起抄；
> 只写文字不挂图，10 页里角色会漂。

海报模式（单幅、留白给标题）用这一套：

```
Use the two characters and the exact art style from the reference images
(attach 1-3 一二布布 original pictures as design reference).
CHARACTER 1 (white panda cub): small chubby pure-white round body, two solid
very dark brown round ears, small dark brown oval eyes, soft pink round blush
cheeks, a small dark brown bow tie, short white stubby arms, little dark brown feet.
CHARACTER 2 (brown bear cub): slightly bigger chubby milk-tea-brown round
body, small round ears, pale yellow round blush cheeks, small black dot eyes,
tiny nose, short stubby limbs, no scarf.
Thick dark brown outlines, completely flat coloring, plain warm-white
background, soft pastel accents, no gradients, no shading, no texture, simple
rounded shapes, cozy warm, vertical portrait 3:4, one single scene,
no panel borders.

SCENE: <一个动作、一个情绪、最多两个道具，写具体>

LARGE clean empty cream space across the top third and the bottom quarter for
later text overlay. CRITICAL: absolutely no text, no Chinese characters, no
letters, no numbers, no captions, no speech balloons, no speech bubbles,
no watermark, no logo.
```

### 5. 只生成「无字底图」
**所有中文一律不交给图片模型。** 生图模型写中文必然错字、糊字、伪字；连「123」「①」都别让它画。气泡也用脚本画，别指望模型留出可用空白。
每页一个连续画面，不要 2×2 四格（格子越多角色越容易漂移）。

### 6. 后期合成中文
```sh
python3 scripts/compose.py spec.json \
  --font ~/fonts/LXGWWenKai-Regular.ttf \
  --font-medium ~/fonts/LXGWWenKai-Medium.ttf \
  --outdir pages --html --contact-sheet   # 渲染后自动 gate：超宽/超行直接报错
```
脚本画：顶部小标签 + 大标题 + 手绘下划线 + 白色圆角气泡（带小尾巴）+ 页脚出处。自动按中文折行、字号自适应、保留 `art/` 原图。
没有中文字体时先跑 `scripts/fetch_font.sh`，或设 `COMIC_FONT=/path/to/font.ttf`。

### 7. 交付前四查 + 发布
- **缩略图查**：把 `preview.jpg` 缩到 200px 宽，标题还认得出吗？认不出就加粗加短。
- **角色查**：6 页里蝴蝶结 / 围巾 / 耳朵有没有丢？丢的那页用封面作参考重生成。
- **字数查**：台词 ≤18 字、标题 ≤20 字、配文 ≤1000 字、图片 ≤18 张（推荐 6–9 张）。
- **合规查**：勾选平台「AI 生成合成内容」标识；署名原书 + 许可证；保留原书「不是心理治疗 / 危机先转介」免责句。
  小红书 2026-02 起要求 AI 图文主动标识，未标识会限制分发（见 `references/cases.md`）。

## 版式依据（taste-skill 审校）

排版规则对照 [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)（108k★，anti-slop 设计品味 skill）逐条审过：删 eyebrow 与页码、全左对齐、一个超大一个小、无渐变无阴影无细线、标题两行以内、图片上的文字用中性描边光环（其唯一允许的例外）、渲染后用 gate 实测字宽行数（inspect 的本地等价物）。对网页规则不适用的两条按媒介惯例保留：对话气泡的描边（漫画的语义元素，不是 UI 分隔线）与气泡尾巴。

## 复刻模式（--layout xhs）

对参考帖 8 张原图先做逐像素测量再复刻：1080×1440 **满版插画**（左右底画到边缘，无白框、无页码、无页脚）、顶部 12% 干净纸条放**居中**标题（内容页 54px / 封面 76px 两行）、气泡画在画面中部 35–55% 的干净带、色板 纸 `#F5F1E8` / 蜜桃 `#F0D1C0` / 棕 `#A48476` / 墨 `#301412` / 灰蓝 `#BCCAD0`。底图生成时把参考帖原图直接挂给生图模型（最强风格锚点），提示词固定要求「顶部 12% 留白 + 35–55% 高度留干净带 + 画到四边」。合成后用同一把尺子自检：顶条亮度、四边是否满版、主色是否贴近。测量数据与自检结果见 `references/copy-复刻版-8件事.md`。

## 原帖双栏版式（--layout xhs-orig）与动态化（scripts/animatic.py）

参考帖《毁掉关系的八种做法》不止是满版插画，它有自己的一套**标签系统**：
顶部黄标签写「行为名」、上格场景里一个白色对白气泡、分界线下方一个白色标签写「其实是…」、
下格是同一件事的反差画面。`--layout xhs-orig` 就是复刻这套版式，文字层由
`scripts/artlayout.py` 统一绘制，**静态页与视频帧共用同一层**，所以图片和视频上的字一模一样。

按参考帖原图（1080×1447）实测：分界线在 y=723（正好一半）、顶部黄标签 y=34–148 底色 `#FEE7A6`、
底部白标签 y=760–882、气泡白色 + 深棕 4px 描边带小尾巴。生图模型自己会照抄原帖的两栏结构，
但**分界线位置每张都不一样**，所以 spec 里要逐页写 `seam`（比例），脚本按 `seam*1440+36` 放底部标签。

### 要视频时：animatic.py

没有文生视频模型时的可行做法，也是这套素材更好用的方式：
**一页 = 上格一个慢推镜头 + 下格一个慢推镜头 + 中间 0.5s 交叉溶解**；
画面做缓动推近（1.00×→1.30×）与轻微平移，中文作为独立图层叠在动画之上，所以**字永远清晰、不跟着缩放糊掉**。

```sh
python3 scripts/animatic.py examples/spec-anime.json \
  --font ~/.fonts/LXGWWenKai-Regular.ttf --font-medium ~/.fonts/LXGWWenKai-Medium.ttf \
  --art-root examples --outdir video --fps 25 --shot 3.0 --fade 0.5 --all
```

- 输出每页一段 MP4（1080×1440 / 25fps / H.264 / yuv420p）+ `--all` 出一段全套合集。
- 加旁白：`--audio 旁白.mp3`（ffmpeg 混流）；加 BGM 同理。
- 依赖 `imageio` + `imageio-ffmpeg`（自带 ffmpeg 二进制），不需要装系统 ffmpeg。
- 内存：写盘用 `imageio_ffmpeg.write_frames` 流式编码；合集用流式拼接，别把整段读进内存。

**边界**：这是「会呼吸的漫画」，不是逐帧生成的真实动作动画。角色 100% 不漂移、文字 0 错字，
但肢体不会真的动。想要真动作就得接视频模型，那时改提示词、角色卡、分镜表的写法都一样。

## 风格为什么好抄（一二布布类漫画的量化拆解）

| 特征 | 做法 | 省掉了什么 |
|---|---|---|
| 两个圆形角色 | 头身比 1:1，只靠耳朵 / 围巾区分 | 表情演技、人体、透视 |
| 三色平涂 | 白 + 棕 + 一个点缀色 | 上色、光影、背景绘制 |
| 一页一动作 | 不画分镜、不画时间流动 | 分镜设计、跨格连贯 |
| 一句对话 | 口语、 ≤18 字、带一点反差萌 | 旁白、论述、信息密度 |
| 情绪转折 | 前半页「我以为是…」，后半页「其实是…」 | 说教，换成被理解的感觉 |
| 大量留白 | 上 1/3 下 1/4 空着 | 排版拥挤、缩略图看不清 |

## 常见失败模式

| 现象 | 原因 | 修法 |
|---|---|---|
| 中文错字 / 糊字 / 乱码 | 让生图模型写字 | 一律无字底图 + compose.py |
| 第 3 页熊换了围巾 | 每页单独生成 | 封面作参考图 + 角色卡逐字复用 |
| 一页塞了 4 个概念 | 想保留原文结构 | 一页一个动作，其余进配文 |
| 做成 20 页文字卡 | 沿用旧素材惯性 | 砍到 6–9 页，改 3:4 竖版 |
| 缩略图看不清 | 标题 30px、字数多 | 标题 62px+、≤12 字 |
| 要商用 / 长期做号 | 高相似版有 IP 风险 | 换 `examples/art-original/` 原创版 |
| 被限流 | 未标 AI | 发布时勾选 AI 标识 |

## 一键起步

```sh
# 1) 读源文，写 storyboard.md 与 spec.json
# 2) 生成 art/00-cover.png（用上面的 prompt，SCENE 换成封面场景）
# 3) 其余每页把 00-cover.png 作为参考图，SCENE 换成分镜表里的「一个动作」
# 4) 合成
python3 scripts/compose.py spec.json --font "$COMIC_FONT" \
  --outdir pages --html --contact-sheet
# 5) 打开 pages/preview.html 做四查
```

完整调研、案例、逐页改造方案与 3.7 整套文案设计见 `references/`；已做好的样张见 `examples/`。

## 内容拆解方法：把长指南拆成「一批十张」的连载漫画

给长指南（13 章 104 条这种）做连载时，先拆内容再画图，别边读边画。完整方法见
[`references/文案拆解方法.md`](references/文案拆解方法.md)，这里是最小可用版：

1. **先建内容地图**：原书 → 章节清单 → 每批 10 页对应 1–2 章；先确认「别人已经做过哪几章」，避免撞车。
2. **一页三层文字**（比单气泡更适合「引导型 / 教育型」内容）：
   - 顶部黄标签＝**标签**（≤8 字，点题分类）
   - 上格白气泡＝**触句**（≤20 字，带着委屈或试探的那一方）
   - 底部白标签＝**点题句**（≤12 字，本页结论）
   - 下格白气泡＝**引导句**（≤20 字，不指责、给选择权的那一方）
3. **每页标源文**：章节号 + 用到的手册字段（判断 / 第一句 / 两种回应 / 接着做 / 做对了 / 红线）。
   能核对到原文的句子逐字引用，核对不到的按原书结构改写——**并把这件事写进文档**，不要装作是原文。
4. **台词必须和画面里谁在做哪件事对上**：文案说布布在收画笔，图就得是布布在收画笔。
   对不上就改文案或改图，二选一，不要各说各话。
5. **气泡别压脸**：生图提示词里让人物偏下 / 偏侧，气泡落在墙面、地面或人物腿上；
   人物居中时把下格气泡放到 `y≈1200`（身体以下）。

### 双气泡版式（`--layout xhs-orig` 的 `bubbles` 字段）

```json
"bubbles": [
  {"text": "我不敢说不想。", "y": 190,  "align": "left",  "tail": "left", "tail_dir": "down"},
  {"text": "那是我越界了。", "y": 1200, "align": "right", "tail": "left", "tail_dir": "up"}
]
```

| 字段 | 取值 | 作用 |
|---|---|---|
| `text` | ≤20 字 | 气泡台词，超 20 字 compose 的 gate 会直接报错 |
| `y` | 0–1440 | `< seam`（默认 720）画在上格，`≥ seam` 画在下格 |
| `align` | `left` / `right` / `center` | 气泡横向位置，对应说话人站位 |
| `tail` | `left` / `right` / `center` | 尾巴在哪一侧 |
| `tail_dir` | `up` / `down` | 尾巴朝上还是朝下（人物在上格就朝下，在下格就朝上） |

一页最多 2 个气泡；`y` 与 `tail_dir` 要跟画面里人物的位置对上，否则像贴纸。

### 十张一批的流水线

```sh
# 1) 写文案：references/anime2-批A-漫画文案.md 是可抄的模板（逐页表 + 源文映射表）
# 2) 写 spec：examples/spec-anime2-A.json（批A）/ spec-anime2-B.json（批B）
# 3) 生图：art/ 每页一张无字底图，挂 原图01 + 原图04（+ 原图02）当参考
# 4) 合成
python3 scripts/compose.py spec-anime2-A.json \
  --font ~/.fonts/LXGWWenKai-Regular.ttf --font-medium ~/.fonts/LXGWWenKai-Medium.ttf \
  --art-root . --outdir pages-A --layout xhs-orig --html --contact-sheet
# 5) 拼版 + 上传：2 列拼版 → Drive 目录；文案 md / 提示词 md 一起传
```

**平台额度注意**：生图模型一般限制「每次回复最多 10 张」，所以一个批次正好 10 张，
一批做完再开下一轮，别在一轮里硬凑 20 张。

## references 索引

| 文件 | 用途 |
|---|---|
| `文案拆解方法.md` | ⭐ 把长指南拆成十张一批的完整方法 + 自检清单 |
| `anime2-批A-漫画文案.md` | 批A《先分清：引导还是控制》逐页文案 + 源文映射表 |
| `anime2-批B-漫画文案.md` | 批B《体面放手》逐页文案 + 源文映射表 |
| `anime2-批A-生图提示词.md` / `anime2-批B-生图提示词.md` | 两批共 20 页的成品提示词（角色卡 + 画风 + 分格 + 禁字 + SCENE） |
| `anime2-批C-漫画文案.md` | 批C《亲密的节奏》逐页文案 + 源文映射表（第 8 章 8.1–8.8） |
| `anime2-批C-生图提示词.md` | 批C 10 页成品提示词 |
| `anime2-批D-漫画文案.md` | 批D《提问、选择、留白》逐页文案 + 源文映射表（第 6 章 6.1–6.8） |
| `anime2-批D-生图提示词.md` | 批D 10 页成品提示词 |
| `anime2-交付说明.md` | 四批 40 张的交付清单与 Drive 位置 |
| `会话与交付记录.md` | ⭐ 本次对话链接 + 继续做下一批的完整步骤 + 沙箱重建备忘 |
| `anime-分镜表.md` / `anime-生图提示词.md` / `anime-发布清单.md` / `anime-说明.md` | v1.1「引导型恋人·亲密日常」7 页图文 + 8 段视频的做法 |
| `copy-复刻版-8件事.md` | 参考帖 8 张原图逐像素测量 + 9 页复刻文案 |
| `copy-3.7-承诺要小而可兑现.md` | 3.7 承诺篇 3 页文案设计 |
| `conversion-plan.md` / `cases.md` / `github-skills.md` | 逐页改造方案、案例库、GitHub skills 调研 |


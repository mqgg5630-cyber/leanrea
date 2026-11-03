# 可复制的提示词（v2）

规则：**图 1 = 照片，图 2 = 风格样张**（`style-ref-sample.jpg`）。顺序反了，风格会压掉人物；**缺了样张，一定滑向干净二次元**。

所有提示词都用英文——模型对「笔触 / 材质」的英文词最敏感；中文只用来跟用户沟通。

---

## 0. 公共块（每条都要带，一字不改）

```
[REF] Image 1 = the real photo of the couple (faces, hair, clothes, pose, expressions).
      Image 2 = the drawing style to copy exactly (line quality, color filling, face parts).
      Copy the STYLE of image 2, the PEOPLE of image 1.

[LINE] Black wax crayon pressed unevenly; every contour drawn TWICE, wobbling and breaking,
       ends overshooting by 5-10px, corners left open; a few fine scratchy inner lines.

[FACE] Wide flat square-ish faces, blunt jaw, tiny chin. Eyes are SOLID BLACK ROUNDED
       RECTANGLES set low and far apart, no highlights, no lashes, no pupils;
       a separate thicker stroke above each eye as the upper lid.
       Brows: short thick dashes. Nose: one dot. Mouth: small open smile.

[HAIR] Hair is ONE SOLID BLACK BLOCK scratched through with white crayon lines, bangs
       pressed into a single black mass, 5-10 loose strands flying outside the outline.

[COLOR] Rough diagonal colored-pencil hatching that stops 3-5px short of the outlines,
        white paper gaps, visible grain, uneven pressure, NO gradients, NO shading.

[BLUSH] Three or four short red hatch strokes on each cheek.

[BG] Pure white paper. No scenery, no props, no texture.

[SIGN] A small slanted handwritten signature "sdldyh" in the lower-right corner, thin black
       ink. No other text, no watermark.

[NEGATIVE] no background, no scenery, no gradient shading, no soft blending, no clean vector
       lines, no anime highlights, no eyelashes, no extra fingers, no text other than the
       signature
```

**为什么 [LINE] 要写 `TWICE`**：v1 只写 `shaky doubled lines`，模型给了单层直线，出来像矢量贴纸。写成「every contour drawn TWICE」后每次都能稳定出复线。

---

## 1. 双人半身（默认，4:5）

```
Canvas: vertical 4:5, half body, the pair fills about 80% of the width, cropped at the chest.

[STYLE] …（复制公共块）

[KEEP] she wears <女生主色 + 单品>, <她的发型/绑法>, <配饰>; he wears <男生主色 + 单品>,
       <他的发型>, <配饰>; <两人的手势>; <表情>.
```

## 2. 方形双人（1:1）

```
Canvas: square 1:1, head-and-shoulders, the pair fills about 80% of the width,
        heads slightly above center.
```
其余同 1。

## 3. 单人（1:1）

```
Canvas: square 1:1, only the <girl / boy>, head-and-shoulders, centered, 75% of the width.
[HAIR] <长度 + 刘海 + 绑法>, loose strands flying outward.
[KEEP] <服装 1 个主色块>, <配饰 1 个>, <真实表情>.
[ACCENT] One tiny red heart at the upper right.
```
单人时把公共块里的「faces / their」改成单数，其余不动。

## 4. 头贴头特写（4:5）

```
Canvas: vertical 4:5, tight crop: their two heads lean together, cheeks almost touching,
        filling about 80% of the width, cropped just below the shoulders.
[ACCENT] One small red heart between their heads.
```

## 5. 坐姿半身（4:5）

```
Canvas: vertical 4:5, seated three-quarter bodies, cropped around the knees.
Keep their seated posture and the hand relationship from the photo;
do NOT draw the seat, the car interior or any scenery — pure white paper only.
```

## 6. 纯线稿版（4:5）

```
Canvas: vertical 4:5, half body, the pair fills about 75% of the width.
Keep the same line quality, but leave the skin as bare white paper:
only three short red blush strokes per cheek and one small red heart.
Hair and clothing are built from dense rough black scribble, not filled color.
```

## 7. 摸头 / 捏脸 / 比心

```
Extra line: his hand rests flat on top of his own head (or her hand touches her cheek /
she makes a small finger heart).
Hands stay simplified: three fingers maximum, big flat shapes, or hidden behind the other person.
```
手是这套风格里最容易崩的部位——优先选原图里本来就有的「大块手」（托脸、放头顶），不要凭空加手指。

## 8. 背影（4:5）

```
Canvas: vertical 4:5, full body, seen from behind, holding hands.
Keep their silhouettes, height difference and clothing colors. No faces needed.
Pure white paper only — do not paint the scenery.
```

---

## 9. 常见微调（只改一句，不要整段重写）

| 问题 | 加这一句 |
|---|---|
| 太干净、像贴纸 | `rougher: broken doubled crayon line, visible white gaps between strokes, uneven pressure` |
| 填色太满 | `hatching stops 3-5px short of the outlines, lots of white paper showing` |
| 脸太圆 / 太可爱 | `wider flatter square-ish face, blunt jaw, features smaller and further apart` |
| 眼太动漫 | `eyes are solid black rounded rectangles, no highlights, no lashes, no pupils` |
| 头发一根根 | `hair is one solid black block scratched with white crayon lines, bangs a single mass` |
| 出现背景色 | `background is pure white paper, nothing else, no texture, no vignette` |
| 人太小 | `the couple fills about 80% of the width, heads in the upper third` |
| 手崩 | `hands simplified or hidden, no visible fingers` |
| 签名写坏 | 重跑一次；连续两次坏 → 用下面的脚本叠字（唯一允许的后期） |

## 10. 签名兜底脚本（可选）

```python
from PIL import Image, ImageDraw, ImageFont

def sign(path, font_path, text="sdldyh"):
    im = Image.open(path).convert("RGB")
    d = ImageDraw.Draw(im)
    size = max(18, int(im.height * 0.028))
    f = ImageFont.truetype(font_path, size)
    w, h = im.size
    d.text((w * 0.86, h * 0.93), text, font=f, fill=(20, 20, 20))
    im.save(path, quality=92)
```

字体用任意手写体即可（`healing-comic/scripts/fetch_font.sh` 里的霞鹜文楷能凑合，但连笔感不如手写体）。

## 11. 从截图复刻时的两个 Pillow 片段

```python
# ① 裁出成品图当风格样张（按像素框，别用百分比）
Image.open(shot).crop((0, 330, 1080, 1120)).save("references/style-ref-sample.jpg", quality=92)

# ② 裁出截图里内嵌的原始照片并放大锐化
from PIL import ImageFilter
photo = Image.open(shot).crop((730, 1425, 1062, 1748))          # 332×323 的纯照片区
photo = photo.resize((photo.width * 4, photo.height * 4), Image.LANCZOS)
photo = photo.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
photo.save("references/originals/original-photo-car.jpg", quality=92)
```

裁完一定打开看一眼：截图里的头像栏、评论、播放按钮很容易被一起裁进来。

---

## 12. 逐对复刻版（v3，推荐用这个）

一份抖音截图里同时有「成品画」和「评论区的原片」，但它们分属不同情侣。**做哪一对，就把那一对的两张图一起挂上**：

| 对 | 图 1（内容） | 图 2（风格） | 一句话角色卡 |
|---|---|---|---|
| A | `originals/original-A.jpg` | `artworks/artwork-A.jpg` | 卷发男生 + 长直发齐刘海女生，白 T，双肩包，男生手托自己下巴 |
| B | `originals/original-B.jpg` | `artworks/artwork-B.jpg` | 蓝白条纹衫，绿/粉派对帽，男生凑过去亲女生脸，一手伸出去 |
| C | `originals/original-C.jpg` | `artworks/artwork-C.jpg` | 黄棒球帽女生比耶，白 T 带棕色格纹图案；黑 T 卷发男生从背后抱 |
| D | `originals/original-D.jpg` | `artworks/artwork-D.jpg` | 车内，双麻花辫 + 头顶墨镜 + 串珠手链；藏青 POLO，wink，手放头顶 |

模板（把 `<对>` 和 `[KEEP]` 换掉，其余照抄）：

```
[REF] Image 1 = the real photo of this couple. Image 2 = the artist's own drawing of this
      SAME couple — copy its style exactly (line quality, face construction, eyes,
      hair treatment, color filling). Copy the STYLE of image 2, the PEOPLE of image 1.

[CANVAS] Hand-drawn wax-crayon couple doodle on pure white paper, <vertical 4:5 / square 1:1>,
         <half body / tight close-up / three-quarter bodies>, the pair fills about <80-85>% of the width.

[LINE] …  [FACE] …  [HAIR] …  [COLOR] …  [BLUSH] …   （同第 0 节公共块）

[KEEP] <从角色卡里抄：发型 + 服装 + 配饰 + 手势 + 表情>
[ACCENT] <一颗红心 / 加 1-2 颗黄星 / 加两道黄射线>
[BG] Pure white paper — do NOT draw <卧室/街道/车内>，重要：截图里的场景一律不画。
```

**B 对要额外加一句**：`the stripes drawn as loose skipping blue bands that break and skip`（否则条纹会被画成规整的商品图）。

## 13. 软彩铅版（D 对的原画就是这种）

同一张脸型系统，但整体更柔、更暖、更「画」而不是「涂」：

```
LINE:  wax crayon / soft pencil pressed unevenly, contours drawn twice, wobbling,
       sometimes breaking, ends overshooting; thin scratchy inner lines.
FACE:  wide flat square-ish face, blunt jaw, tiny chin; eyes solid black rounded rectangles
       with only a small white gap for light, no lashes; short thick brow dashes;
       one dot nose; small closed smile (or a wink).
COLOR: smooth-but-visible colored-pencil strokes, warm peach skin with a slightly deeper
       tone on the shadow side, navy filled in loose diagonal strokes, no gradients.
BG:    white paper with a few loose grey and brown crayon strokes hinting at <车座>, nothing more.
```

对比：重蜡笔版是「黑块 + 露白 + 抖线」；软彩铅版是「细线 + 暖色铺满 + 一笔阴影」。**两版不要混在同一批里**。

## 14. 「每对两个版本」的做法（v4）

同一对出两版时，**只换质感段，[KEEP] 一字不改**，否则会变成两个不同的人。

| | 版本① 重蜡笔 | 版本② 软彩铅 |
|---|---|---|
| 线 | `thick black wax crayon, every contour drawn TWICE, broken, ends overshooting 5-10px` | `soft pencil / thin crayon, contours drawn twice, gently wobbling, mostly closed` |
| 脸 | 纸白皮肤 + 3-4 道腮红短线 | `smooth warm peach skin, a slightly deeper tone on the shadow side` |
| 眼 | 实心黑圆角矩形，无高光 | 同样形状，但留一点小白缝 |
| 色 | `rough diagonal hatching stopping 3-5px short of the outlines, white paper gaps` | `smooth-but-visible colored-pencil strokes, no black outlines everywhere, no harsh contrast` |
| 背景 | 纯白 | 纯白（最多几笔同色暗示） |

一句话口诀：**版本① 靠「破」，版本② 靠「润」**。用户说「要和原图一样好看」时，通常指版本②——它更接近大众审美的完成度，而版本①更像手账涂鸦。

## 15. 三图参考：把「上一版」也挂上（v5 修法）

用户说「你新出的没上一版好看」时，最快的修法不是改词，而是**把上一版当第三张参考图挂上去**，并在提示词里写死「对齐它的密度与完成度」。

```
[REF] Image 1 = the real photo of this couple.
      Image 2 = the artist's original drawing of this SAME couple.
      Image 3 = an earlier rendering of the SAME couple that the client approved:
      match its DENSITY, CONTRAST and FINISH — the same amount of solid black,
      the same amount of bare white paper, the same head size and framing.
      Use the style of image 2 and the finish of image 3, the people of image 1.
```

**v4 为什么变丑（诊断，别再犯）**

| 我做的 | 后果 |
|---|---|
| 把「软彩铅」理解成「线变细、大部分闭合」 | 结构线消失 → 掉进通用可爱插画 |
| 皮肤写成「暖蜜桃铺满」 | 丢掉纸白露白 → 手绘感没了 |
| 头发从「整块黑 + 白划痕」改成「浅棕细线」 | 视觉重量掉了 |
| 没写 `keep the structure` | 模型把「soft」理解成「什么都弱一点」 |

**修正后的两版定义**

- 版本① 重蜡笔：**黑更多**（线更粗更断、发块更整、衣纹更密），皮肤**更白**（只留几笔浅排线）。
- 版本② 软彩铅：软在**颜色过渡**，不软在结构——线仍然两遍、仍然黑；皮肤暖但要看得见笔触和白缝；头发仍是深色重块。

一句话：**「软」只允许软在颜色，不允许软在线和黑。**

---

## §16 参考图必须先切干净（v6 硬规则，顺序不可调）

v6 的偏差不是提示词问题，是**参考图本身坏了**：喂给生成器的「原作者原画」里有
聊天软件的「已滑屏」气泡、深灰截图边框、被缩略图压掉的半张脸。模型会把这些当成
画面内容一起复刻，于是整批都偏。

**三条硬规则**

1. **先切，再喂。** 每轮开始前把 `references/artworks/clean/artwork-X.jpg` 更新一遍：
   裁掉气泡/UI/边框/滚动条，只留白纸上的画。裁完必须 `read_file` 放大目检。
2. **切干净的原画单独归档。** 干净版放 `references/artworks/clean/`，不要覆盖原截图；
   原始截图留 `references/user-screenshots/` 作为溯源。
3. **三图参考一起喂，缺一不可：**
   - 图 1 = 真实原片（决定人、动作、服装、构图）
   - 图 2 = 干净原画（决定风格：线宽、黑量、白纸比例、头部大小、眼睛画法）
   - 图 3 = 上一轮客户认可的成图（只用于密度与取景，不要夺风格）

提示词第一段就写清三张图各是什么，并明确 `Image 2 … uncropped and unobstructed —
ground truth for the style`。少一张，或图 2 有遮挡，偏差一定会回来。

**裁切参考（1080×2400 截图坐标）**

| 对 | 无遮挡来源 | 裁切框 | 输出 |
|---|---|---|---|
| A | `shot-0330713`（这张无气泡） | (120,300)-(930,1140) | 810×840 |
| C | `shot-0345802` | (140,345)-(1035,1215) | 895×870 |
| B / D / E | 原图本身无遮挡 | — | 直接转存 |

**目检清单（4 条，任一不过就重切）**：无半透明气泡；四边无灰/黑边框；两只脸都完整；
白纸边缘干净、没有 UI 按钮残角。

**A 对特别提示**：T 恤上的字母在原画里本来就是涂鸦，模型会写成 `404 OME` 这类乱码。
只要它是**小面积手写涂鸦**就算合格；若变成大段可读文字，重出该张。

---

## §17 任务是「复刻原画」，不是「照照片重画」（v7，最重要的口径）

前六轮一直搞错的就是这一条。用户要的不是「用原画当风格、照原片重画一遍」，
而是**把原作者那张画（对照表第二列）本身复刻出来，一届复刻两版**。

- **图 1 = 原画 = 目标（target）**，不是 style reference。提示词第一行必须写：
  `IMAGE 1 = the artist's original drawing. IT IS THE TARGET, NOT A REFERENCE.
  Reproduce it as closely as possible — same composition, same crop, same head sizes,
  same poses, same hand positions, same clothing, same props, same colour areas,
  same line weight, same amount of solid black, same amount of bare white paper.`
- **图 2 = 原片 = 只用来核对细节**：`Use it ONLY to confirm small details that are hard to
  read in image 1. Never change the composition of image 1 to match the photo.`
- 提示词里把原画逐项写成 `Exact content to reproduce:` 清单（左人 / 右人 / 小道具 /
  背景 / 签名），**不要留「自由发挥」的空间**。
- 构图不许改：原画裁到胸就裁到胸，原画裁到胯就裁到胯，原画有车内背景就保留车内背景
  （D 不是纯白纸，别自作聪明改成白底）。

**两版怎么分**

| 版本 | 定义 | 只改什么 |
|---|---|---|
| ① 重蜡笔 | 最贴原画的忠实复刻 | 什么都不改：厚双勾线、发块整、纸白多 |
| ② 软彩铅 | 同一张画，更细的彩铅收尾 | 只改颜色过渡和排线疏密；**构图/姿势/头身比/黑线粗细/留白全部不动** |

**翻车点**：说「softer」时模型会顺手把眼睛改成带睫毛高光的动漫眼（C② 就这样），
这已经是改结构。提示词要补：`same small solid black rectangle eyes, no eyelash, no highlight`。

**验收**：把复刻图和原画并排放，遮住签名，能否一眼看出是同一张画的两次抄写。
不能，就重出。

---

## §18 泛化测试（新照片 + 老画风锚，v8 十对实测）

手上没有新情侣的原画时，用**已定稿的一张干净原画当画风锚**：
`images=[新照片, references/artworks/clean/artwork-A.jpg]`。
提示词要把「抄什么」写死，否则模型会连锚图的人一起抄：

```
IMAGE 1 = the real photo of a couple. Take the PEOPLE from it: faces, hair, clothes,
expressions, and the gesture (phone in his raised hand).
IMAGE 2 = the artist's original wax-crayon drawing. Copy ONLY its drawing technique:
line weight, face construction, hair-as-one-black-block, solid black rectangle eyes,
45-degree hatching that stops short of the outlines, bare white paper, the small slanted
"sdldyh" signature. Do NOT copy image 2's poses, props or background.
```

十对（P01–P10）实测结论：

| 观察 | 结论 |
|---|---|
| 10/10 都落在这套风格里，脸型/眼/发块/白纸稳定 | 画风锚有效，可以放心用来扩量 |
| 整体比原画**偏轻**：衣服排线稀、头发的白划痕多过黑块 | 每张都要补 `denser black mass in the hair, denser clothing hatching` |
| 少数图的眼睛出现小白点/小弧线（高光、睫毛） | 补 `no white glint inside the eyes, eyes are flat filled rectangles` |
| 深色外套（P09）容易糊成一片、两张脸趋同 | 一人一句写清发型差异 + `keep the two faces clearly different` |
| 手部（P07 拿刀、P06 牵手）容易退化成「握着个小方块」 | 道具只写形状不写细节；手最多三指；拿不准就改成空手 |

**这一档的定位**：这是「扩量验证」，不是「复刻交付」。真交付仍按 §17：图 1 = 原画目标。

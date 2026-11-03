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

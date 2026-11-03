# 可复制的提示词

规则：**图 1 = 照片，图 2 = 风格样张**（`style-ref-sample.jpg`）。顺序反了，风格会压掉人物。
所有示例都是英文——模型对英文的「材质/笔触」词更敏感；中文只用来跟用户沟通。

---

## 0. 公共块（每条都要带）

```
[STYLE]
Hand-drawn scribble portrait on pure white paper, no background.
Thick shaky black crayon outlines with double strokes, overshoots and small gaps;
thin scratchy inner lines; flat crayon and colored-pencil filling that stops short of the
outlines leaving white paper showing through; visible pencil grain; grainy uneven edges;
no gradients, no soft shading, no clean vector lines.

[FACE]
Chibi proportions, wide flat face, big head and tiny shoulders; solid black bean-shaped
eyes with no highlights; thick short flat brows; tiny dot nose; small open smile with a
hint of pink; blush as three short diagonal colored-pencil strokes on each cheek.

[SIGN]
A small slanted handwritten signature "sdldyh" in the lower-right corner, thin black ink.
No other text, no watermark.

[NEGATIVE]
no background, no scenery, no paper texture, no gradient shading, no photorealistic
rendering, no detailed eyelashes, no extra fingers, no text other than the signature
```

---

## 1. 双人半身（默认，4:5）

```
Image 1 is the photo: keep the two people's hairstyles, clothing colors, accessories,
relative position and height difference.
Image 2 is the drawing-style reference: match its line quality and color filling exactly.

Canvas: vertical 4:5, head-and-shoulders, the two of them fill about 70% of the frame,
generous white space, heads slightly above center.

[STYLE] …（复制公共块）

[KEEP] she wears <主色> <单品>; he wears <主色> <单品>; <道具>; <表情/动作>.

[ACCENT] One small red heart between them, two tiny yellow sparkles.

[SIGN] …（复制公共块）
```

## 2. 单人头像（1:1）

```
Canvas: square 1:1, only the <girl/boy>, head-and-shoulders, centered, about 65% of the frame.

[HAIR] <长发黑直 / 短发 / 卷发>，发梢乱飞线朝外。
[KEEP] <服装 1 个主色块>，<配饰 1 个>，<真实的表情>。
[ACCENT] One tiny red heart at the upper right.
```

## 3. 背影全身（4:5）

```
Canvas: vertical 4:5, full body, seen from behind, holding hands, walking.
Keep their silhouettes, height difference, her flowing dress and his jacket.
No faces needed. Pure white paper only — do not paint the scenery they are standing in.
[ACCENT] One small red heart floating between their heads.
```

## 4. 摸头 / 捏脸 / 拥抱

```
Extra line: his hand pats her head (or her hand pinches his cheek / she hugs him)。
Hands stay simplified: three fingers maximum, or hidden behind the other person.
注意：手是这套风格里最容易崩的部位，能藏就藏。
```

---

## 5. 常见微调（只改一句，不要整段重写）

| 问题 | 加这一句 |
|---|---|
| 太干净、像矢量 | `rougher, more broken and doubled lines, visible white gaps between strokes` |
| 填色太满 | `color filling stops 2-3px short of the outlines, lots of white paper showing` |
| 出现背景色 | `background is pure white paper, nothing else, no texture` |
| 脸太写实 | `flatter wider face, smaller features, eyes are solid black beans with no highlights` |
| 人太小 | `the couple fills about 70% of the frame, heads near the top third` |
| 手崩 | `hands simplified or hidden, no visible fingers` |
| 签名写坏 | 重跑；连续两次坏 → 用脚本在右下角叠 `sdldyh`（唯一允许的后期） |

## 6. 签名兜底脚本（可选）

模型把 `sdldyh` 写错时，用 Pillow 在右下角叠一层手写体：

```python
from PIL import Image, ImageDraw, ImageFont

def sign(path, font_path, text="sdldyh"):
    im = Image.open(path).convert("RGB")
    d = ImageDraw.Draw(im)
    size = max(18, int(im.height * 0.028))
    f = ImageFont.truetype(font_path, size)
    w, h = im.size
    # 右下角，留 7% 边距，整体略斜（先渲染再旋转也行，这里只做平铺）
    d.text((w * 0.86, h * 0.93), text, font=f, fill=(20, 20, 20))
    im.save(path, quality=92)
```

字体用任意手写体即可（本仓库 `healing-comic/scripts/fetch_font.sh` 下的霞鹜文楷也能凑合，但连笔感不如手写体）。

# 生图提示词（本次实际使用）

## 怎么保证角色「一模一样」

三招叠着用，缺一不可：

1. **挂原帖原图当参考**。每次调用都挂 `原图01.png` / `原图04.png`（角色最完整的两张）。
   模型会连同描边粗细、平涂方式、腮红位置一起抄。
2. **角色卡逐字复用**。下面这段 CHARACTER 描述 7 页一字不改——黑圆耳、蝴蝶结、奶白口鼻是三个识别锚点。
3. **统一画风约束**。粗深棕描边、纯平涂、暖色室内、满版出血、无渐变无阴影。

> 一开始只写「thin clean outlines」会出来细线版本，和原帖的粗描边对不上；
> 一定要写 **thick dark brown outlines**。

## 角色卡（每页原样复制）

```
CHARACTER 1 (white panda cub, "一二"): chubby pure-white round body and round head,
two solid very dark brown round ears, small dark brown oval eyes, tiny mouth,
soft pink round blush cheeks, a small dark brown bow tie at the neck, short white
stubby arms, small dark brown feet.
CHARACTER 2 (milk-tea brown bear cub, "布布"): slightly bigger chubby milk-tea brown
round body and round head, small round ears with darker brown inner ear, small black
dot eyes, tiny nose, pale yellow round blush cheeks, short stubby limbs, no scarf.
```

## 画风约束（每页原样复制）

```
Style: thick dark brown outlines, completely flat coloring, warm pastel interior
background, soft even lighting, no gradients, no shading, no texture, simple
rounded shapes, cozy warm healing mood, vertical portrait 3:4, one single
continuous scene, the illustration fills the entire frame edge to edge, no panel
borders, no white frame.
```

多格页额外加：

```
The illustration is a comic page split into TWO stacked panels separated by a
clean straight horizontal edge: the UPPER panel is bright and warmly lit, the
LOWER panel is dimmer and muted/greyish. No panel borders, no frames, no white
margin.
```

## 禁字（每页原样复制）

```
CRITICAL: absolutely no text, no Chinese characters, no letters, no numbers, no
captions, no speech balloons, no speech bubbles, no watermark, no logo, no signature.
```

中文一律交给 `compose.py` / `animatic.py` 后期合成，生图阶段一个字都不给模型。

## 逐页 SCENE

| 页 | SCENE（英文原句） |
|---|---|
| 01 封面 | At night by a big window, the two cubs sit close together on the floor sharing one big soft blanket over their legs; a steaming cup of tea on the floor beside them; the white panda cub leans a little toward the brown bear cub with a small gentle smile; the bear cub sits relaxed and content, eyes softly closed; moonlight coming through the window; full body, front view. |
| 02 不查手机 | Cozy living room in daylight. The white panda cub stands and gently places a smartphone face down on the wooden coffee table, one paw on top of it. The brown bear cub stands beside, looking at the phone, then looking up at the panda with a calm trusting face. A soft sofa and a small lamp in the background. Full body, front view. |
| 03 先问再说 | The brown bear cub sits at a low wooden table drawing on a sheet of white paper with a pencil. The white panda cub stands beside the table holding out another pencil with both paws, head tilted, as if politely asking first. A potted plant and a framed picture in the background. Full body, front view. |
| 04 互相照顾 | UPPER PANEL: The two cubs sit on the floor sharing one big knitted blanket; the white panda cub lifts one corner of the blanket with both paws and drapes it over the brown bear cub's shoulders; the bear smiles with closed eyes; two mugs of cocoa beside them. LOWER PANEL: The white panda cub alone on the floor hugging the remaining corner of the blanket tightly, knees up, looking a little sad and cold; the brown bear cub walks away in the background with its back turned, out of focus and simple. |
| 05 先接住情绪 | UPPER PANEL: Dim cozy bedroom at night, one warm lamp. The white panda cub sits on the floor with head slightly lowered, looking tired and sad, paws in its lap. The brown bear cub sits quietly right next to it, not asking anything, just being there, one paw resting gently near the panda's paw. LOWER PANEL: The same dim room; the brown bear cub stands over the white panda cub with hands on hips, mouth open and brows furrowed, lecturing; the panda cowers slightly, ears low, looking overwhelmed. |
| 06 并肩不代替 | UPPER PANEL: Bright sunny kitchen. The two cubs stand side by side at the counter washing dishes together, each holding one plate and a cloth, both smiling, shoulder to shoulder, plants on the windowsill. LOWER PANEL: The same dim kitchen; the white panda cub alone at the counter doing everything at once, arms full of dishes, with a big pile of dishes stacked high in front of it, looking exhausted and overwhelmed; the brown bear cub stands behind the doorway watching with a worried face, arms down, not helping. |
| 07 结尾 | Night time on a wide windowsill. The two cubs sit side by side looking out at a big moon and a few stars. The white panda cub rests its head gently on the brown bear cub's shoulder; the bear cub sits upright and relaxed, smiling softly. A small potted plant and a mug on the windowsill. Full body, front view, calm peaceful ending mood. |

## 参考图挂法

```
images = [原图01.png, 原图04.png]      # 角色锚点，两张就够，挂多了会稀释
```

## 底图尺寸

模型这次返回 **896×1200**（3:4），脚本统一 `ImageOps.fit` 到 1080×1440 输出。

## 已知坑

- 挂原图当参考会让模型**自动照抄原帖的两格分栏**——本次要的正是这个；
  但如果只想要单幅画面，必须在 SCENE 里写「one single continuous scene」并说明不要分格。
- 封面（单幅）不要写 split into two panels，否则会出现空的下格。

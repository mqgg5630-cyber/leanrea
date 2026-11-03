---
name: photo-style
description: 把用户给的一张照片转成指定画风（日系动漫赛璐璐 / 吉卜力治愈 / 奶油蜡笔软萌 / 3D 黏土盲盒 / 透明水彩 / 撕纸拼贴 / 新海诚夜景 / 日系胶片），保住构图、人物身份和背景物件。当用户说「把这张照片变成动漫风」「照片转吉卜力」「这张图换成黏土/手绘/水彩风格」「给我做一套同风格头像」「宠物照片做成贴纸」时使用。
---

# photo-style：一张照片 → 一种画风，别的不许变

**核心原则：先保真，再画风。** 用户给的是一张有意义的记忆，不是一张待重绘的素材。任何"顺手美化"（换背景、加花、改天气、磨皮、把人画成另一个人）都是失败，不是创意。

## 何时用 / 何时别用

- 用：把已有照片转成画风做头像 / 封面 / 贴纸 / 情侣图 / 一整套同风格图；把 healing-comic 需要的场景底图照片化。
- 别用：要"生成一个图画"（那是生图，不是转绘）；要修图去路人/换衣服（那是编辑，不是风格化）；要保留精确中文（文字一律脚本画，见 healing-comic）。
- 别用：证件照、需要人脸识别的场合、医疗/证据类图像。

## 输出契约

```
<project>/
├── sources/            # 原图，只读，永不覆盖
├── out/<style-id>/*.jpg  # 每种画风一个目录，文件名与 source 同名
├── test-log.md         # 每张图一行：原图 × 风格 = 通过 / 重跑原因
└── preview.html        # 原图与成品并排（浏览器打开）
```

`out/` 是派生物。改风格只重跑，不动 `sources/`。

## 四轴约束（写提示词前先写这四行）

| 轴 | 必须写死的内容 | 漏写的后果 |
|---|---|---|
| 构图 | 机位、裁切、主体在画面中的位置与占比、原始宽高比 | 模型自动"重新构图"，人物被挪到中间、背景被裁 |
| 身份 | 脸型、眼睛形状、发际线与刘海分缝、发色、服装颜色与版型、宠物花纹/记号 | 出来一个"同风格的路人" |
| 物件 | 背景里必须留下的 2–4 样东西（门、窗、杯子、招牌、家具）及其左右关系 | 背景被换成樱花、蓝天、纯色棚 |
| 禁忌 | 不要文字、不要水印、不要多手多指、不要磨皮、不要加原图没有的物体 | 招牌乱码、脸变塑料、凭空多出一个花瓶 |

## 强度三档（默认 M）

| 档 | 提示词写法 | 用在 |
|---|---|---|
| L 轻 | `restyle only color, light and surface texture; keep shapes photographic` | 人像、要"还是本人"、日系胶片 |
| M 中（默认） | `rebuild as <style> while keeping composition and identity` | 绝大多数 |
| H 重 | `fully repaint in <style>, allow stylized proportions` | 头像、贴纸、宠物、封面 |

**规则：人像默认 L/M，宠物和食物才敢用 H。** H 档要求用户明确同意"可以画成 Q 版"。

## 提示词骨架（三段，永不省）

```
[PREFIX]
Use the supplied photo as the base. Keep the exact composition, camera angle, crop,
subject pose and proportions, and the recognizable identity of the subject (face shape,
hairstyle, clothing colors, distinctive markings). Do not add, remove or move major
objects. Preserve the original aspect ratio.

[STYLE BLOCK]        ← references/style-recipes.md 里 R01–R16 任选一条，整段复制

[SUFFIX]
No text, no letters, no watermark, no extra limbs, no deformed hands, no plastic skin.
```

多用图参考时**顺序有语义**：第 1 张永远是用户原图；第 2、3 张只能是风格图，并且要在提示词里说明各自贡献什么（`reference 2 defines the palette, reference 3 defines the line weight`）。顺序错了，风格图会盖掉原图的主体。

## 工作流（6 步）

1. **读图**，写 5 行 Scene Card：主体 / 必须留下的物件 / 主导光线与色温 / 安静区（留给文字或留白）/ 语义最小集（少到什么程度还认得出这张照片）。
2. **选风格**：按 `style-recipes.md` 末尾的「选风格速查」选 1 个，不要一次给 5 个。用户没主意就用 R08（日系胶片）或 R02（吉卜力）——这两个几乎不会翻车。
3. **写提示词**：PREFIX + STYLE BLOCK + SUFFIX，把 Scene Card 的"必须留下"塞进 PREFIX。
4. **先出 1 张**，让用户验收；不要直接批量。验收通过后，**这段 prompt 一字不改**地用于整批（要更稳就同时固定 seed / 参考图顺序）。
5. **质检**（见下表），不过就只修坏的那一项，不要整段重写。
6. **交付**：`sources/` + `out/<style>/` + 一页 `preview.html`（原图与成品并排），并注明哪张是 H 档 Q 版、哪张不建议商用。

## 质检六查（一张一张过）

| # | 查什么 | 不合格的表现 | 只改这一项的办法 |
|---|---|---|---|
| 1 | 构图 | 主体被挪动、裁掉、放大 | PREFIX 加 `identical framing, same distance from camera` |
| 2 | 身份 | 脸/发型/服装/花纹变了 | 逐项点名特征；必要时挂 1 张原图 + 1 张同风格成品做双参考 |
| 3 | 物件 | 背景少了东西或被替换 | 列出物件清单与左右关系 |
| 4 | 手与肢体 | 六指、断手、多余手臂 | SUFFIX 加 `hands hidden or simple, five fingers maximum` |
| 5 | 文字 | 出现乱码、假字、水印 | SUFFIX 强化 `signs are abstract shapes, no readable characters` |
| 6 | 画风纯度 | 只是加滤镜 / 风格混着两种 | 把 STYLE BLOCK 收紧到 4–6 个锚点，删掉互相冲突的词 |

**"差不多"不算通过。** 第 2 项（身份）不过就重跑，不要交付。

## 批量一致（一套图 / 连载 / 店铺）

- 同一个 STYLE BLOCK 字符串，不改一个词。
- 同一个参考图列表与顺序，同一个 seed（模型支持时）。
- 同一档强度。同批里混 L 和 H，出来的图会像两个人做的。
- 每批先出 1 张"标板"，后面所有图与标板比对，不与"记忆里的风格"比对。

## 双人 / 情侣额外三条

1. **写死身高差与体型差**：`keep their exact height difference and body types`。不写，模型会把两人画得更"般配"，高矮差被抹平。
2. **写死肢体位置**：`keep the original pose and limb positions exactly, no added arms`。实测中韩系厚涂自动给女生加了一条搂腰的手臂。
3. **配饰是身份锚点**：眼镜、帽子、痣、纹身、耳环逐项点名。实测 6 张情侣图里 5 张保住了墨镜，唯一丢掉的是黏土版（变成色块）。

**情侣头像两种做法**：① 同框转（氛围统一，裁成头像后只剩半个人）；② **分头转**（推荐）——两人各裁 1:1，用同一段 STYLE BLOCK、同一档强度分别转，再拼成一对，风格与脸都能对上。

## 风格菜单由用户拍板

`references/style-scorecard.md` 记录了每种风格的 5 维评分与去留建议。用户说"不好看"就是不好看，不要争：把该风格从默认菜单移到 `archive/`，配方保留但不再主动推荐。

## 失败模式

| 现象 | 根因 | 修法 |
|---|---|---|
| 整张图被重画，原图信息全丢 | 只写了 STYLE BLOCK，没写 PREFIX | 补四轴约束；降到 L/M 档 |
| 人脸变成通用二次元脸 | 只写"anime style"这种大类词 | 点名脸型/眼型/刘海；用 R01 而不是"anime" |
| 背景变樱花/蓝天/纯色 | 没列物件清单 | PREFIX 写 `keep the door on the left, the window on the right` |
| 食物看起来不能吃 | 风格词太"插画" | 加 `appetizing, keep food colors warm and saturated` |
| 夜景招牌全是乱码字 | 模型在画字 | 明说 `signs are abstract glowing shapes`，真有文案就用脚本后期叠 |
| 一批图风格不一致 | 每张 prompt 都"顺手改一点" | 冻结 prompt + 参考图顺序 + seed |
| 皮肤像塑料 | `beautiful, flawless skin` 这类词 | 换 `keep skin texture and pores, no smoothing` |

## 与其他模块的配合

- **healing-comic**：照片先用本技能转成 R03 / R02 画风，作为漫画封面或场景底图；文字仍由 `compose.py` 合成，绝不让生图模型写字。
- **只想要"好看"**：不要走生成模型，直接用调色（ffmpeg 那套），零幻觉、可批量、可回退。

风格库与调研来源见 `references/style-recipes.md`、`references/github-skills.md`；实测与评分见 `references/test-log.md`、`references/style-scorecard.md`。

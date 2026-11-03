# photo-style · 照片转风格（治愈 / 好看 / 动漫可爱向）

> 一个 `SKILL.md` + 一份 16 条风格配方 + 一组实测样张。
> 目标很窄：**同一张照片，换画风，别的不许变。**
> 与 `healing-comic/` 同思路：不装 MCP、不依赖第三方账号，提示词纪律 + 一张对照表就能交付。

## 目录

```
photo-style/
├── SKILL.md                        技能本体：四轴约束、强度三档、6 步工作流、质检六查、失败模式
├── README.md                       本文件
├── references/
│   ├── github-skills.md            ⭐ GitHub 上「照片→风格」skills 全景调研（30+ 组关键词，逐个读源码）
│   ├── style-recipes.md            ⭐ 17 条风格配方（13 条已实测 + 4 条备选），可直接复制的 prompt
│   ├── style-scorecard.md          ⭐ 5 维评分 + 去留决策表 + 情侣专章（拍板用）
│   └── test-log.md                 6 类照片 × 8 种画风的 20 张逐张评分
├── scripts/
│   └── gallery.py                  扫 out/ 目录 → contact-sheet.jpg + preview.html（只依赖 Pillow）
└── examples/
    ├── sources/                    10 张原图：人像 / 宠物 / 食物 / 风景 / 夜景 / 情侣 ×3 / 中国情侣
    ├── out/<style-id>/             成品，文件名与 source 一致
    ├── contact-sheet.jpg           全风格拼版
    ├── batch-10-couple-cn.jpg      ⭐ 中国情侣 × 10 风格单张对照（batch_sheet.py 生成）
    └── preview.html                原图与成品并排预览
```

## 结论先说

1. **GitHub 上没有一个高星的「照片转画风」skill。** 高星的是风格库（`yang0/handraw-style` 6.9k★、`wuyoscar/GPT-Image2-Skill` 6.0k★）；真正写清楚"怎么保住人脸和构图"的反而是 1–12★ 的小仓库（`beatra-ai/photo-to-anime-skill`、`xiaoou-waou/zhaopianfengge-skill`）。详见 [references/github-skills.md](references/github-skills.md)。
2. **画风靠配方，不靠装包。** 9 条实测配方覆盖了治愈 / 可爱 / 动漫的主流需求，复制就能用：[references/style-recipes.md](references/style-recipes.md)。
3. **人像是最难的，材质类画风一定会换脸。** 同一张人像在赛璐璐/水彩下还能认出本人，在黏土下就变成通用玩偶。要保人像就选 L/M 档的二维画风。详见 [references/test-log.md](references/test-log.md)。

## 实测结果（30 张，7 类题材 × 13 种画风）

| 画风 | 人像 | 猫 | 食物 | 风景 | 夜景 | 情侣 | 决策 |
|---|:--:|:--:|:--:|:--:|:--:|:--:|---|
| R01 动漫赛璐璐 | ✅ | ✅✅ | — | — | — | ✅ | ✅ 主力 |
| R02 吉卜力 | ✅ | ✅ | — | ✅✅ | — | ✅ | ✅ 主力 |
| R03 奶油蜡笔 | 待测 | ✅✅ | ✅ | — | — | ✅（手糊） | ✅ 贴纸向 |
| R04 3D 黏土 | ✅（换脸） | ✅✅ | ✅ | — | — | ✅（换脸） | 🟡 仅宠物/食物 |
| R05 水彩 | ✅ | — | — | ✅✅ | — | ✅ | ✅ 主力 |
| R06 撕纸拼贴 | — | — | ✅（文字泄漏） | — | — | — | 🔧 修配方 |
| R07 新海诚夜景 | — | — | — | — | ✅（伪字） | — | 🟡 仅夜景 |
| R11 韩系厚涂 | — | — | — | — | — | ✅✅（最漂亮） | 🟡 情侣/头像 |
| R08 日系胶片 | — | — | — | — | — | — | ⏳ 待测 |

评分维度（颜值 / 保真 / 纯度 / 稳定 / 好上手）与"保留哪几种"的决策表：[references/style-scorecard.md](references/style-scorecard.md)

拼版：[examples/contact-sheet.jpg](examples/contact-sheet.jpg) · 交互预览：[examples/preview.html](examples/preview.html)

## 上手

```sh
# 全仓库唯一的硬依赖
python3 -m venv .venv && .venv/bin/pip install Pillow

# 重出拼版与 HTML 预览（新增成品后随时重跑）
.venv/bin/python photo-style/scripts/gallery.py
```

转一张照片的流程（给 agent 或自己用）：

1. 按 `SKILL.md` 写 5 行 Scene Card（主体 / 必留物件 / 光色 / 安静区 / 语义最小集）。
2. 从 `style-recipes.md` 选 1 条 STYLE BLOCK，套 PREFIX / SUFFIX。
3. 先出 1 张验收，再冻结 prompt 批量。
4. 用「质检六查」逐张过，身份不过就重跑，不交付。

## 适合谁

- 想把生活照做成一套同风格头像 / 贴纸 / 封面的人。
- 想给公众号、小红书、漫画（`healing-comic/`）配统一画风场景图的人。
- 想评估"哪个模型/哪条 prompt 更保真"的人：`test-log.md` 的评分表就是模板。

## 不做的事

- 不做"生成一张图"（那是生图，不是转绘）。
- 不做一键批量 API 流水线（各家接口不同，本仓库只提供与模型无关的提示词层）。
- 不让生图模型写字：招牌、标题、对白一律脚本后期合成（同 `healing-comic/`）。

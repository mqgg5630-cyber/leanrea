# healing-comic · 把长文 / 指南转成「一二布布」式治愈漫画

> 一个 `SKILL.md` + 两个只依赖 Pillow 的脚本，把长文 / PDF / 指南压成可爱治愈漫画：
> 单篇 6–9 页，或**连载式「一批十张」**。中文永远由脚本后期合成，生图模型一个字都不写。
> 延续本仓库 `leanrea/` 的思路：不装 MCP、不加几百个工具、不依赖第三方服务。

## 目录

```
healing-comic/
├── SKILL.md                 单文件技能：规格、7 步工作流、提示词模板、双气泡版式、失败模式
├── README.md                本文件
├── 说明.md                  已交付成品的清单与位置
├── references/
│   ├── 文案拆解方法.md       ⭐ 把长指南拆成「一批十张」的完整方法 + 六查清单
│   ├── anime2-批A-漫画文案.md    批A《先分清：引导还是控制》逐页文案 + 源文映射表
│   ├── anime2-批B-漫画文案.md    批B《体面放手》逐页文案 + 源文映射表
│   ├── anime2-批A-生图提示词.md   批A 10 页成品提示词（角色卡 + 画风 + 分格 + 禁字 + SCENE）
│   ├── anime2-批B-生图提示词.md   批B 10 页成品提示词
│   ├── anime2-批C-漫画文案.md    批C《亲密的节奏》逐页文案 + 源文映射表
│   ├── anime2-批C-生图提示词.md   批C 10 页成品提示词
│   ├── anime2-交付说明.md         三批 30 张的交付清单与 Drive 位置
│   ├── 会话与交付记录.md          ⭐ 本次对话链接 + 继续做下一批的完整步骤 + 环境备忘
│   ├── anime-分镜表.md / anime-生图提示词.md / anime-发布清单.md / anime-说明.md
│   ├── copy-复刻版-8件事.md / copy-3.7-承诺要小而可兑现.md
│   └── conversion-plan.md / cases.md / github-skills.md
├── examples/
│   ├── storyboard.md            6 页分镜表 + 可复制的生图提示词
│   ├── spec.json                排版输入（海报版）
│   ├── spec-xhs8.json           参考帖 8 张原图复刻（满版版式）
│   ├── spec-anime.json          v1.1 动态化 7 页（图文 → 短视频）
│   ├── spec-anime2-A.json       ⭐ 批A 10 页（双气泡）
│   ├── spec-anime2-B.json       ⭐ 批B 10 页（双气泡）
│   ├── spec-anime2-C.json       ⭐ 批C 10 页（双气泡）
│   └── pages*/                  样张成品 + preview.html + preview.jpg
└── scripts/
    ├── compose.py               无字底图 + spec → 成品页（Pillow；折行 / 气泡 / 预览 / gate）
    ├── artlayout.py             原帖标签系统 + 双气泡文字层（静态页与视频帧共用）
    ├── animatic.py              一页两镜 + 交叉溶解 → MP4（可选旁白 / 合集）
    └── fetch_font.sh            下载霞鹜文楷（SIL OFL 1.1）
```

## 三种产出模式

| 模式 | 命令 | 产物 | 适合 |
|---|---|---|---|
| 海报版 | `compose.py spec.json --layout poster` | 1080×1440 竖版卡片 | 单篇科普，6–9 页 |
| 原帖复刻版 | `compose.py spec.json --layout xhs-orig` | 顶部黄标签 + 画面内气泡 + 底部白标签 | 连载，一批十张 |
| 动态化 | `animatic.py spec-anime.json --all` | 每页 MP4 + 全套合集 | 把已做好的漫画变成短视频 |

`--layout xhs-orig` 支持**双气泡**：上格放「触句」、下格放「引导句」，一问一答形成翻页节奏（参数见 SKILL.md）。

## 上手

```sh
python3 -m venv venv && ./venv/bin/pip install Pillow      # 唯一硬依赖
bash scripts/fetch_font.sh                                  # 或自备任意中文 .ttf/.ttc
./venv/bin/python scripts/compose.py examples/spec-anime2-A.json \
  --font ~/.fonts/LXGWWenKai-Regular.ttf --font-medium ~/.fonts/LXGWWenKai-Medium.ttf \
  --art-root . --outdir pages-A --layout xhs-orig --html --contact-sheet
```

换文案只改 spec 重跑即可，`art/` 原图不动。

## 已交付的成品

| 批次 | 内容 | 位置 |
|---|---|---|
| v1.1 动态化 | 引导型恋人「亲密日常」7 页图文 + 8 段视频 + 旁白 | Drive `亲密动画_引导型恋人_一二布布风_2026-11-02/` |
| v1.2 批A | 《先分清：引导还是控制》（第 11 章）10 张 | Drive `引导型恋人_十连漫画_布布引导_AIPaint_2026-11-02/批A_先分清引导和控制/` |
| v1.2 批B | 《体面放手》（第 12–13 章）10 张 | Drive `引导型恋人_十连漫画_布布引导_AIPaint_2026-11-02/批B_体面放手/` |
| v1.2 批C | 《亲密的节奏》（第 8 章）10 张 | Drive `引导型恋人_十连漫画_布布引导_AIPaint_2026-11-02/批C_亲密的节奏/` |

## 找回这次对话

- 对话链接：https://arena.ai/agent/01a19c32-252f-711f-87ba-e0bb7c8f4dad
- 完整交付清单 / 下一批怎么做 / 环境备忘：[`references/会话与交付记录.md`](references/会话与交付记录.md)

## 三条硬规则

1. **中文永远不由生图模型写**：所有字都由 `compose.py` 后期合成，避免错字糊字。
2. **封面先出，后续页拿它当参考图**：蝴蝶结 / 耳朵 / 腮红才不会漂。
3. **发布时勾选 AI 生成合成内容标识**：小红书 2026-02 起要求；同时保留原书署名与免责条款。

## 版权与许可

- 本目录文字与代码沿用仓库 MIT；示例画面为 AI 生成，仅作风格演示。
- 「一二和布布」是黄小 B 的受保护 IP：本技能提供**高相似版**（个人笔记可用，注意署名与 AI 标识）
  与**原创版**（`examples/art-original/` 的「白团子 + 阿棕」，商用 / 长期做号用这套）。
- 源书《引导型恋人指南》正文 CC BY 4.0；字体霞鹜文楷 SIL OFL 1.1。

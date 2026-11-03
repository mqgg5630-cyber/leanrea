# 引导型恋人 · 亲密日常（一二布布风）｜图片 + 视频

生成日期：2026-11-02　｜　分支：`arena/7c8f4dad-leanrea`　｜　技能：`healing-comic`（+ 新增 `scripts/animatic.py`）

## 这是什么

把小红书参考帖《毁掉关系的八种做法》的**原版式**（顶部黄标签 + 上格场景 + 对白气泡 + 底部「其实是…」白标签 + 下格反差场景），
连同**同一对角色（一二 = 白色小熊猫 / 布布 = 奶茶棕小熊）**一起搬过来，
但把主题内容从「毁掉关系的做法」换成《引导型恋人指南 v1.1.0》的**亲密日常**。

- **图片**：7 张 1080×1440 竖版成品（小红书图文可直接发）
- **视频**：7 段 1080×1440 / 25fps / H.264 短视频（每段 6.5 秒）+ 1 段 44.6 秒全套合集

## 用了哪个 skill

GitHub 上同系列仓库 `hukeying85-ux/leanrea` 分支 `arena/ed6c462d-leanrea` 里的 **`healing-comic`** 技能
（长文 → 小红书「一二布布」治愈漫画：一个 SKILL.md + 一个 Pillow 排版脚本，不装 MCP、不依赖第三方服务）。

本次在它上面补了两件事，并已同步回本仓库 `mqgg5630-cyber/leanrea`：

1. `scripts/artlayout.py`（新）——原帖版式的文字层：顶部黄标签 `#FEE7A6` 药丸、底部白标签药丸、白色对白气泡。
   静态页和视频帧共用这一层，**图片和视频上的字完全一致**。
2. `scripts/animatic.py`（新）——把无字底图变成短视频：一页 = 上格一个慢推镜头 + 下格一个慢推镜头 + 中间交叉溶解；
   文字层单独合成在动画之上，所以**字永远清晰，不会跟着缩放糊掉**。

## 为什么视频是「镜头 + 溶解」而不是扩散模型逐帧生成

本机没有文生视频模型可用（沙箱只放行 GitHub / PyPI / npm），所以走的是可控、可复现的路线：
AI 生成**关键帧插画** → 脚本做**推镜 / 平移 / 交叉溶解** → ffmpeg 编码。
好处是角色 100% 不漂移、字不会错、能一键重跑；代价是它更像「会呼吸的漫画」，不是逐帧生成的真实动作动画。

## 目录

| 文件 | 内容 |
|---|---|
| `00_说明.md` | 本文件：怎么做的、怎么复现、版权与合规 |
| `01_分镜表_亲密日常.md` | 7 页逐页分镜（画面 / 标签 / 台词 / 对应指南章节） |
| `02_生图提示词.md` | 实际用的完整提示词 + 角色卡 + 分界线测量值 |
| `03_发布清单.md` | 小红书发布前必查项（AI 标识 / 署名 / 标题 / 话题） |
| `图片/` | 7 张成品页 + `预览拼版.jpg` |
| `视频/` | 7 段短片 + `00-全套合集.mp4` |

## 复现

```sh
# 依赖：Pillow + imageio + imageio-ffmpeg；中文字体用霞鹜文楷（SIL OFL 1.1）
python3 -m pip install Pillow imageio imageio-ffmpeg
bash scripts/fetch_font.sh            # 或自行准备任意中文 .ttf/.ttc

# 1) 静态成品页
python3 scripts/compose.py examples/spec-anime.json \
  --font ~/.fonts/LXGWWenKai-Regular.ttf \
  --font-medium ~/.fonts/LXGWWenKai-Medium.ttf \
  --art-root examples --outdir pages --html --contact-sheet

# 2) 短视频（每页一段 + 全套合集）
python3 scripts/animatic.py examples/spec-anime.json \
  --font ~/.fonts/LXGWWenKai-Regular.ttf \
  --font-medium ~/.fonts/LXGWWenKai-Medium.ttf \
  --art-root examples --outdir video --fps 25 --shot 3.0 --fade 0.5 --all
```

底图（`examples/art-anime/*.png`）不在本仓库里（体积大、可由提示词重生成）；
`examples/spec-anime.json` 是唯一的排版输入，改字只改它。

## 版权与合规（发布前必读）

- **角色**：「一二和布布」是黄小B 的受保护 IP。本套是**按原作特征重绘的高相似版**，
  适合自己发着玩的笔记；**商用、印周边、长期做号请换原创角色**（技能里 `examples/art-original/` 就是原创的「白团子 + 阿棕」）。
- **文案**：主题内容取自《引导型恋人指南 v1.1.0》（正文标注 **CC BY 4.0**）。改写需署名「《引导型恋人指南》v1.1.0」并保留许可证与原书免责句
  （本套对应原书四条底线：同意可撤回 / 不改造人格 / 不代替专业帮助 / 不监控不试探）。
- **平台**：小红书 2026-02 起要求 AI 生成图文主动勾选「AI 生成合成内容」标识，未标识会限制分发。
- **免责**：原书不是心理治疗；危机 / 成瘾 / 自伤场景先转介专业帮助。

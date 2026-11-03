# GitHub 上「照片 → 风格化」Skills 全景调研

调研时间：2026-11-02 / 2026-11-03（两次）。方法：`gh search repos` 跑了 30+ 组中英文关键词（style transfer skill、photo to anime、图片风格 转换、照片转绘、插画 skill、滤镜 skill、image editing skill、image prompt library…，均按 star 排序），再用 `gh api repos/.../contents/SKILL.md` 逐个读源码与目录结构。star 数为查询当日 GitHub API 返回值。

## 结论先说

1. **"照片转风格"这个赛道在 skills 生态里还很小。** 最相关的几个仓库都是 1–12★（`beatra-ai/photo-to-anime-skill` 8★、`xiaoou-waou/zhaopianfengge-skill` 12★）。真正高星的是**风格库 / 提示词库**（`yang0/handraw-style` 6.9k★、`wuyoscar/GPT-Image2-Skill` 6.0k★），不是转换流水线。
2. **高星技能大多不带模型。** 它们要么是「查风格编号 + 拼提示词」（handraw），要么是「调你自己的 Gemini/OpenAI key」（bananahub、gemini-image-skill）。所以**转换质量取决于底层模型 + 提示词纪律，不取决于装哪个 skill**。
3. **工程上最值得抄的是三件事**：① 参考图排序（原图第一、风格图第二三，并说明各自贡献什么）；② 强度三档（light / scene / full redraw）而不是一个"变风格"开关；③ 输出保真核对表（脸、手、文字、logo、构图）。这三条比任何 prompt 词都重要。
4. **治愈 / 好看 / 动漫可爱**这一类没有现成 skill 打包，但风格配方可以从 `handraw-style` 的 367 种编号里直接点名（FB 经典绘本、FD 日本当代插画、FG 动漫赛璐璐、FF 黏土毛毡），再套本仓库 `style-recipes.md` 的骨架即可。

## 一、最相关：照片 → 指定画风的 skills

| 仓库 | ★ | 它到底做什么 | 可借鉴 | 问题 |
|---|---|---|---|---|
| [beatra-ai/photo-to-anime-skill](https://github.com/beatra-ai/photo-to-anime-skill) | 8 | `ai-photo-restyler`：一张照片 → anime / manga / cartoon / watercolor / clay / 3D，人物宠物商品保持可辨认；一整套图复用同一个 look | ⭐⭐⭐ **规格写得最专业**：必保留项（must-keeps）清单、参考图排序（原图第一，最多 3 张风格图，并说明每张贡献调色/线宽/明暗）、`seed` 固定整批一致、先出 1 张再批量、"drift review ≠ 精确保真"的诚实表述 | 绑 Beatra 付费 API，必须装它的 MCP client；无法本地跑 |
| [xiaoou-waou/zhaopianfengge-skill](https://github.com/xiaoou-waou/zhaopianfengge-skill) | 12 | 照片 → 3:5 撕纸拼贴 zine 海报：真景锚定 + 抽象插画场 + 一个高饱和色当结构 + 手撕纸边 | ⭐⭐⭐ 唯一的"单风格做到极致"：Scene Card（主体 / 空间不变量 / 主导手势 / 视觉重量图 / 语义最小集）先读图再写 prompt；"删细节优先于加装饰"；隐私条款（不保存、不外传原图）写进 skill | 只出海报，不做多风格；成品依赖生图模型排版文字，中文易翻车 |
| [Bucket 里另一个日系：bkgz-photo-jp-decorator](https://github.com/Buckkkk/bkgz-photo-jp-decorator) | 8 | 照片 → 日系拍立得：白边 + 竖排明朝体日文 + 手写小字 | ⭐⭐ **文字交给脚本画、不交给模型**（`scripts/render_instant_photo.py`），与本仓库 healing-comic 同一原则；边框/字号确定性生成 | 只做拍立得一种版式 |
| [ekkojiang/zelda-screenshot-transfer](https://github.com/ekkojiang/zelda-screenshot-transfer) | 92 | 现实照片 →《塞尔达》实机截图风格 + 转绘工作流 | ⭐ 单一 IP 画风的完整配方（世界观、光照、UI 元素如何保留）；同法可做"吉卜力化""新海诚化" | 绑定任天堂 IP，商用别碰 |
| [lzhandcyx/photo-to-ink-painting-skill](https://github.com/lzhandcyx/photo-to-ink-painting-skill) | 3 | 照片 → 横版中国水墨，按题材自动选大师（张大千 / 吴冠中 / 齐白石） | ⭐⭐ **内容感知选风格**：先判主体与情绪，再决定画法与留白；HARD RULES 置顶（不加原文没有的景物、不写字、不盖章） | 单一画种 |
| [moskoo/xxg-portrait-rebuild-light](https://github.com/moskoo/xxg-portrait-rebuild-light) | 223 | 人像重打光：主光/补光/阴影/背景氛围 + 修复干净通透的皮肤微质感 | ⭐⭐ 人像类最高星。它不做画风，但**「先重打光再谈风格」**的顺序对人像风格化同样成立；皮肤质感描述词可直接复用 | 不是风格转换；面向真人写真 |
| [wzj52501/aesthetic-atelier](https://github.com/wzj52501/aesthetic-atelier) | 1 | 两个子技能：情侣配对头像 + 单图风格迁移；带回归 demo 集（riso / newsprint 等） | ⭐ 带 `demo/` 原图 + 成品对照，这是评估风格稳定性的正确做法（本仓库测试也是这么做的） | 文档薄，star 低 |
| [Wmy0416/NiuLai-style](https://github.com/Wmy0416/NiuLai-style) | 1 | 把主体重建为"乡村低成本 CGI"怪异画风，保姿态/剪影/构图/身份锚点，三档强度 light / scene / uncanny | ⭐⭐ **强度三档**的写法值得抄：light=只换调色与质感，scene=换场景画法，uncanny=整体重绘但仍保身份 | 画风非常小众，非治愈向 |
| [petercjl/cloud-hug-style-transfer](https://github.com/petercjl/cloud-hug-style-transfer) | 0 | 云朵抱抱品牌风格迁移（Codex / SealSeek 用） | 品牌一致性的做法：固定色板 + 固定笔触 + 固定构图模板 | 品牌专用，未开源模型路径 |
| [alphaparkinc/genpark-neural-avatar-anime-stylization-filter-skill](https://github.com/alphaparkinc/genpark-neural-avatar-anime-stylization-filter-skill) | 8 | 头像 → 动漫滤镜（AI Mirror 式），带 `mcp_server.py` / `client.py` | 传统"滤镜式"路线（人脸对齐 + 风格化），与生成式重绘是两条路 | 需要自建服务 |

## 二、高星风格库 / 提示词库（查"有哪些风格"用这些）

| 仓库 | ★ | 内容 | 怎么用 |
|---|---|---|---|
| [yang0/handraw-style](https://github.com/yang0/handraw-style) | 6.9k | **367 种手绘风格编号图鉴**（FA 社论幽默 / FB 经典绘本 66 种 / FC 现代平面 / FD 日本当代插画 42 种 / FE 新国风 / FF 3D 黏土毛毡 / FG 动漫赛璐璐 / FH 实验 / FI 写实摄影），每种带英文名、参考作者、核心特征 + 预览图 | 直接报编号；治愈可爱优先看 FB / FD / FG / FF。本仓库 `style-recipes.md` 的 R03/R04/R05/R09 就是从这几组拆出来的 |
| [wuyoscar/GPT-Image2-Skill](https://github.com/wuyoscar/GPT-Image2-Skill) | 6.0k | GPT Image 2/2.5 提示词画廊 + agent skill + CLI，`docs/anime-manga/` 等按题材分类的成品图 | 找"这个模型能出到什么程度"的基准；`anime-manga` 一组可当动漫风的验收线 |
| [PicoTrex/Awesome-Nano-Banana-images](https://github.com/PicoTrex/Awesome-Nano-Banana-images) | 24k | Nano Banana 玩图案例合集（含大量风格迁移前后对照） | 想看"同一张图 N 种风格"的灵感库；star 最高但只是案例集，不是 skill |
| [yokel1121/muyang-illustration-skills](https://github.com/yokel1121/muyang-illustration-skills) | 217 | 25 种固定插画风格、9 个 skill、提示词配方 + 视觉参考（含 cool-summer、giant-pet 等可爱向） | 固定画风的配方写法；编号化风格便于整批一致 |
| [Toolify-AI/awesome-gpt-image-2-prompts](https://github.com/Toolify-AI/awesome-gpt-image-2-prompts) | 14 | 多语 prompt 库 | 补充词库 |
| [GiMi-Xiaomi/gimi-illustration-skill](https://github.com/GiMi-Xiaomi/gimi-illustration-skill) | 719 | 文章配图 skill：自定义 IP、调尺寸、换风格 | 想要"固定 IP 角色"时的角色一致性做法 |
| [orange2ai/orange-line-illustration](https://github.com/orange2ai/orange-line-illustration) | 451 | 纽约客式极简编辑插画 | 冷幽默线稿风，不是治愈向但线条语言可借 |
| [EverettFish/ip_illustration_for_yourself](https://github.com/EverettFish/ip_illustration_for_yourself) | 384 | 钢笔小涂鸦 IP 插画 | 做个人头像/IP 时可用 |
| [yjz211/vivid-illustration-skill](https://github.com/yjz211/vivid-illustration-skill) | 671 | 科研图表 108 个配方（不是照片转绘） | 与照片风格化无关，列出避免误装 |

## 三、生图底座 skills（不带画风，只解决"怎么调模型"）

| 仓库 | ★ | 作用 | 判断 |
|---|---|---|---|
| [bananahub-ai/bananahub-skill](https://github.com/bananahub-ai/bananahub-skill) | 113 | 多provider 图像工作流：中文 → 英文 prompt 规范化、保守增强、模板沉淀、Gemini/OpenAI 路由 | 想要"一句话出图"的完整管道时可用；画风仍要自己写 |
| [Agentchengfeng/gemini-image-skill](https://github.com/Agentchengfeng/gemini-image-skill) | 43 | 极简 Gemini 图生图：`URL + 描述` 就出图 | 最轻；适合拿自己的 key 做批处理 |
| [dakl/claude-nanobanana-skill](https://github.com/dakl/claude-nanobanana-skill) | 1 | Gemini 2.5 Flash Image 纯 Python 封装 | 同上，代码更干净 |
| [codejunkie99/image-loop](https://github.com/codejunkie99/image-loop) | 13 | 编号地图 + 独立视觉复核 + 有界修复 + 结构化提取 | **"改一版 → 自己看一眼 → 只修坏的地方"** 的循环工程，适合批量返修 |
| [quadrilemmo/image-edit-only-skills](https://github.com/quadrilemmo/image-edit-only-skills) | 0 | 非破坏式编辑、批量、商品图、严格"不重生成" | 商品图/证件照类需要"只改一处"时参考 |

## 四、不是 skill、但绕不开的传统路线

| 仓库 | ★ | 说明 |
|---|---|---|
| [junyanz/pytorch-CycleGAN-and-pix2pix](https://github.com/junyanz/pytorch-CycleGAN-and-pix2pix) | 25k | 图生图翻译的学术基线，自带 `anime` 数据集示例；要本地训练/推理时用它 |
| [jjxxmiin/anime_style_transfer_pytorch](https://github.com/jjxxmiin/anime_style_transfer_pytorch) | 57 | AnimeGAN 系实现，CPU 也能跑；**画风固定、人脸容易崩**，适合"整张照片统一滤镜"而不是"保留个人特征" |
| [AnimeGANv2](https://github.com/TachibanaYoshino/AnimeGANv2)（同生态） | — | 最经典的"照片转动漫"模型；速度快、可爱，但只出 1 种画风，且对宠物/食物/风景效果远好于人脸特写 |
| [qq939/muse-photo-color-grading](https://github.com/qq939/muse-photo-color-grading) | 0 | 纯 ffmpeg 调色 / 去雾 / 日系滤镜，不重绘任何像素 | **不想改内容只想变好看时的正解**：0 生成、0 幻觉、可批量、可回退 |

## 推荐组合（按需求）

- **只想把一批照片变好看，不改内容和脸** → 先用 `muse-photo-color-grading` 的思路做调色；不要动生成模型。
- **要动漫 / 吉卜力 / 黏土 / 蜡笔这些"换画风"** → 本仓库 `photo-style/SKILL.md` + `style-recipes.md`；想加更多画风就查 `handraw-style` 编号，把编号里的核心特征抄进配方。
- **要一套图风格完全一致（连载、店铺、情侣头像）** → 抄 `beatra-ai/photo-to-anime-skill` 的做法：固定一段 prompt + 固定参考图顺序 + 固定 seed，先出 1 张验收再批量。
- **要海报 / 拼贴 / 版式成品** → `xiaoou-waou/zhaopianfengge-skill`（撕纸拼贴）或 `bkgz-photo-jp-decorator`（拍立得 + 日文），文字一律脚本画。
- **要本地跑、不联网、不付费** → AnimeGANv2 / CycleGAN；接受"画风固定、人物特征会漂"的代价。

## 生态现状的三个坑

1. **高星 ≠ 能转风格。** `Awesome-Nano-Banana-images` 24k★ 是案例集，`GPT-Image2-Skill` 6k★ 是提示词画廊，都不能直接"转一张照片"。
2. **很多"风格迁移 skill"实质是 API 壳。** 装完还要注册账号、充积分（Beatra、Cloud Hug、GenPark 都是）。真正的提示词纪律反而写在 1–12★ 的小仓库里。
3. **把中文/日文交给生图模型仍然不可靠。** 唯一稳的做法是像 `bkgz-photo-jp-decorator` 和本仓库 `healing-comic` 那样，文字层用脚本合成。

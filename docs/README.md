# 💕 恋爱小屋（couple-site）

一个**纯静态、零依赖、开源免费**的情侣记录网站。功能设计参考了 GitHub 上的开源项目
[liu7866/couple-home](https://github.com/liu7866/couple-home)（MIT，275★，Next.js + Cloudflare 重型方案），
本站将其核心功能做成了无需服务器、无需数据库的轻量版。

## 功能

- ⏱️ **在一起计时器**：精确到秒的恋爱时长
- 🎂 **纪念日倒数**：自动计算整百天（100 / 520 / 1000 / 1314…）、周年、情人节 / 520 / 圣诞
- 🕰️ **时光轴**：记录大事小事，网页上直接增删
- 📷 **回忆相册**：直接引用 Google Drive 图片（免图床、免流量费），带灯箱放大
- 💌 **悄悄话**：双人聊天气泡式留言板
- 🧳 **出游指南**：挂载 Google Drive 里的《情侣出游指南》PDF / 网页 / EPUB
- 🗂️ **数据备份**：时光轴与留言保存在浏览器 localStorage，可一键导出 / 导入 JSON

## 自定义

全部配置集中在 [`js/config.js`](js/config.js)：

- `nameA / nameB`：两个人的名字
- `togetherDate`：在一起的日子
- `GALLERY`：相册图片 —— 把 Google Drive 图片设为"知道链接可查看"后，填文件 ID 即可
- 也可以直接点网页右上角 ⚙️ 在线改名字和日期（存在浏览器里）

## 本地运行

```sh
cd docs
python3 -m http.server 8000
# 打开 http://localhost:8000
```

## 免费部署（任选其一）

| 平台 | 方法 |
|---|---|
| **GitHub Pages** | 仓库 Settings → Pages → 选择分支和 `docs/` 目录 |
| **Vercel** | 导入仓库，Root Directory 填 `couple-site`，Framework 选 Other |
| **Cloudflare Pages** | 连接仓库，构建命令留空，输出目录 `couple-site` |
| **Netlify** | 拖拽 `couple-site` 文件夹到 app.netlify.com/drop |

## 注意

- 相册图片依赖 Google Drive 的"知道链接可查看"权限；若在 Drive 里撤销共享，图片将不再显示。
- localStorage 数据只存在当前浏览器，换设备请先"导出 JSON"再导入。
- 想要双人异地同步数据，可升级到 [couple-home](https://github.com/liu7866/couple-home)（自带账号与数据库，可免费部署在 Cloudflare）。

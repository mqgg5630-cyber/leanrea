#!/usr/bin/env python3
"""原帖版式复刻（xhs-orig）：顶部黄标签 + 画面内白色气泡 + 底部白标签。

被 compose.py（静态成品页）和 animatic.py（视频帧）共用，
保证「图片」和「视频」上的中文完全一致。

版式参数按参考帖《毁掉关系的八种做法》8 张原图逐像素测量：
  - 画布 1080×1440（原图 1080×1447，差 7px 忽略）
  - 上格 / 下格分界在 1447 的 y=723（正好一半）→ 1440 上是 y=720
  - 顶部黄标签：y=34..148（高 114），药丸形，底色 #FEE7A6，深棕字
  - 底部白标签：y=760..882（高 122），药丸形，白底深棕字，紧贴分界线下方
  - 对白气泡：白色 + 深棕 4px 描边 + 小尾巴，画在上格场景里
"""
from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1440
INK = "#3B2314"        # 原帖描边/文字深棕
YELLOW = "#FEE7A6"     # 原帖顶部标签底色（实测 254,231,166）
PAPER = "#FFFFFF"
CREAM = "#F5F1E8"      # 原帖纸色（给标题描边光环用）
MUTED = "#7A6A63"
CLOSERS = "，。！？、；：）」』】…～,.!?;:)]}"
SEAM_DEFAULT = 0.5


def wrap(text: str, font, draw, max_width: int) -> list[str]:
    """按中文逐字折行，避头尾标点。"""
    lines, cur = [], ""
    for ch in text:
        if ch == "\n":
            lines.append(cur)
            cur = ""
            continue
        trial = cur + ch
        if cur and draw.textlength(trial, font=font) > max_width:
            if ch in CLOSERS:
                cur = trial
            else:
                lines.append(cur)
                cur = ch
        else:
            cur = trial
    if cur:
        lines.append(cur)
    return lines or [""]


def pill(draw, text: str, font, y: int, fill: str, outline: str = INK,
         width: int = 5, pad_x: int = 56, pad_y: int = 30) -> tuple[int, int, int, int]:
    """居中药丸标签，返回 bbox。原帖顶部/底部标签都是这种形状。"""
    bbox = font.getbbox(text)
    tw = int(draw.textlength(text, font=font))
    th = bbox[3] - bbox[1]
    x0 = (W - tw) // 2 - pad_x
    x1 = (W + tw) // 2 + pad_x
    y0 = y
    y1 = y + th + pad_y * 2
    draw.rounded_rectangle([x0, y0, x1, y1], radius=(y1 - y0) // 2,
                           fill=fill, outline=outline, width=width)
    draw.text(((W - tw) // 2, y0 + pad_y - bbox[1]), text, font=font, fill=INK)
    return x0, y0, x1, y1


def bubble(draw, lines: list[str], font, y_top: int = 210) -> tuple[int, int, int, int]:
    """白色对白气泡（带小尾巴），宽度随文字自适应，水平居中。"""
    if not lines:
        return (0, 0, 0, 0)
    pad_x, pad_y, lh = 46, 30, 62
    widths = [int(draw.textlength(ln, font=font)) for ln in lines]
    body_w = min(max(widths) + pad_x * 2, W - 120)
    x0 = (W - body_w) // 2
    x1 = x0 + body_w
    first = font.getbbox(lines[0])
    body_h = pad_y * 2 + lh * (len(lines) - 1) + (first[3] - first[1])
    y0, y1 = y_top, y_top + body_h

    tx = x0 + 60
    draw.polygon([(tx, y0 + 10), (tx + 30, y0 - 42), (tx + 104, y0 + 10)],
                 fill=PAPER, outline=INK, width=4)
    draw.rounded_rectangle([x0, y0, x1, y1], radius=30,
                           fill=PAPER, outline=INK, width=4)
    for i, line in enumerate(lines):
        draw.text((x0 + pad_x, y0 + pad_y + i * lh), line, font=font, fill=INK)
    return x0, y0, x1, y1


def seam_y(item: dict) -> int:
    """上下格分界线；spec 可用 "seam": 0.52 指定，默认正好一半。"""
    s = item.get("seam", SEAM_DEFAULT)
    return int(round(H * s))


def page_overlay(item: dict, fonts: dict, part: str = "top") -> Image.Image:
    """生成整页的文字层（RGBA，透明底），静态页和视频帧共用。

    part="top"    → 顶部黄标签 / 封面大标题 / 对白气泡
    part="bottom" → 底部白标签

    item 字段：
      layout    "xhs-orig"（默认）或 "cover"
      title     顶部黄标签文字（str）或封面大标题（list[str]）
      subtitle  底部白标签文字（封面模式下为钩子句）
      bubble    气泡台词，list[str] 或 str
      seam      上下格分界比例（默认 0.5）
      bubble_y  气泡顶端 y（默认 210）
    """
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)

    if item.get("layout") == "cover":
        if part != "top":
            return ov
        title = item.get("title", [])
        if isinstance(title, str):
            title = [title]
        y = 64
        for line in title[:2]:
            d.text(((W - d.textlength(line, font=fonts["cover"])) / 2, y), line,
                   font=fonts["cover"], fill=INK, stroke_width=3, stroke_fill=CREAM)
            y += 100
        hook = item.get("subtitle", "")
        if hook:
            d.text(((W - d.textlength(hook, font=fonts["hook"])) / 2, y + 20), hook,
                   font=fonts["hook"], fill=INK, stroke_width=3, stroke_fill=CREAM)
        return ov

    if part == "top":
        title = item.get("title", "")
        if title:
            pill(d, title, fonts["label_top"], 32, YELLOW)
        lines = item.get("bubble", [])
        if isinstance(lines, str):
            lines = [lines]
        if lines:
            f = fonts["bubble"]
            wrapped: list[str] = []
            for part_text in lines:
                wrapped.extend(wrap(part_text, f, d, W - 120 - 92))
            bubble(d, wrapped, f, y_top=item.get("bubble_y", 210))
    else:
        sub = item.get("subtitle", "")
        if sub:
            pill(d, sub, fonts["label_bottom"], seam_y(item) + 36, PAPER)
    return ov


def make_fonts(regular: str, medium: str) -> dict:
    return {
        "cover": ImageFont.truetype(medium, 76),
        "hook": ImageFont.truetype(regular, 34),
        "label_top": ImageFont.truetype(medium, 62),
        "label_bottom": ImageFont.truetype(medium, 56),
        "bubble": ImageFont.truetype(medium, 42),
    }

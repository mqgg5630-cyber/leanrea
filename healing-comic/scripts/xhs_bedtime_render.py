#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把晚安故事文字版渲染成小红书图片版：黑底白字，3:4 (1080x1440) JPG。
用法: python3 xhs_bedtime_render.py <故事md文件...> --out <输出目录> --font <字体ttf>
每个故事生成: 0000_cover.jpg + 内页卡片 NNNN.jpg
"""
import argparse, os, re
from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1440
BG = (8, 8, 12)          # 近黑背景
FG = (245, 245, 245)     # 白字
ACCENT = (235, 208, 155) # 暖金色（标题/点缀）
GRAY = (150, 150, 158)   # 页脚灰

def load_font(path, size):
    return ImageFont.truetype(path, size)

def wrap(draw, text, font, max_w):
    lines = []
    for para in text.split("\n"):
        if not para.strip():
            lines.append("")
            continue
        cur = ""
        for ch in para:
            if draw.textlength(cur + ch, font=font) <= max_w:
                cur += ch
            else:
                lines.append(cur)
                cur = ch
        lines.append(cur)
    return lines

def parse_stories(paths):
    stories = []
    for path in paths:
        with open(path, encoding="utf-8") as f:
            content = f.read()
        parts = re.split(r"^## ", content, flags=re.M)
        for p in parts:
            if not p.startswith("故事"):
                continue
            lines = p.splitlines()
            title = lines[0].strip()
            m = re.match(r"故事(\S+)\s+《(.+)》", title)
            num = m.group(1) if m else "?"
            name = m.group(2) if m else title
            body = "\n".join(lines[1:]).strip("-\n ")
            stories.append((num, name, body))
    return stories

def draw_cover(outdir, num, name, font_path):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    f_title = load_font(font_path, 76)
    f_sub = load_font(font_path, 40)
    f_small = load_font(font_path, 30)
    # 月牙装饰
    cx, cy, r = W // 2, 330, 90
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=ACCENT)
    d.ellipse([cx - r + 38, cy - r - 14, cx + r + 38, cy + r - 14], fill=BG)
    # 标题
    title = f"《{name}》"
    for i, line in enumerate(wrap(d, title, f_title, W - 160)):
        tw = d.textlength(line, font=f_title)
        d.text(((W - tw) / 2, 520 + i * 100), line, font=f_title, fill=FG)
    sub = f"晚安故事 · 第{num}则"
    sw = d.textlength(sub, font=f_sub)
    d.text(((W - sw) / 2, 760), sub, font=f_sub, fill=ACCENT)
    line2 = "哄睡女朋友的睡前故事 · 黑夜漫长，有我陪你"
    lw = d.textlength(line2, font=f_small)
    d.text(((W - lw) / 2, 850), line2, font=f_small, fill=GRAY)
    foot = "晚安 · 做个好梦 · 2026-11-03"
    fw = d.textlength(foot, font=f_small)
    d.text(((W - fw) / 2, H - 110), foot, font=f_small, fill=GRAY)
    path = os.path.join(outdir, "0000_cover.jpg")
    img.save(path, "JPEG", quality=92)
    return path

def draw_cards(outdir, num, name, body, font_path):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    f_head = load_font(font_path, 34)
    f_body = load_font(font_path, 42)
    f_foot = load_font(font_path, 28)
    margin = 80
    max_w = W - margin * 2
    head_h = 150
    foot_h = 100
    line_h = 42 * 1.75
    max_lines = int((H - head_h - foot_h) // line_h)

    # 先把全部文字绕排成行，再按 max_lines 分卡
    all_lines = []
    for para in body.split("\n"):
        if not para.strip():
            all_lines.append("")
            continue
        all_lines.extend(wrap(d, para, f_body, max_w))
    # 去掉连续空行
    cleaned, prev_blank = [], False
    for ln in all_lines:
        if ln == "":
            if prev_blank:
                continue
            prev_blank = True
        else:
            prev_blank = False
        cleaned.append(ln)
    total = max(1, (len(cleaned) + max_lines - 1) // max_lines)
    paths = []
    for page in range(total):
        img = Image.new("RGB", (W, H), BG)
        d = ImageDraw.Draw(img)
        # 页眉
        head = f"第{num}则 · {name}"
        d.text((margin, 60), head, font=f_head, fill=ACCENT)
        d.line([(margin, 115), (W - margin, 115)], fill=(60, 60, 70), width=2)
        # 正文
        chunk = cleaned[page * max_lines:(page + 1) * max_lines]
        y = head_h
        for ln in chunk:
            d.text((margin, y), ln, font=f_body, fill=FG)
            y += line_h
        # 页脚
        foot = f"{page + 1}/{total} · 晚安"
        fw = d.textlength(foot, font=f_foot)
        d.text(((W - fw) / 2, H - 70), foot, font=f_foot, fill=GRAY)
        p = os.path.join(outdir, f"{page + 1:04d}.jpg")
        img.save(p, "JPEG", quality=92)
        paths.append(p)
    return paths

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inputs", nargs="+")
    ap.add_argument("--out", required=True)
    ap.add_argument("--font", required=True)
    args = ap.parse_args()
    stories = parse_stories(args.inputs)
    print(f"共解析到 {len(stories)} 则故事")
    for num, name, body in stories:
        outdir = os.path.join(args.out, f"故事{num}_{name}")
        os.makedirs(outdir, exist_ok=True)
        cover = draw_cover(outdir, num, name, args.font)
        cards = draw_cards(outdir, num, name, body, args.font)
        print(f"故事{num}《{name}》: 封面1 + 内页{len(cards)} -> {outdir} ({len(body)}字)")

if __name__ == "__main__":
    main()

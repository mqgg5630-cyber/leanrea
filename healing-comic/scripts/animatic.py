#!/usr/bin/env python3
"""healing-comic 动态化：把无字底图 + spec.json 变成竖版短视频（MP4）。

原理（没有视频模型时的可行做法）：
  一页漫画 = 两个镜头。上格一个慢推镜头，下格一个慢推镜头，中间做交叉溶解；
  画面用「缓动推近 + 轻微平移」制造呼吸感；中文在动画图层之上合成，
  所以字永远是清晰的，不会跟着缩放糊掉。

用法:
  python3 animatic.py spec.json --font R.ttf --font-medium M.ttf \
      --art-root examples --outdir examples/video --fps 25 --all
"""
from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps

sys.path.insert(0, str(Path(__file__).resolve().parent))
from artlayout import H, W, make_fonts, page_overlay  # noqa: E402

try:
    import imageio.v2 as iio
except ImportError:
    sys.exit("需要 imageio：python3 -m pip install imageio imageio-ffmpeg")


def smooth(u: float) -> float:
    return u * u * (3 - 2 * u)


def camera(base: Image.Image, z: float, cy: float) -> Image.Image:
    """按缩放 z 与中心 cy 从整页取景（只放大，不留黑边）。"""
    vh, vw = H / z, W / z
    cy = min(max(cy, vh / 2), H - vh / 2)
    cx = W / 2
    box = (int(round(cx - vw / 2)), int(round(cy - vh / 2)),
           int(round(cx + vw / 2)), int(round(cy + vh / 2)))
    return base.crop(box).resize((W, H), Image.LANCZOS)


def fade(img: Image.Image, alpha: float) -> Image.Image:
    if alpha >= 0.999:
        return img
    a = img.getchannel("A").point(lambda v: int(v * max(0.0, min(1.0, alpha))))
    out = img.copy()
    out.putalpha(a)
    return out


def clip_frames(item: dict, art: Image.Image, fonts: dict, fps: int,
                shot_s: float, fade_s: float):
    """产出该页的所有帧（PIL RGBA）。"""
    is_cover = item.get("layout") == "cover"
    seam = int(round(H * item.get("seam", 0.5)))
    top_y = H * 0.30 if is_cover else seam * 0.56
    bot_y = H * 0.74 if is_cover else H * 0.76

    ov_top = page_overlay(item, fonts, "top")
    ov_bot = page_overlay(item, fonts, "bottom")

    if is_cover:
        total = shot_s * 1.9
        n = int(total * fps)
        for i in range(n):
            u = smooth(i / max(1, n - 1))
            z = 1.0 + 0.13 * u
            cy = H * 0.52 - 40 * u
            frame = camera(art, z, cy).convert("RGBA")
            frame.alpha_composite(fade(ov_top, min(1.0, i / (0.4 * fps))))
            yield frame
        return

    total = shot_s * 2 + fade_s
    n = int(total * fps)
    n_a = int(shot_s * fps)
    n_f = int(fade_s * fps)
    keep_top = not item.get("subtitle")          # 结尾页没有底部标签，台词一直留在画面上
    for i in range(n):
        if i < n_a:                                  # 上格
            u = smooth(i / max(1, n_a - 1))
            z = 1.0 + 0.20 * u
            cy = H * 0.50 + (top_y - H * 0.50) * u
            a_top, a_bot = 1.0, 0.0
        elif i < n_a + n_f:                           # 交叉溶解
            u = (i - n_a) / max(1, n_f)
            z = 1.20
            cy = top_y + (bot_y - top_y) * smooth(u)
            a_top, a_bot = (1.0 if keep_top else 1.0 - u), u
        else:                                        # 下格
            u = smooth((i - n_a - n_f) / max(1, n - n_a - n_f))
            z = 1.20 + 0.10 * u
            cy = bot_y + 26 * u
            a_top, a_bot = (1.0 if keep_top else 0.0), 1.0
        frame = camera(art, z, cy).convert("RGBA")
        if a_top > 0:
            frame.alpha_composite(fade(ov_top, a_top))
        if a_bot > 0:
            frame.alpha_composite(fade(ov_bot, a_bot))
        yield frame


def write_clip(path: Path, frames, fps: int, audio: Path | None = None) -> None:
    """流式写 H.264（imageio-ffmpeg 的 write_frames，边生成边编码，不占内存）。"""
    import imageio_ffmpeg

    tmp = path.with_suffix(".tmp.mp4")
    writer = imageio_ffmpeg.write_frames(
        str(tmp), size=(W, H), fps=fps, codec="libx264", pix_fmt_in="rgb24",
        pix_fmt_out="yuv420p", quality=None,
        output_params=["-crf", "18", "-preset", "medium", "-movflags", "+faststart"], macro_block_size=1)
    writer.send(None)
    for frame in frames:
        writer.send(np.asarray(frame.convert("RGB"), dtype=np.uint8))
    writer.close()

    if audio and audio.is_file():
        cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp),
               "-i", str(audio), "-c:v", "copy", "-c:a", "aac", "-b:a", "128k",
               "-shortest", str(path)]
        try:
            subprocess.run(cmd, check=True)
            tmp.unlink()
            return
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
    tmp.replace(path)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("spec", type=Path)
    ap.add_argument("--font")
    ap.add_argument("--font-medium")
    ap.add_argument("--art-root", type=Path, default=None)
    ap.add_argument("--outdir", type=Path, default=None)
    ap.add_argument("--fps", type=int, default=25)
    ap.add_argument("--shot", type=float, default=3.2, help="单格镜头秒数")
    ap.add_argument("--fade", type=float, default=0.5, help="格间溶解秒数")
    ap.add_argument("--audio", type=Path, help="给全部片段挂同一条音轨（旁白/BGM）")
    ap.add_argument("--all", action="store_true", help="额外输出全套合集视频")
    ap.add_argument("--all-name", default="00-全套合集.mp4")
    a = ap.parse_args()

    spec = a.spec.resolve()
    items = json.loads(spec.read_text(encoding="utf-8"))
    art_root = (a.art_root or spec.parent).resolve()
    outdir = (a.outdir or spec.parent / "video").resolve()
    outdir.mkdir(parents=True, exist_ok=True)

    reg = os.environ.get("COMIC_FONT", "") or (a.font or "")
    med = os.environ.get("COMIC_FONT_MEDIUM", "") or (a.font_medium or "") or reg
    if not reg or not Path(reg).is_file():
        sys.exit("找不到中文字体：--font 指定 .ttf/.ttc，或设 COMIC_FONT")
    fonts = make_fonts(reg, med)

    clips = []
    for it in items:
        art_path = art_root / it["art"]
        if not art_path.is_file():
            sys.exit(f"缺少底图：{art_path}")
        art = ImageOps.fit(Image.open(art_path).convert("RGB"), (W, H),
                           method=Image.LANCZOS, centering=(0.5, 0.5))
        name = it.get("clip") or Path(it.get("out", it["art"])).with_suffix(".mp4").name
        out = outdir / name
        frames = clip_frames(it, art, fonts, a.fps, a.shot, a.fade)
        write_clip(out, frames, a.fps, a.audio)
        clips.append(out)
        print(f"[animatic] {name}  <- {it['art']}")

    if a.all:
        # 合集：把各页片段首尾相接（流式写，不把整段读进内存）
        import imageio_ffmpeg
        allp = outdir / a.all_name
        w = imageio_ffmpeg.write_frames(
            str(allp), size=(W, H), fps=a.fps, codec="libx264", pix_fmt_in="rgb24",
            pix_fmt_out="yuv420p", quality=None,
            output_params=["-crf", "18", "-preset", "medium", "-movflags", "+faststart"],
            macro_block_size=1)
        w.send(None)
        total = 0
        for c in clips:
            rd = iio.get_reader(str(c))
            for f in rd:
                w.send(np.asarray(f, dtype=np.uint8))
                total += 1
            rd.close()
        w.close()
        print(f"[animatic] {a.all_name}  ({total} 帧 / {total / a.fps:.1f}s)")


if __name__ == "__main__":
    main()

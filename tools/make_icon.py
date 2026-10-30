#!/usr/bin/env python3
"""
生成 App 图标（1024x1024，无 alpha，符合 App Store 要求）。

用法：
    python tools/make_icon.py

设计：蓝紫渐变底 + 白色学士帽 + 右下角对勾徽章。
全部用几何图形绘制，不依赖字体（避免中文字体缺失问题）。
4 倍超采样后缩小，边缘更干净。
"""

from __future__ import annotations

import math
import os
from PIL import Image, ImageDraw, ImageFilter

# ---- 参数 ----
SIZE = 1024          # 输出尺寸
SS = 4               # 超采样倍数
S = SIZE * SS        # 画布尺寸

TOP_COLOR = (74, 125, 255)     # #4A7DFF
BOTTOM_COLOR = (107, 78, 230)  # #6B4EE6
WHITE = (255, 255, 255)

OUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "KaoyanWorkbench", "Assets.xcassets", "AppIcon.appiconset",
)
OUT_NAME = "AppIcon-1024.png"


def vertical_gradient(size: int, top: tuple, bottom: tuple) -> Image.Image:
    """逐行插值的竖向渐变。"""
    img = Image.new("RGB", (size, size), top)
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(1, size - 1)
        r = round(top[0] + (bottom[0] - top[0]) * t)
        g = round(top[1] + (bottom[1] - top[1]) * t)
        b = round(top[2] + (bottom[2] - top[2]) * t)
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    return img


def add_glow(img: Image.Image, center: tuple, radius: int, alpha: int) -> Image.Image:
    """左上角柔光，让纯渐变不那么平。"""
    glow = Image.new("L", img.size, 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse(
        [center[0] - radius, center[1] - radius,
         center[0] + radius, center[1] + radius],
        fill=alpha,
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius // 3))
    white = Image.new("RGB", img.size, WHITE)
    return Image.composite(white, img, glow.point(lambda v: v))


def draw_graduation_cap(draw: ImageDraw.ImageDraw, cx: float, cy: float, unit: float) -> None:
    """白色学士帽：帽板（菱形）+ 帽身（圆角矩形）+ 流苏。

    cx, cy 为帽板中心；unit 为「基准单位」，所有尺寸按它缩放。
    """
    board_half_w = unit * 0.360      # 帽板半宽
    board_half_h = unit * 0.098      # 帽板半高

    # 帽板：菱形（上尖、左右宽、下尖）
    board = [
        (cx, cy - board_half_h),
        (cx + board_half_w, cy + board_half_h * 0.18),
        (cx, cy + board_half_h * 1.55),
        (cx - board_half_w, cy + board_half_h * 0.18),
    ]
    draw.polygon(board, fill=WHITE)

    # 帽身：从帽板中部垂下，略窄，底部圆角
    body_top = cy + board_half_h * 0.30
    body_bottom = body_top + unit * 0.235
    body_half_w = unit * 0.176
    draw.rounded_rectangle(
        [cx - body_half_w, body_top, cx + body_half_w, body_bottom],
        radius=int(body_half_w * 0.34),
        fill=WHITE,
    )

    # 流苏：从帽板右角垂下 + 末端圆球
    tassel_x = cx + board_half_w * 0.93
    tassel_y = cy + board_half_h * 0.34
    tassel_end_y = tassel_y + unit * 0.175
    draw.line(
        [(tassel_x, tassel_y), (tassel_x, tassel_end_y)],
        fill=WHITE,
        width=max(2, int(unit * 0.014)),
    )
    r = unit * 0.030
    draw.ellipse(
        [tassel_x - r, tassel_end_y - r, tassel_x + r, tassel_end_y + r],
        fill=WHITE,
    )


def draw_check_badge(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float) -> None:
    """右下角对勾徽章：白圆 + 渐变绿勾。"""
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
    # 对勾
    width = max(4, int(r * 0.30))
    p1 = (cx - r * 0.42, cy + r * 0.02)
    p2 = (cx - r * 0.10, cy + r * 0.34)
    p3 = (cx + r * 0.46, cy - r * 0.34)
    draw.line([p1, p2, p3], fill=(52, 199, 123), width=width, joint="curve")


def build() -> Image.Image:
    img = vertical_gradient(S, TOP_COLOR, BOTTOM_COLOR)
    img = add_glow(img, (S * 0.22, S * 0.16), int(S * 0.45), 70)

    draw = ImageDraw.Draw(img)

    # 帽子整体略偏左上，右下角留给对勾徽章
    draw_graduation_cap(draw, cx=S * 0.455, cy=S * 0.330, unit=S)
    draw_check_badge(draw, cx=S * 0.790, cy=S * 0.790, r=S * 0.110)

    # 降采样，去掉锯齿
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    icon = build()

    # App Store 不接受带 alpha 的图标
    if icon.mode != "RGB":
        icon = icon.convert("RGB")

    out_path = os.path.join(OUT_DIR, OUT_NAME)
    icon.save(out_path, format="PNG", optimize=True)
    print(f"已生成: {out_path}")
    print(f"尺寸: {icon.size[0]}x{icon.size[1]}, 模式: {icon.mode}")
    print(f"体积: {os.path.getsize(out_path) / 1024:.1f} KB")


if __name__ == "__main__":
    main()


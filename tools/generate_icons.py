"""
アイコン・スプラッシュ用プレースホルダーPNG生成スクリプト
実際のリリース前に本物のデザインアセットに差し替えてください。
"""
import struct
import zlib
import os

def make_png(width, height, pixels_rgba):
    def chunk(name, data):
        c = struct.pack('>I', len(data)) + name + data
        return c + struct.pack('>I', zlib.crc32(name + data) & 0xffffffff)

    raw = b''
    for y in range(height):
        raw += b'\x00'
        for x in range(width):
            raw += bytes(pixels_rgba[y * width + x])

    ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    idat = zlib.compress(raw)

    return (
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', ihdr)
        + chunk(b'IDAT', idat)
        + chunk(b'IEND', b'')
    )

def solid_color(w, h, r, g, b):
    return [(r, g, b)] * (w * h)

def draw_circle(pixels, w, h, cx, cy, radius, r, g, b):
    for y in range(h):
        for x in range(w):
            if (x - cx) ** 2 + (y - cy) ** 2 <= radius ** 2:
                pixels[y * w + x] = (r, g, b)
    return pixels

def draw_text_pixels(pixels, w, h, r, g, b):
    # Simple "M" shape drawn with pixels for monster icon
    center_x, center_y = w // 2, h // 2
    size = w // 4
    # Draw emoji-like running figure with circles
    # Head
    pixels = draw_circle(pixels, w, h, center_x, center_y - size, size // 5, r, g, b)
    # Body
    for y in range(center_y - size + size // 5, center_y + size // 2):
        for x in range(center_x - size // 6, center_x + size // 6):
            pixels[y * w + x] = (r, g, b)
    return pixels

def generate():
    out_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icons')
    os.makedirs(out_dir, exist_ok=True)

    # Background color: #1A1A2E (dark navy)
    bg_r, bg_g, bg_b = 0x1A, 0x1A, 0x2E
    # Accent color: #6C63FF (purple)
    acc_r, acc_g, acc_b = 0x6C, 0x63, 0xFF
    # White
    wh = (255, 255, 255)

    # app_icon.png (1024x1024) — dark bg with purple circle
    SIZE = 1024
    px = solid_color(SIZE, SIZE, bg_r, bg_g, bg_b)
    px = draw_circle(px, SIZE, SIZE, SIZE // 2, SIZE // 2, SIZE // 2 - 40, acc_r, acc_g, acc_b)
    px = draw_circle(px, SIZE, SIZE, SIZE // 2, SIZE // 2 - 180, 80, 255, 255, 255)
    data = make_png(SIZE, SIZE, px)
    path = os.path.join(out_dir, 'app_icon.png')
    with open(path, 'wb') as f:
        f.write(data)
    print(f'Generated: {path}')

    # app_icon_fg.png (1024x1024) — transparent bg with figure (for adaptive icon)
    px2 = solid_color(SIZE, SIZE, acc_r, acc_g, acc_b)
    px2 = draw_circle(px2, SIZE, SIZE, SIZE // 2, SIZE // 2 - 180, 90, 255, 255, 255)
    data2 = make_png(SIZE, SIZE, px2)
    path2 = os.path.join(out_dir, 'app_icon_fg.png')
    with open(path2, 'wb') as f:
        f.write(data2)
    print(f'Generated: {path2}')

    # splash_logo.png (512x512) — centered icon on dark bg
    S = 512
    px3 = solid_color(S, S, bg_r, bg_g, bg_b)
    px3 = draw_circle(px3, S, S, S // 2, S // 2, S // 3, acc_r, acc_g, acc_b)
    px3 = draw_circle(px3, S, S, S // 2, S // 2 - 80, 40, 255, 255, 255)
    data3 = make_png(S, S, px3)
    path3 = os.path.join(out_dir, 'splash_logo.png')
    with open(path3, 'wb') as f:
        f.write(data3)
    print(f'Generated: {path3}')

    print('\n完了！assets/icons/ の PNG は仮アセットです。')
    print('リリース前に本番デザインに差し替えてください。')

if __name__ == '__main__':
    generate()

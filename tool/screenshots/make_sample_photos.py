# Draws simple illustrated "job photos" (no real photos): cars, plates, glass.
import random, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
W, H = 640, 480
F = "/usr/share/fonts/opentype/inter/Inter-Bold.otf"
def bg(d, seed):
    r = random.Random(seed)
    sky = (150+r.randint(-15,15), 185+r.randint(-15,15), 215+r.randint(-10,15))
    for y in range(H):
        t = y/H
        if y < H*0.55: c = tuple(int(sky[i]*(1-t*0.3)+255*t*0.3) for i in range(3))
        else: g = int(95+40*(t-0.55)); c=(g,g,g+4)
        d.line([(0,y),(W,y)], fill=c)
    d.rectangle([0,int(H*0.55)-30,W,int(H*0.55)], fill=(120,125,118))  # building strip
def car(d, color, x=0, scale=1.0):
    cx, base = W//2 + x, int(H*0.78)
    s = scale
    dark = tuple(max(0,c-60) for c in color)
    d.rounded_rectangle([cx-230*s, base-110*s, cx+230*s, base-30*s], 30*s, fill=color)
    d.polygon([(cx-140*s,base-110*s),(cx-90*s,base-175*s),(cx+80*s,base-175*s),(cx+150*s,base-110*s)], fill=color)
    d.polygon([(cx-125*s,base-112*s),(cx-82*s,base-165*s),(cx-5*s,base-165*s),(cx-5*s,base-112*s)], fill=(60,80,100))
    d.polygon([(cx+5*s,base-112*s),(cx+5*s,base-165*s),(cx+75*s,base-165*s),(cx+132*s,base-112*s)], fill=(60,80,100))
    d.line([(cx-200*s,base-75*s),(cx+200*s,base-75*s)], fill=dark, width=int(3*s))
    for wx in (-140,140):
        d.ellipse([cx+(wx-48)*s, base-80*s, cx+(wx+48)*s, base+16*s], fill=(25,25,28))
        d.ellipse([cx+(wx-24)*s, base-56*s, cx+(wx+24)*s, base-8*s], fill=(170,170,175))
    d.ellipse([cx-240*s, base+5*s, cx+240*s, base+30*s], fill=(70,70,74))
def plate(d, text, seed):
    r = random.Random(seed)
    d.rectangle([0,0,W,H], fill=(70+r.randint(0,40),)*3)
    d.rounded_rectangle([110,150,530,350], 18, fill=(246,246,240), outline=(40,40,40), width=6)
    d.text((W//2,190),"TEXAS",font=ImageFont.truetype(F,30),fill=(170,30,30),anchor="mm")
    d.text((W//2,275),text,font=ImageFont.truetype(F,70),fill=(20,20,30),anchor="mm")
def glass(d, seed):
    r = random.Random(seed)
    for y in range(H):
        g = int(120+60*y/H); d.line([(0,y),(W,y)], fill=(g-40,g-10,g+20))
    cx, cy = 300+r.randint(-60,60), 220+r.randint(-40,40)
    d.ellipse([cx-14,cy-14,cx+14,cy+14], outline=(240,240,240), width=4)
    for _ in range(9):
        x, y = cx, cy
        for _ in range(5):
            nx, ny = x+r.randint(-70,70), y+r.randint(-70,70)
            d.line([(x,y),(nx,ny)], fill=(235,240,245), width=2); x, y = nx, ny
jobs = [("HBX 4821",(200,40,40)),("KLM 3307",(30,60,140)),("RTX 9152",(235,235,235)),("JWD 6640",(40,40,45)),("PNT 2289",(60,130,80))]
n = 4810
for j,(pl,col) in enumerate(jobs):
    shots = [("plate",None),("side",0),("side",1),("glass",None),("side",2)]
    for k,(kind,v) in enumerate(shots[: 5 if j%2==0 else 4]):
        im = Image.new("RGB",(W,H)); d = ImageDraw.Draw(im)
        if kind=="plate": plate(d, pl, j)
        elif kind=="glass": glass(d, j*7+k)
        else:
            bg(d, j*10+k); car(d, col, x=[-40,60,0][v], scale=[1.0,1.15,0.85][v])
        im = im.filter(ImageFilter.GaussianBlur(0.6))
        im.save(f"{out}/IMG_{n}.jpg", quality=80); n += 1
print(n-4810)

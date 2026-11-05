#!/usr/bin/env python3
"""Regenerate editable headpiece handoff art from the edition palette.

900×260 native artboard is mapped into the existing 900×360 handoff canvas.
Paths mirror ManuscriptDrawing; these SVGs are not runtime dependencies.
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'assets/templates'


def flower(x, y, radius, petals, color, metal):
    paths = []
    for i in range(petals):
        a = i * math.tau / petals
        dx, dy = math.cos(a), math.sin(a)
        tx, ty = -dy, dx
        paths.append(f'<path d="M{x},{y} Q{x+tx*radius*.7+dx*radius},{y+ty*radius*.7+dy*radius} {x+dx*radius*2.1},{y+dy*radius*2.1} Q{x-tx*radius*.7+dx*radius},{y-ty*radius*.7+dy*radius} {x},{y}" fill="{color}" fill-opacity=".78"/>')
    paths.append(f'<circle cx="{x}" cy="{y}" r="{radius*.42}" fill="{metal}"/>')
    return ''.join(paths)


def arch(x, y, w, h):
    return f'M{x},{y+h} V{y+h/2} Q{x+w*.1},{y+h*.13} {x+w/2},{y} Q{x+w*.9},{y+h*.13} {x+w},{y+h/2} V{y+h}Z'


def garden(t, x, y, w, h, scale):
    out = []
    step = 66 * scale
    row = 0
    cy = y
    while cy <= y+h:
        cx = x-step+(0 if row % 2 == 0 else step/2)
        while cx <= x+w+step:
            out.append(f'<path d="M{cx-step/2},{cy} C{cx-step/2},{cy-step*.75} {cx+step/2},{cy+step*.75} {cx+step/2},{cy} C{cx+step*.8},{cy-step*.65} {cx-step*.3},{cy-step*.6} {cx},{cy-step*.18}" fill="none" stroke="{t["metal"]}" stroke-width=".9"/>')
            for d in [-1, 1]:
                lx, ly = cx+d*step*.27, cy+d*step*.2
                out.append(f'<path d="M{lx},{ly} Q{lx-d*step*.12},{ly-step*.35} {lx+d*step*.22},{ly-step*.3} Q{lx+d*step*.28},{ly-step*.04} {lx},{ly}" fill="{t["leaf"]}" stroke="{t["metal"]}" stroke-width=".45"/>')
            petals = 5 if t['id'] == 'shirazGarden' else 8
            for r, n, color in [(6,petals,t['metal']),(4.4,petals,t['blossom']),(2,6,t['pigmentLight'])]:
                out.append(flower(cx,cy,r*scale,n,color,t['metal']))
            for dx in [-.38,.38]:
                out.append(f'<circle cx="{cx+step*dx+1}" cy="{cy+step*.34+1}" r="1" fill="{t["metal"]}"/>')
            cx += step
        row += 1
        cy += step*.85
    return ''.join(out)


def rosette(t, x, y, r, fill):
    pts = []
    for i in range(16):
        a = i*math.pi/8-math.pi/2
        length = r*(1 if i%2 == 0 else .57)
        pts.append(f'{x+math.cos(a)*length},{y+math.sin(a)*length}')
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{t["metal"]}"/>'


def medallion(t,x,y,r):
    out = [rosette(t,x,y,r,t['metal']),rosette(t,x,y,r*.88,t['pigment'])]
    for i in range(12):
        a=i*math.pi/6
        out.append(flower(x+math.cos(a)*r*.49,y+math.sin(a)*r*.49,r*.075,5,t['blossom'],t['metal']))
    out.append(flower(x,y,r*.2,8,t['metal'],t['blossom']))
    out.append(flower(x,y,r*.13,8,t['blossom'],t['metal']))
    return ''.join(out)


for t in json.loads((FOLDER/'template-tokens.json').read_text())['templates']:
    heart = arch(268,34,364,182)
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="900" height="360" viewBox="0 0 900 360" role="img" aria-label="{t["name"]} editable sar-lawh"><title>{t["name"]}</title><defs><clipPath id="field"><rect x="18" y="50" width="864" height="190"/></clipPath><clipPath id="heart"><path d="{heart}"/></clipPath></defs><g transform="scale(1 1.38461538)">']
    out.append(f'<rect x="4" y="36" width="892" height="218" fill="{t["pigment"]}" stroke="{t["metal"]}" stroke-width="3"/>')
    for inset in [6,11]:
        out.append(f'<rect x="{4+inset}" y="{36+inset}" width="{892-2*inset}" height="{218-2*inset}" fill="none" stroke="{t["metal"]}" stroke-width="1"/>')
    out.append('<g clip-path="url(#field)">'+garden(t,18,50,864,190,1)+'</g>')
    for layer in range(4):
        inset=layer*8
        out.append(f'<path d="{arch(238+inset,4+inset,424-2*inset,242-2*inset)}" fill="{t["metal"] if layer%2==0 else t["pigment"]}" stroke="{t["metal"]}"/>')
    out.append('<g clip-path="url(#heart)">'+garden(t,263,29,374,192,.8)+'</g>')
    out += [medallion(t,112,145,50),medallion(t,788,145,50),medallion(t,450,151,46 if t['id']=='shirazGarden' else 51)]
    for x in range(24,877,14):
        for y in [41,249]:
            out.append(f'<circle cx="{x+1}" cy="{y}" r="1" fill="{t["metal"]}"/>')
    out.append('</g></svg>')
    (FOLDER/t['asset']).write_text('\n'.join(out)+'\n')

import subprocess, re, sys
import _poppler
p = int(sys.argv[1])
pdf = sys.argv[2] if len(sys.argv) > 2 else 'substitution/substitution2.pdf'
xlo = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0
xhi = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
out = subprocess.run([_poppler.tool('pdftotext'), '-bbox', '-f', str(p), '-l', str(p), pdf, '-'],
                     capture_output=True, text=True,
                     encoding='utf-8', errors='replace').stdout or ''
mp = re.search(r'<page width="([\d.]+)" height="([\d.]+)"', out)
W, H = float(mp.group(1)), float(mp.group(2))
words = []
for m in re.finditer(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>', out, re.S):
    x0, y0, x1, y1 = [float(m.group(i)) for i in range(1, 5)]
    x0 /= W; x1 /= W; y0 /= H; y1 /= H
    cx = (x0 + x1) / 2
    if cx < xlo or cx > xhi:
        continue
    words.append((y0, x0, x1, y1, re.sub(r'<[^>]+>', '', m.group(5))))
words.sort()
cur = None
rows = []
for y0, x0, x1, y1, t in words:
    if cur and abs(y0 - cur[0]) < 0.004:
        cur[1] = min(cur[1], x0); cur[2] = max(cur[2], x1); cur[3] = max(cur[3], y1)
        cur[4].append(t)
    else:
        if cur:
            rows.append(cur)
        cur = [y0, x0, x1, y1, [t]]
if cur:
    rows.append(cur)
print('\n'.join('y %.4f-%.4f  x %.4f-%.4f  %s' % (r[0], r[3], r[1], r[2], ' '.join(r[4])[:80]) for r in rows))

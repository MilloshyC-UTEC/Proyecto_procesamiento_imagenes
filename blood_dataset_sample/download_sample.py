import csv, os, sys, urllib.request, time
from concurrent.futures import ThreadPoolExecutor
man, out = sys.argv[1], sys.argv[2]
rows = list(csv.DictReader(open(man)))
def get(u):
    for t in range(5):
        try:
            with urllib.request.urlopen(u, timeout=60) as r: return r.read()
        except Exception: time.sleep(2*(t+1))
    raise RuntimeError(u)
def dl(r):
    rel = f"{r['label']}/row_{int(r['row_idx']):05d}.jpg"
    p = os.path.join(out, rel); os.makedirs(os.path.dirname(p), exist_ok=True)
    if not os.path.exists(p): open(p, 'wb').write(get(r['url']))
    return (rel, r['label'], r['row_idx'])
with ThreadPoolExecutor(8) as ex: res = list(ex.map(dl, rows))
with open(os.path.join(out, 'labels.csv'), 'w', newline='') as f:
    w = csv.writer(f); w.writerow(['file', 'label', 'row_idx']); w.writerows(res)
print('DONE', len(res))

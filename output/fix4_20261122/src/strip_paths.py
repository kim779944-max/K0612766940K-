import json, ntpath
for f in ('measure_before.json', 'measure_after.json'):
    R = json.load(open(f, encoding='utf-8'))
    for k in list(R):
        if k.startswith('show_full_'): R[k] = 'shots/' + ntpath.basename(R[k])
    json.dump(R, open(f, 'w', encoding='utf-8'), ensure_ascii=False, indent=1); print(f, R['show_full_390'])

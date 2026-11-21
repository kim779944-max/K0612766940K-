import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8-sig'))
for k in ['pnu0','pxDefault','arrowNote','AR_gapyeong','AR_gapyeong_z18','AR_yangpyeong','AR_namyangju','A10','A8','err','evts']:
    print(k, json.dumps(d.get(k),ensure_ascii=False)[:400])
for k in ['A1_gapyeong','A1_gapyeong_sat','A1_gapyeong_z18','A1_yangpyeong','A1_namyangju']:
    v=d.get(k)
    if not v: print(k,None); continue
    sm=v['samples']; print(k,'total',v['total'],'n',len(sm),'pass',sum(x['pass'] for x in sm), [(x['band'],x['rgb'],x['dmax'],x['baseW_at0_5'],x['tailW_at0_6']) for x in sm if not x['pass']])
for k in ['A4_gapyeong','A4_yangpyeong','A4_namyangju']:
    v=d.get(k); print(k, v and {kk:v[kk] for kk in ['ok','total','downhill','minDrop','allDownhill','worst']})
for s in d.get('A5') or []:
    print('A5',s.get('name'),s.get('center'),s.get('outward'),s.get('lower'),s.get('zoom'),[ (r['dir'],r['dot50'],r['dot100'],r['elev100']) for r in s['dirs']])
print('pxstat same', json.dumps(d.get('PXSTAT'))==json.dumps(d.get('PXSTAT_after')))
for e in d.get('evtList',[]):
    if 'vworld' not in e.lower(): print('EVT',e[:200])

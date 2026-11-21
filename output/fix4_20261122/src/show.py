import json,sys
R=json.load(open(sys.argv[1],encoding='utf-8'))
for k,v in R.items():
  if k.startswith('navi_quiz'): print(k,[(q['lv'],q['cards'],q['imgs'],q['broken'],q['overlap'],q['firstRowVisible'],q['docW']) for q in v])
  else: print(k, json.dumps(v,ensure_ascii=False)[:900])

import re,sys,os
P=sys.argv[1]
M="""d2a-3 j2-4 l4-3 s3a-2 d1-3 j1-1 d1-1 s2c-1 j2-1 d2b-2 d2a-1 v3-3 d1-4 l3-2 s4b-1 d3d-2 s3c-3 s3d-2 l3-3 s2c-3
s4b-2 d3a-3 s3c-2 d4b-3 l1-2 s3d-3 d2c-1 j1-3 d2d-4 s4c-3 s4b-4 j3-3
d3b-1 d4a-3 v2-3 d3d-4 v1-4 d2c-4 d2c-3 j4-3
s2d-2 v1-2 s1-2 s2b-3 d2a-2 s3b-1 l1-3 s3c-4
d4c-4 s2d-4 l4-2 s4b-3 d3c-1 d3b-3 s2b-1 d4b-4 l1-4 s3b-4 d2b-1 l1-1
s3a-1 j3-1 s2a-1 s3d-1 d3b-4 s3c-1 d4c-2 s2b-4
s2d-1 s2c-2 l3-4 s2a-4 d2b-4 s4c-4 l4-4 l2-2
d3c-2 d4d-1 s3d-4 s4c-2 d3c-3 j4-4 j1-4 j2-3
d2d-1 d4c-1 d4b-1 j3-4 v2-4 d4a-1 s1-3 s4d-3
v4-2 s4d-2 j3-2 l2-1 s2b-2 s4d-1 l3-1 s3b-3""".split()
assert len(M)==100 and len(set(M))==100, (len(M),len(set(M)))
raw=open(P,'rb').read().decode('utf-8')
it=iter(M); n=0
def rep(m):
    global n; n+=1
    return m.group(1)+", img:'img/opts/%s.jpg' }" % next(it)
# 보기 줄: { l:'...', ..., p:'...' }  → p 뒤에 img 추가
new=re.sub(r"(\{ l:'[^\n]*?p:'[^'\n]*')\s*\}", rep, raw)
assert n==100, n
open(P,'wb').write(new.encode('utf-8'))
for f in M: assert os.path.exists(os.path.join(os.path.dirname(P),'..','img','opts',f+'.jpg')), f
print('ok',n)

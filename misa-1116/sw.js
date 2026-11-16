/* KTS 미사 발송판 — 홈 화면 설치용 최소 서비스워커 (네트워크 우선, 실패 시 캐시) */
var CACHE = 'misa1116-v2';
self.addEventListener('install', function(){ self.skipWaiting(); });
self.addEventListener('activate', function(e){ e.waitUntil(self.clients.claim()); });
self.addEventListener('fetch', function(e){
  if (e.request.method !== 'GET') return;
  e.respondWith(
    fetch(e.request).then(function(r){
      var copy = r.clone();
      caches.open(CACHE).then(function(c){ c.put(e.request, copy); }).catch(function(){});
      return r;
    }).catch(function(){
      return caches.match(e.request);
    })
  );
});

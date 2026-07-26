/* Service worker da Obra Bananeiras C08
   Guarda o app no aparelho para abrir mesmo sem internet no canteiro. */
const CACHE='obra-c08-v2';

self.addEventListener('install', e=>{
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(c=>c.addAll([
    './','./index.html','./manifest.json','./icon-192.png','./icon-512.png'
  ]).catch(()=>{})));
});

self.addEventListener('activate', e=>{
  e.waitUntil(
    caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k))))
      .then(()=>self.clients.claim())
  );
});

self.addEventListener('fetch', e=>{
  const req=e.request;
  if(req.method!=='GET') return;

  const url=new URL(req.url);

  /* Supabase e qualquer API: sempre rede, nunca cache */
  if(url.hostname.endsWith('supabase.co')) return;

  /* Páginas: tenta rede primeiro (para pegar atualizações), cai no cache se offline */
  if(req.mode==='navigate'){
    e.respondWith(
      fetch(req).then(r=>{
        const copia=r.clone();
        caches.open(CACHE).then(c=>c.put(req,copia));
        return r;
      }).catch(()=>caches.match(req).then(r=>r||caches.match('./index.html')))
    );
    return;
  }

  /* Demais recursos (inclusive a biblioteca de PDF): cache primeiro, atualiza em segundo plano */
  e.respondWith(
    caches.match(req).then(cached=>{
      const rede=fetch(req).then(r=>{
        if(r&&r.status===200){
          const copia=r.clone();
          caches.open(CACHE).then(c=>c.put(req,copia));
        }
        return r;
      }).catch(()=>cached);
      return cached||rede;
    })
  );
});

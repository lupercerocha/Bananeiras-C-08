-- ============================================================
--  Gestão Obras C08 — espaço para guardar os arquivos das notas
--  Rode uma única vez no Supabase: menu SQL Editor > New query >
--  cole tudo > Run. O resultado "Success. No rows returned" é o esperado.
-- ============================================================

-- 1) Cria o repositório de arquivos (privado: ninguém acessa sem estar logado)
insert into storage.buckets (id, name, public)
values ('notas', 'notas', false)
on conflict (id) do nothing;

-- 2) Cada usuário só enxerga e mexe nos arquivos da própria pasta.
--    Os arquivos são gravados como  <id-do-usuario>/<id-da-nota>.pdf

drop policy if exists "notas ler proprios arquivos" on storage.objects;
create policy "notas ler proprios arquivos"
on storage.objects for select to authenticated
using (
  bucket_id = 'notas'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "notas enviar proprios arquivos" on storage.objects;
create policy "notas enviar proprios arquivos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'notas'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "notas atualizar proprios arquivos" on storage.objects;
create policy "notas atualizar proprios arquivos"
on storage.objects for update to authenticated
using (
  bucket_id = 'notas'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'notas'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "notas apagar proprios arquivos" on storage.objects;
create policy "notas apagar proprios arquivos"
on storage.objects for delete to authenticated
using (
  bucket_id = 'notas'
  and (storage.foldername(name))[1] = auth.uid()::text
);

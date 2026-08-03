-- ============================================================
--  Gestão Obras C08 — recriar a base no Supabase
--  SQL Editor > New query > cole tudo > Run.
--  Pode rodar quantas vezes quiser: não apaga nada que já exista.
--  "Success. No rows returned" é o resultado esperado.
-- ============================================================

-- 1) Tabela onde ficam os dados da obra (um registro por usuário)
create table if not exists obra_dados (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null unique,
  dados jsonb not null,
  updated_at timestamptz default now()
);

-- 2) Trava de segurança: cada conta só enxerga o próprio registro
alter table obra_dados enable row level security;

drop policy if exists "cada usuario so ve e edita o proprio registro" on obra_dados;
create policy "cada usuario so ve e edita o proprio registro"
  on obra_dados
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 3) Espaço para os arquivos das notas fiscais (PDF, XML, foto)
insert into storage.buckets (id, name, public)
values ('notas', 'notas', false)
on conflict (id) do nothing;

drop policy if exists "notas ler proprios arquivos" on storage.objects;
create policy "notas ler proprios arquivos"
on storage.objects for select to authenticated
using (bucket_id = 'notas' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "notas enviar proprios arquivos" on storage.objects;
create policy "notas enviar proprios arquivos"
on storage.objects for insert to authenticated
with check (bucket_id = 'notas' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "notas atualizar proprios arquivos" on storage.objects;
create policy "notas atualizar proprios arquivos"
on storage.objects for update to authenticated
using (bucket_id = 'notas' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'notas' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "notas apagar proprios arquivos" on storage.objects;
create policy "notas apagar proprios arquivos"
on storage.objects for delete to authenticated
using (bucket_id = 'notas' and (storage.foldername(name))[1] = auth.uid()::text);

-- 4) Confirmação
select 'tabela obra_dados e espaco de notas prontos' as resultado;

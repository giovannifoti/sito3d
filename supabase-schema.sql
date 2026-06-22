-- artigianidel3d — Database, autenticazione e Storage
-- Eseguire questo file nel SQL Editor del progetto Supabase.

begin;

-- -----------------------------------------------------------------------------
-- 1. Tabelle
-- -----------------------------------------------------------------------------

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

comment on table public.admin_users is
  'Allowlist degli utenti autorizzati a gestire il catalogo.';

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 80),
  description text not null check (char_length(description) between 1 and 500),
  price numeric(10, 2) not null check (price >= 0),
  price_from boolean not null default false,
  image_path text not null check (char_length(image_path) > 0),
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.products is
  'Catalogo pubblico dei prodotti artigianidel3d. Le immagini risiedono nel bucket product-images.';

create index if not exists products_created_at_idx
  on public.products (created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 2. Permessi e Row Level Security
-- -----------------------------------------------------------------------------

alter table public.admin_users enable row level security;
alter table public.products enable row level security;

revoke all on table public.admin_users from anon, authenticated;
grant select on table public.admin_users to authenticated;

revoke all on table public.products from anon, authenticated;
grant select on table public.products to anon, authenticated;
grant insert, update, delete on table public.products to authenticated;

drop policy if exists "admin_users_read_self" on public.admin_users;
create policy "admin_users_read_self"
on public.admin_users
for select
to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "products_public_read" on public.products;
create policy "products_public_read"
on public.products
for select
to anon, authenticated
using (true);

drop policy if exists "products_admin_insert" on public.products;
create policy "products_admin_insert"
on public.products
for insert
to authenticated
with check (
  exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
  )
);

drop policy if exists "products_admin_update" on public.products;
create policy "products_admin_update"
on public.products
for update
to authenticated
using (
  exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
  )
);

drop policy if exists "products_admin_delete" on public.products;
create policy "products_admin_delete"
on public.products
for delete
to authenticated
using (
  exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
  )
);

-- -----------------------------------------------------------------------------
-- 3. Bucket pubblico per le immagini
--    La lettura è pubblica; upload e cancellazione restano riservati agli admin.
-- -----------------------------------------------------------------------------

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "product_images_admin_insert" on storage.objects;
create policy "product_images_admin_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
  )
);

drop policy if exists "product_images_admin_delete" on storage.objects;
create policy "product_images_admin_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
  )
);

commit;

-- -----------------------------------------------------------------------------
-- 4. DOPO aver creato il tuo utente in Authentication > Users:
--    sostituisci l'indirizzo e lancia SOLO questa query nel SQL Editor.
-- -----------------------------------------------------------------------------
-- insert into public.admin_users (user_id)
-- select id from auth.users where lower(email) = lower('TUO-INDIRIZZO-EMAIL')
-- on conflict (user_id) do nothing
-- returning user_id;

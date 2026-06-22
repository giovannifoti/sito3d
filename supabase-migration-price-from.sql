-- artigianidel3d — aggiunge l'opzione "A partire da" ai prezzi.
-- Eseguire una sola volta nel SQL Editor di Supabase come ruolo postgres.

alter table public.products
add column if not exists price_from boolean not null default false;

comment on column public.products.price_from is
  'Se true, il prezzo viene mostrato con la dicitura A partire da.';


-- ============================================================================
-- NeumoAI-D · Supabase schema (ALIGNED with NeumoAIweb website schema)
--
-- Website dokter sudah punya skema `screenings` (lihat NeumoAIweb/supabase/
-- migrations/0001_init.sql). Agar skrining dari aplikasi Flutter muncul di
-- website dokter, tabel & kolom di bawah HARUS konsisten dengan skema website.
--
-- Jalankan di Supabase SQL Editor (Dashboard → SQL → New query → Run)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tabel screenings (sama dengan skema website dokter)
--    id = UUID (bukan teks); status pakai kata-kunci awaiting/accepted/...
-- ---------------------------------------------------------------------------
create table if not exists public.screenings (
  id uuid primary key default gen_random_uuid(),
  child_id text not null,
  child_name text,
  user_id uuid references auth.users (id) on delete cascade,
  date timestamptz not null default now(),
  symptoms text[] default '{}',
  audio_duration numeric default 5,
  risk_level text check (risk_level in ('low', 'medium', 'high')),
  disease text,
  confidence numeric,
  audio_url text,
  status text not null default 'awaiting'
    check (status in ('awaiting', 'accepted', 'rejected', 'done')),
  outcome text,
  model_version text default 'v2.4',
  trend numeric[] default '{}',
  vitals jsonb default '{}',
  created_at timestamptz not null default now()
);

alter table public.screenings enable row level security;

-- Dokter (website) bisa membaca semua skrining.
drop policy if exists "screenings_read_all" on public.screenings;
create policy "screenings_read_all" on public.screenings
  for select using (true);

-- Pasien (aplikasi) bisa membuat skrining. Untuk demo skripsi, izinkan anon
-- insert (tanpa akun). Ganti ke `auth.uid() = user_id` bila sudah pakai
-- Supabase Auth di aplikasi.
drop policy if exists "screenings_insert_public" on public.screenings;
create policy "screenings_insert_public" on public.screenings
  for insert with check (true);

-- Dokter bisa memperbarui status/outcome skrining.
drop policy if exists "screenings_update_all" on public.screenings;
create policy "screenings_update_all" on public.screenings
  for update using (true);

create index if not exists screenings_child_id_idx on public.screenings (child_id);
create index if not exists screenings_date_idx on public.screenings (date desc);

-- ---------------------------------------------------------------------------
-- 2. Storage bucket "audio" — di website memakai bucket private + signed URL.
--    Untuk demo skripsi, buat public agar aplikasi bisa upload & dokter bisa
--    putar langsung. Ganti ke restricted bila sudah pakai Auth.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('audio', 'audio', true)
on conflict (id) do nothing;

drop policy if exists "audio_read_public" on storage.objects;
create policy "audio_read_public" on storage.objects
  for select using (bucket_id = 'audio');

drop policy if exists "audio_insert_public" on storage.objects;
create policy "audio_insert_public" on storage.objects
  for insert with check (bucket_id = 'audio');

-- ============================================================================
-- Selesai. Setelah menjalankan, isi kredensial di Flutter:
--   flutter run --dart-define=SUPABASE_URL=<URL> --dart-define=SUPABASE_ANON_KEY=<ANON>
-- ============================================================================

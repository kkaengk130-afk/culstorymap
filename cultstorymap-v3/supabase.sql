create extension if not exists pgcrypto;
create table if not exists public.admin_users(user_id uuid primary key references auth.users(id) on delete cascade);
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.admin_users where user_id=auth.uid()) $$;
revoke all on function public.is_admin() from public; grant execute on function public.is_admin() to anon,authenticated;
create table if not exists public.posts(id uuid primary key default gen_random_uuid(),visit_date date not null,record_date date not null default current_date,content_type text not null,subject text not null,place text default '',companions text default '혼자',title text not null,related_url text,tags text[] default '{}',images text[] default '{}',note_html text default '',published boolean default true,author_id uuid references auth.users(id),created_at timestamptz default now(),updated_at timestamptz default now());
create table if not exists public.seeds(id uuid primary key default gen_random_uuid(),post_id uuid not null references public.posts(id) on delete cascade,title text not null,body text default '',sort_order int default 0);
create table if not exists public.works(id uuid primary key default gen_random_uuid(),post_id uuid not null references public.posts(id) on delete cascade,title text not null,description text default '',url text,sort_order int default 0);
create table if not exists public.site_settings(id int primary key check(id=1),brand text,sub text,headline text,motto text,profile text,archive_label text,note_label text,seed_label text,work_label text);
alter table public.admin_users enable row level security;alter table public.posts enable row level security;alter table public.seeds enable row level security;alter table public.works enable row level security;alter table public.site_settings enable row level security;
create policy "admin can see own role" on public.admin_users for select to authenticated using(user_id=auth.uid());
create policy "public reads published posts" on public.posts for select to anon,authenticated using(published=true or public.is_admin());
create policy "admin inserts posts" on public.posts for insert to authenticated with check(public.is_admin() and author_id=auth.uid());
create policy "admin updates posts" on public.posts for update to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "admin deletes posts" on public.posts for delete to authenticated using(public.is_admin());
create policy "public reads published seeds" on public.seeds for select to anon,authenticated using(exists(select 1 from public.posts p where p.id=post_id and (p.published or public.is_admin())));
create policy "admin manages seeds" on public.seeds for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "public reads published works" on public.works for select to anon,authenticated using(exists(select 1 from public.posts p where p.id=post_id and (p.published or public.is_admin())));
create policy "admin manages works" on public.works for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "everyone reads settings" on public.site_settings for select to anon,authenticated using(true);
create policy "admin manages settings" on public.site_settings for all to authenticated using(public.is_admin()) with check(public.is_admin());
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('archive-images','archive-images',true,6291456,array['image/webp','image/jpeg','image/png']) on conflict(id) do update set public=true,file_size_limit=6291456;
create policy "public reads archive images" on storage.objects for select to anon,authenticated using(bucket_id='archive-images');
create policy "admin uploads own folder" on storage.objects for insert to authenticated with check(bucket_id='archive-images' and public.is_admin() and (storage.foldername(name))[1]=auth.uid()::text);
create policy "admin updates own folder" on storage.objects for update to authenticated using(bucket_id='archive-images' and public.is_admin() and (storage.foldername(name))[1]=auth.uid()::text);
create policy "admin deletes own folder" on storage.objects for delete to authenticated using(bucket_id='archive-images' and public.is_admin() and (storage.foldername(name))[1]=auth.uid()::text);
insert into public.site_settings values(1,'컬스토리맵','CULTURE × (HI)STORY','경험에서 콘텐츠까지, 생각의 이동 경로','관찰해서 시작해<br>콘텐츠로 완성되는 기록들','동덕여자대학교 이서진<br>문예창작학 · 국사학 · 문화예술경영학<br>2gongi@naver.com','ARCHIVE','NOTE','SEED','WORK') on conflict(id) do nothing;

-- WORK 첨부파일
create table if not exists public.work_files(
  id uuid primary key default gen_random_uuid(),
  work_id uuid not null references public.works(id) on delete cascade,
  file_name text not null,
  file_url text not null,
  storage_path text not null,
  file_type text default '',
  file_size bigint default 0,
  created_at timestamptz default now()
);
alter table public.work_files enable row level security;
create policy "public reads files of published works" on public.work_files for select to anon,authenticated using(exists(select 1 from public.works w join public.posts p on p.id=w.post_id where w.id=work_id and (p.published or public.is_admin())));
create policy "admin manages work file metadata" on public.work_files for all to authenticated using(public.is_admin()) with check(public.is_admin());
insert into storage.buckets(id,name,public,file_size_limit) values('work-files','work-files',true,20971520) on conflict(id) do update set public=true,file_size_limit=20971520;
create policy "public downloads work files" on storage.objects for select to anon,authenticated using(bucket_id='work-files');
create policy "admin uploads work files" on storage.objects for insert to authenticated with check(bucket_id='work-files' and public.is_admin() and (storage.foldername(name))[1]=auth.uid()::text);
create policy "admin updates work files" on storage.objects for update to authenticated using(bucket_id='work-files' and public.is_admin() and (storage.foldername(name))[1]=auth.uid()::text);
create policy "admin deletes work files" on storage.objects for delete to authenticated using(bucket_id='work-files' and public.is_admin() and (storage.foldername(name))[1]=auth.uid()::text);

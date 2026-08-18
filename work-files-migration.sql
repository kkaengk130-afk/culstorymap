-- 이미 v3를 Supabase에 설치했다면 이 파일만 SQL Editor에서 1회 실행하세요.
create table if not exists public.work_files(id uuid primary key default gen_random_uuid(),work_id uuid not null references public.works(id) on delete cascade,file_name text not null,file_url text not null,storage_path text not null,file_type text default '',file_size bigint default 0,created_at timestamptz default now());
alter table public.work_files enable row level security;
create policy "public reads files of published works" on public.work_files for select to anon,authenticated using(exists(select 1 from public.works w join public.posts p on p.id=w.post_id where w.id=work_id and (p.published or public.is_admin())));
create policy "admin manages work file metadata" on public.work_files for all to authenticated using(public.is_admin()) with check(public.is_admin());
insert into storage.buckets(id,name,public,file_size_limit) values('work-files','work-files',true,20971520) on conflict(id) do update set public=true,file_size_limit=20971520;
create policy "public downloads work files" on storage.objects for select to anon,authenticated using(bucket_id='work-files');
create policy "admin uploads work files" on storage.objects for insert to authenticated with check(bucket_id='work-files' and public.is_admin() and (storage.foldername(name))[1]=auth.uid()::text);
create policy "admin updates work files" on storage.objects for update to authenticated using(bucket_id='work-files' and public.is_admin() and (storage.foldername(name))[1]=auth.uid()::text);
create policy "admin deletes work files" on storage.objects for delete to authenticated using(bucket_id='work-files' and public.is_admin() and (storage.foldername(name))[1]=auth.uid()::text);

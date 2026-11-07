-- Additive migration: keeps public.wines, staff_profiles and existing records.
begin;
create table if not exists public.location_specials (
 id uuid primary key default gen_random_uuid(),
 location text not null check(location in ('Upper West Side','Manhattan West','Union Square','NoMad')),
 name text not null,
 category text not null default 'Red',
 price numeric(10,2) check(price>=0),
 presentation text,
 is_available boolean not null default true,
 created_at timestamptz not null default now()
);
alter table public.location_specials add column if not exists kind text not null default 'wine';
do $$ begin
 if not exists (select 1 from pg_constraint where conrelid='public.location_specials'::regclass and conname='wg_special_kind_location') then
  alter table public.location_specials add constraint wg_special_kind_location
   check (kind in ('wine','cocktail') and (kind <> 'cocktail' or location='Union Square'));
 end if;
end $$;
create index if not exists wg_specials_location_kind on public.location_specials(location,kind);
alter table public.location_specials enable row level security;
create or replace function public.wg_active_role() returns text language sql stable security definer set search_path=public as $$
 select role::text from public.staff_profiles where id=auth.uid() and is_active=true limit 1
$$;
revoke all on function public.wg_active_role() from public;
grant execute on function public.wg_active_role() to authenticated;
drop policy if exists wg_specials_read on public.location_specials;
create policy wg_specials_read on public.location_specials for select to authenticated using(public.wg_active_role() in ('owner','manager','staff'));
drop policy if exists wg_specials_insert on public.location_specials;
create policy wg_specials_insert on public.location_specials for insert to authenticated with check(public.wg_active_role() in ('owner','manager'));
drop policy if exists wg_specials_update on public.location_specials;
create policy wg_specials_update on public.location_specials for update to authenticated using(public.wg_active_role() in ('owner','manager')) with check(public.wg_active_role() in ('owner','manager'));
drop policy if exists wg_specials_delete on public.location_specials;
create policy wg_specials_delete on public.location_specials for delete to authenticated using(public.wg_active_role() in ('owner','manager'));
-- Restrictive policy also protects against other permissive write policies.
drop policy if exists wg_specials_write_guard on public.location_specials;
create policy wg_specials_write_guard on public.location_specials as restrictive for all to authenticated
 using(public.wg_active_role() in ('owner','manager','staff'))
 with check(public.wg_active_role() in ('owner','manager'));
drop policy if exists wg_specials_delete_guard on public.location_specials;
create policy wg_specials_delete_guard on public.location_specials as restrictive for delete to authenticated using(public.wg_active_role() in ('owner','manager'));
drop policy if exists wg_specials_update_guard on public.location_specials;
create policy wg_specials_update_guard on public.location_specials as restrictive for update to authenticated using(public.wg_active_role() in ('owner','manager')) with check(public.wg_active_role() in ('owner','manager'));
grant select,insert,update,delete on public.location_specials to authenticated;
-- Owners manage existing staff profiles. Authentication accounts remain in Supabase Auth.
alter table public.staff_profiles enable row level security;
drop policy if exists wg_owner_profiles_read on public.staff_profiles;
create policy wg_owner_profiles_read on public.staff_profiles for select to authenticated using(public.wg_active_role()='owner');
drop policy if exists wg_owner_profiles_update on public.staff_profiles;
create policy wg_owner_profiles_update on public.staff_profiles for update to authenticated using(public.wg_active_role()='owner') with check(public.wg_active_role()='owner');
grant update(role,is_active) on public.staff_profiles to authenticated;
-- Prevent self-service role/activation changes even if a legacy self-update policy exists.
create or replace function public.wg_protect_profile_access() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if auth.role()='authenticated' then
  if (new.role is distinct from old.role or new.is_active is distinct from old.is_active)
    and public.wg_active_role() is distinct from 'owner' then
   raise exception 'Only an active owner can change employee access';
  end if;
  if old.role::text='owner' and (new.role is distinct from old.role or new.is_active is distinct from old.is_active) then
   raise exception 'Owner access must be managed in Supabase';
  end if;
 end if;
 return new;
end $$;
drop trigger if exists wg_protect_profile_access on public.staff_profiles;
create trigger wg_protect_profile_access before update on public.staff_profiles for each row execute function public.wg_protect_profile_access();
commit;

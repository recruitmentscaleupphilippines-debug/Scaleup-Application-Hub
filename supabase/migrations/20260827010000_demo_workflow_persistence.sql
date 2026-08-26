-- Recruitment Hub demo workflow persistence and 30-day recycle bin.
-- All seeded records are synthetic and explicitly tagged as demo data.

create schema if not exists private;
create extension if not exists pg_cron with schema pg_catalog;

create or replace function private.is_hub_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.team_members
    where id = (select auth.uid()) and active and role = 'admin'
  );
$$;
revoke all on function private.is_hub_admin() from public;
grant execute on function private.is_hub_admin() to authenticated;

alter table public.candidates
  add column if not exists is_demo boolean not null default false,
  add column if not exists archived_at timestamptz,
  add column if not exists purge_after timestamptz,
  add column if not exists archived_by uuid references public.team_members(id) on delete set null;

alter table public.job_requisitions
  add column if not exists is_demo boolean not null default false,
  add column if not exists jd_url text,
  add column if not exists openings integer not null default 1 check (openings > 0),
  add column if not exists priority text not null default 'Medium' check (priority in ('Low','Medium','High','Urgent')),
  add column if not exists target_start_date date,
  add column if not exists sales_owner text,
  add column if not exists handoff_status text not null default 'Awaiting Recruitment Review',
  add column if not exists archived_at timestamptz,
  add column if not exists purge_after timestamptz,
  add column if not exists archived_by uuid references public.team_members(id) on delete set null,
  add column if not exists updated_at timestamptz not null default now();

alter table public.applications
  add column if not exists is_demo boolean not null default false,
  add column if not exists acknowledged_at timestamptz,
  add column if not exists archived_at timestamptz,
  add column if not exists purge_after timestamptz,
  add column if not exists archived_by uuid references public.team_members(id) on delete set null;

alter table public.communications
  add column if not exists is_demo boolean not null default false,
  add column if not exists archived_at timestamptz,
  add column if not exists purge_after timestamptz,
  add column if not exists archived_by uuid references public.team_members(id) on delete set null;

create table if not exists public.hub_records (
  id uuid primary key default gen_random_uuid(),
  record_type text not null check (record_type in (
    'referral','interview','active_pool','offer','onboarding','task',
    'notification','template','report','vacancy_checklist','email_outbox'
  )),
  title text not null,
  subtitle text,
  status text not null default 'Draft',
  owner_id uuid references public.team_members(id) on delete set null,
  requisition_id uuid references public.job_requisitions(id) on delete cascade,
  candidate_id uuid references public.candidates(id) on delete cascade,
  application_id uuid references public.applications(id) on delete cascade,
  parent_id uuid references public.hub_records(id) on delete cascade,
  due_at timestamptz,
  details jsonb not null default '{}'::jsonb,
  is_demo boolean not null default true,
  created_by uuid references public.team_members(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  purge_after timestamptz,
  archived_by uuid references public.team_members(id) on delete set null,
  constraint hub_records_archive_window check (
    (archived_at is null and purge_after is null) or
    (archived_at is not null and purge_after is not null and purge_after >= archived_at)
  )
);

create table if not exists public.internal_comments (
  id uuid primary key default gen_random_uuid(),
  requisition_id uuid references public.job_requisitions(id) on delete cascade,
  application_id uuid references public.applications(id) on delete cascade,
  hub_record_id uuid references public.hub_records(id) on delete cascade,
  author_id uuid not null references public.team_members(id) on delete restrict default auth.uid(),
  body text not null check (length(trim(body)) > 0),
  is_pinned boolean not null default false,
  is_demo boolean not null default true,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  archived_at timestamptz,
  purge_after timestamptz,
  archived_by uuid references public.team_members(id) on delete set null,
  constraint internal_comments_target check (num_nonnulls(requisition_id, application_id, hub_record_id) = 1)
);

create table if not exists public.audit_events (
  id bigint generated always as identity primary key,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  actor_id uuid references public.team_members(id) on delete set null,
  summary text not null,
  metadata jsonb not null default '{}'::jsonb,
  is_demo boolean not null default true,
  created_at timestamptz not null default now(),
  archived_at timestamptz,
  purge_after timestamptz
);

create index if not exists hub_records_active_type_idx on public.hub_records(record_type, updated_at desc) where archived_at is null;
create index if not exists hub_records_requisition_idx on public.hub_records(requisition_id) where archived_at is null;
create index if not exists hub_records_application_idx on public.hub_records(application_id) where archived_at is null;
create index if not exists hub_records_purge_idx on public.hub_records(purge_after) where purge_after is not null;
create index if not exists comments_requisition_idx on public.internal_comments(requisition_id, created_at) where archived_at is null;
create index if not exists audit_entity_idx on public.audit_events(entity_type, entity_id, created_at desc);
create index if not exists candidates_purge_idx on public.candidates(purge_after) where purge_after is not null;
create index if not exists requisitions_purge_idx on public.job_requisitions(purge_after) where purge_after is not null;
create index if not exists applications_purge_idx on public.applications(purge_after) where purge_after is not null;
create index if not exists applications_archived_by_idx on public.applications(archived_by);
create index if not exists candidates_archived_by_idx on public.candidates(archived_by);
create index if not exists communications_archived_by_idx on public.communications(archived_by);
create index if not exists requisitions_archived_by_idx on public.job_requisitions(archived_by);
create index if not exists hub_records_owner_idx on public.hub_records(owner_id);
create index if not exists hub_records_candidate_idx on public.hub_records(candidate_id);
create index if not exists hub_records_parent_idx on public.hub_records(parent_id);
create index if not exists hub_records_created_by_idx on public.hub_records(created_by);
create index if not exists hub_records_archived_by_idx on public.hub_records(archived_by);
create index if not exists comments_application_idx on public.internal_comments(application_id);
create index if not exists comments_hub_record_idx on public.internal_comments(hub_record_id);
create index if not exists comments_author_idx on public.internal_comments(author_id);
create index if not exists comments_archived_by_idx on public.internal_comments(archived_by);
create index if not exists audit_actor_idx on public.audit_events(actor_id);

drop trigger if exists touch_hub_records_updated_at on public.hub_records;
create trigger touch_hub_records_updated_at before update on public.hub_records
for each row execute function public.touch_updated_at();

drop trigger if exists touch_job_requisitions_updated_at on public.job_requisitions;
create trigger touch_job_requisitions_updated_at before update on public.job_requisitions
for each row execute function public.touch_updated_at();

alter table public.hub_records enable row level security;
alter table public.internal_comments enable row level security;
alter table public.audit_events enable row level security;

drop policy if exists "active team read hub records" on public.hub_records;
create policy "active team read hub records" on public.hub_records for select to authenticated
using ((select private.is_active_team_member()));
drop policy if exists "active team create hub records" on public.hub_records;
create policy "active team create hub records" on public.hub_records for insert to authenticated
with check ((select private.is_active_team_member()) and created_by = (select auth.uid()));
drop policy if exists "active team update hub records" on public.hub_records;
create policy "active team update hub records" on public.hub_records for update to authenticated
using ((select private.is_active_team_member()))
with check ((select private.is_active_team_member()));
drop policy if exists "admin permanently deletes hub records" on public.hub_records;
create policy "admin permanently deletes hub records" on public.hub_records for delete to authenticated
using ((select private.is_hub_admin()) and purge_after <= now());

drop policy if exists "active team read comments" on public.internal_comments;
create policy "active team read comments" on public.internal_comments for select to authenticated
using ((select private.is_active_team_member()));
drop policy if exists "active team create comments" on public.internal_comments;
create policy "active team create comments" on public.internal_comments for insert to authenticated
with check ((select private.is_active_team_member()) and author_id = (select auth.uid()));
drop policy if exists "comment author updates comments" on public.internal_comments;
create policy "comment author updates comments" on public.internal_comments for update to authenticated
using ((select private.is_active_team_member()) and (author_id = (select auth.uid()) or (select private.is_hub_admin())))
with check ((select private.is_active_team_member()));
drop policy if exists "admin permanently deletes comments" on public.internal_comments;
create policy "admin permanently deletes comments" on public.internal_comments for delete to authenticated
using ((select private.is_hub_admin()) and purge_after <= now());

drop policy if exists "active team read audit" on public.audit_events;
create policy "active team read audit" on public.audit_events for select to authenticated
using ((select private.is_active_team_member()));
drop policy if exists "active team create audit" on public.audit_events;
create policy "active team create audit" on public.audit_events for insert to authenticated
with check ((select private.is_active_team_member()) and actor_id = (select auth.uid()));

grant select, insert, update, delete on public.hub_records to authenticated;
grant select, insert, update, delete on public.internal_comments to authenticated;
grant select, insert on public.audit_events to authenticated;
grant usage, select on sequence public.audit_events_id_seq to authenticated;
revoke all on public.hub_records, public.internal_comments, public.audit_events from anon;

-- Existing core tables previously used broad ALL policies. Keep normal CRUD but
-- prevent authenticated users from bypassing the recycle bin with direct DELETE.
drop policy if exists "team manage applications" on public.applications;
create policy "team read applications" on public.applications for select to authenticated using ((select private.is_active_team_member()));
create policy "team create applications" on public.applications for insert to authenticated with check ((select private.is_active_team_member()));
create policy "team update applications" on public.applications for update to authenticated using ((select private.is_active_team_member())) with check ((select private.is_active_team_member()));
create policy "admin delete expired demo applications" on public.applications for delete to authenticated using ((select private.is_hub_admin()) and is_demo and purge_after <= now());

drop policy if exists "team manage candidates" on public.candidates;
create policy "team read candidates" on public.candidates for select to authenticated using ((select private.is_active_team_member()));
create policy "team create candidates" on public.candidates for insert to authenticated with check ((select private.is_active_team_member()));
create policy "team update candidates" on public.candidates for update to authenticated using ((select private.is_active_team_member())) with check ((select private.is_active_team_member()));
create policy "admin delete expired demo candidates" on public.candidates for delete to authenticated using ((select private.is_hub_admin()) and is_demo and purge_after <= now());

drop policy if exists "team manage communications" on public.communications;
create policy "team read communications" on public.communications for select to authenticated using ((select private.is_active_team_member()));
create policy "team create communications" on public.communications for insert to authenticated with check ((select private.is_active_team_member()));
create policy "team update communications" on public.communications for update to authenticated using ((select private.is_active_team_member())) with check ((select private.is_active_team_member()));
create policy "admin delete expired demo communications" on public.communications for delete to authenticated using ((select private.is_hub_admin()) and is_demo and purge_after <= now());

drop policy if exists "lead delete jobs" on public.job_requisitions;
create policy "admin delete expired demo jobs" on public.job_requisitions for delete to authenticated using ((select private.is_hub_admin()) and is_demo and purge_after <= now());

create or replace function public.archive_hub_record(target_id uuid)
returns public.hub_records
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare archived public.hub_records;
begin
  update public.hub_records
  set archived_at = now(), purge_after = now() + interval '30 days', archived_by = (select auth.uid())
  where id = target_id and archived_at is null
  returning * into archived;
  if archived.id is null then raise exception 'Record not found or already archived'; end if;
  insert into public.audit_events(entity_type, entity_id, action, actor_id, summary, is_demo)
  values (archived.record_type, archived.id, 'archived', (select auth.uid()), 'Archived for 30-day recovery', archived.is_demo);
  return archived;
end;
$$;
grant execute on function public.archive_hub_record(uuid) to authenticated;

create or replace function public.restore_hub_record(target_id uuid)
returns public.hub_records
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare restored public.hub_records;
begin
  update public.hub_records
  set archived_at = null, purge_after = null, archived_by = null
  where id = target_id and archived_at is not null and purge_after > now()
  returning * into restored;
  if restored.id is null then raise exception 'Record is unavailable for restoration'; end if;
  insert into public.audit_events(entity_type, entity_id, action, actor_id, summary, is_demo)
  values (restored.record_type, restored.id, 'restored', (select auth.uid()), 'Restored from archive', restored.is_demo);
  return restored;
end;
$$;
grant execute on function public.restore_hub_record(uuid) to authenticated;

create or replace function private.purge_expired_hub_data()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare result jsonb;
begin
  with deleted as (delete from public.hub_records where is_demo and purge_after <= now() returning 1)
  select jsonb_build_object('hub_records', count(*)) into result from deleted;
  delete from public.internal_comments where is_demo and purge_after <= now();
  delete from public.communications where is_demo and purge_after <= now();
  delete from public.applications where is_demo and purge_after <= now();
  delete from public.candidates where is_demo and purge_after <= now();
  delete from public.job_requisitions where is_demo and purge_after <= now();
  delete from public.audit_events where is_demo and purge_after <= now();
  return result;
end;
$$;
revoke all on function private.purge_expired_hub_data() from public, anon, authenticated;

select cron.schedule(
  'recruitment-hub-30-day-purge',
  '15 18 * * *',
  $$select private.purge_expired_hub_data();$$
)
where not exists (select 1 from cron.job where jobname = 'recruitment-hub-30-day-purge');

-- Synthetic demo seed. Safe to run repeatedly.
insert into public.job_requisitions (
  requisition_code, position_title, client_name, work_setup, location, schedule,
  status, owner_id, is_demo, openings, priority, target_start_date, sales_owner,
  handoff_status, jd_url
)
select 'DEMO-SDR-001', 'Sales Development Representative', 'Demo Client A', 'Remote',
  'Philippines', 'US business hours', 'Open', id, true, 2, 'High', current_date + 30,
  'Demo Sales Owner', 'Approved for Recruitment', '/demo-jd?position=Sales%20Development%20Representative'
from public.team_members where active order by case role when 'lead' then 0 when 'admin' then 1 else 2 end limit 1
on conflict (requisition_code) do nothing;

insert into public.job_requisitions (
  requisition_code, position_title, client_name, work_setup, location, schedule,
  status, owner_id, is_demo, openings, priority, target_start_date, sales_owner,
  handoff_status, jd_url
)
select 'DEMO-MB-002', 'Medical Biller – Orthopedic', 'Demo Client B', 'Hybrid',
  'Bulakan, Bulacan', 'Night shift', 'Open', id, true, 1, 'Medium', current_date + 45,
  'Demo Sales Owner', 'Awaiting Recruitment Review', '/demo-jd?position=Medical%20Biller'
from public.team_members where active order by case role when 'lead' then 0 when 'admin' then 1 else 2 end limit 1
on conflict (requisition_code) do nothing;

insert into public.candidates(full_name,email,mobile,location,preferred_work_setup,consent_at,is_demo)
values
  ('Demo Candidate 01','candidate01@example.test','+63 900 000 0001','Bulacan','Remote',now(),true),
  ('Demo Candidate 02','candidate02@example.test','+63 900 000 0002','Metro Manila','Hybrid',now(),true),
  ('Demo Candidate 03','candidate03@example.test','+63 900 000 0003','Pampanga','Remote',now(),true)
on conflict do nothing;

insert into public.applications(candidate_id,requisition_id,source,status,owner_id,next_action,next_action_due,is_demo,acknowledged_at,last_communication_at)
select c.id, r.id, x.source, x.status::public.application_status, r.owner_id, x.next_action, now() + x.due, true, x.ack_at, x.ack_at
from (values
  ('Demo Candidate 01','DEMO-SDR-001','LinkedIn','New Application','Review application',interval '4 hours',null::timestamptz),
  ('Demo Candidate 02','DEMO-MB-002','Referral','Screening in Progress','Complete phone screening',interval '1 day',now()),
  ('Demo Candidate 03','DEMO-SDR-001','Google Forms','Awaiting Client Feedback','Send holding update',interval '2 days',now())
) as x(candidate_name,req_code,source,status,next_action,due,ack_at)
join public.candidates c on c.full_name=x.candidate_name and c.is_demo
join public.job_requisitions r on r.requisition_code=x.req_code
where not exists (select 1 from public.applications a where a.candidate_id=c.id and a.requisition_id=r.id);

insert into public.hub_records(record_type,title,subtitle,status,owner_id,requisition_id,candidate_id,application_id,due_at,details,is_demo,created_by)
select x.record_type,x.title,x.subtitle,x.status,r.owner_id,r.id,c.id,a.id,now()+x.due,x.details,true,r.owner_id
from (values
 ('referral','Demo Candidate 02','Employee referral','New referral','DEMO-MB-002','Demo Candidate 02',interval '1 day','{"referred_by":"Demo Team Member","next_action":"Review referral"}'::jsonb),
 ('interview','Demo Candidate 02','Internal interview','Awaiting buddy review','DEMO-MB-002','Demo Candidate 02',interval '2 days','{"buddy":"Demo Recruitment Lead","interviewer":"Demo Recruiter","rating":"Pending"}'::jsonb),
 ('active_pool','Demo Candidate 03','Sales and lead generation','Active','DEMO-SDR-001','Demo Candidate 03',interval '30 days','{"availability":"Available","reconfirm_days":30}'::jsonb),
 ('offer','Demo Candidate 01','Sales Development Representative','Draft','DEMO-SDR-001','Demo Candidate 01',interval '5 days','{"rate_check":"Pending authorized review","approver":"Demo Administrator"}'::jsonb),
 ('onboarding','Demo Candidate 01','Conditional offer checklist','2 of 4 complete','DEMO-SDR-001','Demo Candidate 01',interval '10 days','{"access":"Restricted","documents":["NDA","Contract","ID link","NBI link"]}'::jsonb),
 ('task','Review new requisition DEMO-MB-002','Sales handoff review','Open','DEMO-MB-002',null,interval '1 day','{"priority":"High","category":"Handoff"}'::jsonb),
 ('notification','New requisition handoff','DEMO-MB-002 requires review','Unread','DEMO-MB-002',null,interval '1 day','{"level":"Action required"}'::jsonb),
 ('template','Pre-call availability message','Calling','Active','DEMO-SDR-001',null,interval '365 days','{"channel":"SMS / Email","editable":true}'::jsonb),
 ('report','Weekly recruitment operations','Current demo period','Ready','DEMO-SDR-001',null,interval '7 days','{"format":"CSV","scope":"Demo only"}'::jsonb),
 ('vacancy_checklist','DEMO-SDR-001 closure checklist','Vacancy closure','Not started','DEMO-SDR-001',null,interval '30 days','{"items":["Candidates informed","Active pool identified","Job posts closed","Form closed","Client informed","Report completed"]}'::jsonb)
) as x(record_type,title,subtitle,status,req_code,candidate_name,due,details)
join public.job_requisitions r on r.requisition_code=x.req_code
left join public.candidates c on c.full_name=x.candidate_name and c.is_demo
left join public.applications a on a.candidate_id=c.id and a.requisition_id=r.id
where not exists (select 1 from public.hub_records h where h.record_type=x.record_type and h.title=x.title and h.is_demo);

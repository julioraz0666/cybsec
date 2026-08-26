
create extension if not exists pgcrypto;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null default '', username text not null unique, email text not null,
 university text, study_level text,
 role text not null default 'member' check(role in('member','trainer','organizer','admin')),
 status text not null default 'PENDING' check(status in('PENDING','ACTIVE','SUSPENDED','REJECTED')),
 invite_verified boolean not null default false, xp integer not null default 0, level integer not null default 1,
 last_seen timestamptz, created_at timestamptz not null default now()
);
create table if not exists private.app_settings(id integer primary key check(id=1),invite_code text not null,maintenance boolean not null default false,registrations_open boolean not null default true);
insert into private.app_settings(id,invite_code) values(1,'CYBER-ENI-2026') on conflict(id) do nothing;

create table if not exists public.courses(id uuid primary key default gen_random_uuid(),slug text unique not null,title text not null,description text,level text not null default 'Débutant',icon text not null default '📘',published boolean not null default true,created_by uuid references public.profiles(id),created_at timestamptz default now());
create table if not exists public.lessons(id uuid primary key default gen_random_uuid(),course_id uuid not null references public.courses(id) on delete cascade,position integer not null,title text not null,content text,xp_reward integer not null default 20);
create table if not exists public.lesson_progress(user_id uuid not null references public.profiles(id) on delete cascade,lesson_id uuid not null references public.lessons(id) on delete cascade,completed_at timestamptz default now(),primary key(user_id,lesson_id));

create table if not exists public.quizzes(id uuid primary key default gen_random_uuid(),course_id uuid unique not null references public.courses(id) on delete cascade,title text not null,xp_reward integer not null default 80);
create table if not exists public.quiz_questions(id uuid primary key default gen_random_uuid(),quiz_id uuid not null references public.quizzes(id) on delete cascade,position integer not null,question text not null,options jsonb not null);
create table if not exists private.quiz_answers(question_id uuid primary key references public.quiz_questions(id) on delete cascade,answer_index integer not null);
create table if not exists public.quiz_results(user_id uuid not null references public.profiles(id) on delete cascade,quiz_id uuid not null references public.quizzes(id) on delete cascade,score integer not null,total integer not null,passed boolean not null,completed_at timestamptz default now(),primary key(user_id,quiz_id));

create table if not exists public.challenges(
 id uuid primary key default gen_random_uuid(),slug text unique not null,title text not null,category text not null,
 difficulty text not null default 'Easy' check(difficulty in('Easy','Medium','Hard')),
 base_points integer not null,min_points integer not null default 50,dynamic_enabled boolean not null default false,
 description text not null,hint text,published boolean not null default true,training_enabled boolean not null default true,
 lab_url text,created_by uuid references public.profiles(id),created_at timestamptz default now()
);
create table if not exists private.challenge_secrets(challenge_id uuid primary key references public.challenges(id) on delete cascade,flag text not null);
create table if not exists public.challenge_files(id uuid primary key default gen_random_uuid(),challenge_id uuid not null references public.challenges(id) on delete cascade,original_name text not null,storage_path text not null,created_at timestamptz default now());
create table if not exists public.writeups(id uuid primary key default gen_random_uuid(),challenge_id uuid unique not null references public.challenges(id) on delete cascade,title text not null,content text not null,published boolean not null default true,unlock_after timestamptz);

create table if not exists public.seasons(id uuid primary key default gen_random_uuid(),title text not null,starts_at timestamptz not null,ends_at timestamptz not null,is_active boolean not null default false,created_at timestamptz default now());
create table if not exists public.ctf_events(id uuid primary key default gen_random_uuid(),season_id uuid references public.seasons(id) on delete set null,title text not null,description text,starts_at timestamptz not null,ends_at timestamptz not null,is_open boolean not null default false,team_mode boolean not null default false,created_by uuid references public.profiles(id),created_at timestamptz default now());
create table if not exists public.ctf_event_challenges(event_id uuid not null references public.ctf_events(id) on delete cascade,challenge_id uuid not null references public.challenges(id) on delete cascade,primary key(event_id,challenge_id));
create table if not exists public.ctf_registrations(event_id uuid not null references public.ctf_events(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,registered_at timestamptz default now(),primary key(event_id,user_id));
create table if not exists public.solves(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,challenge_id uuid not null references public.challenges(id) on delete cascade,event_id uuid references public.ctf_events(id) on delete cascade,points integer not null,solved_at timestamptz default now());
create unique index if not exists uq_training_solve on public.solves(user_id,challenge_id) where event_id is null;
create unique index if not exists uq_event_solve on public.solves(user_id,challenge_id,event_id) where event_id is not null;
create table if not exists private.flag_attempts(id bigint generated always as identity primary key,user_id uuid not null references public.profiles(id) on delete cascade,challenge_id uuid not null references public.challenges(id) on delete cascade,event_id uuid references public.ctf_events(id) on delete cascade,submitted_flag text not null,is_correct boolean not null default false,created_at timestamptz default now());
create table if not exists public.hint_usage(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,challenge_id uuid not null references public.challenges(id) on delete cascade,event_id uuid references public.ctf_events(id) on delete cascade,penalty integer not null,used_at timestamptz default now());
create unique index if not exists uq_hint on public.hint_usage(user_id,challenge_id,coalesce(event_id,'00000000-0000-0000-0000-000000000000'::uuid));

create table if not exists public.teams(id uuid primary key default gen_random_uuid(),name text unique not null,join_code text unique not null,captain_id uuid not null references public.profiles(id) on delete cascade,description text,created_at timestamptz default now());
create table if not exists public.team_members(team_id uuid not null references public.teams(id) on delete cascade,user_id uuid unique not null references public.profiles(id) on delete cascade,joined_at timestamptz default now(),primary key(team_id,user_id));
create table if not exists public.announcements(id uuid primary key default gen_random_uuid(),title text not null,body text not null,pinned boolean not null default false,created_by uuid references public.profiles(id),created_at timestamptz default now());
create table if not exists public.notifications(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,title text not null,body text not null,is_read boolean not null default false,created_at timestamptz default now());
create table if not exists private.activity_log(id bigint generated always as identity primary key,user_id uuid references public.profiles(id) on delete set null,action text not null,details text,created_at timestamptz default now());

create or replace function public.current_role() returns text language sql stable security definer set search_path=public as $$select role from public.profiles where id=auth.uid()$$;
create or replace function public.is_active_member() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE' and invite_verified=true)$$;
create or replace function public.has_role(p_roles text[]) returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE' and role=any(p_roles))$$;
create or replace function private.log(p_action text,p_details text default '') returns void language sql security definer set search_path=private as $$insert into private.activity_log(user_id,action,details) values(auth.uid(),p_action,p_details)$$;
create or replace function private.relevel(p_user uuid) returns void language plpgsql security definer set search_path=public as $$declare v integer;begin select xp into v from public.profiles where id=p_user;update public.profiles set level=greatest(1,coalesce(v,0)/500+1) where id=p_user;end$$;
create or replace function private.points_now(p_challenge uuid,p_event uuid default null) returns integer language plpgsql security definer set search_path=public as $$declare c public.challenges%rowtype;n integer;d integer;begin select * into c from public.challenges where id=p_challenge;if c.id is null then return 0;end if;if not c.dynamic_enabled then return c.base_points;end if;if p_event is null then select count(*) into n from public.solves where challenge_id=p_challenge and event_id is null;else select count(*) into n from public.solves where challenge_id=p_challenge and event_id=p_event;end if;d:=greatest(1,(c.base_points-c.min_points)*5/100);return greatest(c.min_points,c.base_points-n*d);end$$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare u text;begin u:=coalesce(nullif(new.raw_user_meta_data->>'username',''),split_part(new.email,'@',1));
begin insert into public.profiles(id,name,username,email,university,study_level) values(new.id,coalesce(new.raw_user_meta_data->>'name',''),u,new.email,new.raw_user_meta_data->>'university',new.raw_user_meta_data->>'study_level');
exception when unique_violation then insert into public.profiles(id,name,username,email,university,study_level) values(new.id,coalesce(new.raw_user_meta_data->>'name',''),u||'-'||substr(new.id::text,1,6),new.email,new.raw_user_meta_data->>'university',new.raw_user_meta_data->>'study_level');end;return new;end$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.get_app_state()
returns jsonb language sql stable security definer set search_path=private as $$
  select jsonb_build_object('maintenance',maintenance,'registrations_open',registrations_open)
  from private.app_settings where id=1
$$;

create or replace function public.apply_membership(p_invite text) returns boolean language plpgsql security definer set search_path=public,private as $$declare x text;o boolean;begin select invite_code,registrations_open into x,o from private.app_settings where id=1;if not o then raise exception 'Inscriptions fermées';end if;if p_invite is distinct from x then raise exception 'Code membre invalide';end if;update public.profiles set invite_verified=true where id=auth.uid();perform private.log('Code membre validé','');return true;end$$;
create or replace function public.touch_last_seen() returns boolean language plpgsql security definer set search_path=public as $$begin update public.profiles set last_seen=now() where id=auth.uid();return true;end$$;
create or replace function public.mark_lesson_complete(p_lesson uuid) returns jsonb language plpgsql security definer set search_path=public,private as $$declare r integer;t text;begin if not public.is_active_member() then raise exception 'Compte actif requis';end if;if exists(select 1 from public.lesson_progress where user_id=auth.uid() and lesson_id=p_lesson) then return jsonb_build_object('new',false);end if;select xp_reward,title into r,t from public.lessons where id=p_lesson;insert into public.lesson_progress values(auth.uid(),p_lesson,now());update public.profiles set xp=xp+r where id=auth.uid();perform private.relevel(auth.uid());perform private.log('Leçon terminée',t);return jsonb_build_object('new',true,'xp',r);end$$;

create or replace function public.submit_quiz(p_quiz uuid,p_answers integer[]) returns jsonb language plpgsql security definer set search_path=public,private as $$
declare q record;i integer:=1;s integer:=0;t integer:=0;ok boolean;reward integer;old_ok boolean:=false;begin
for q in select qq.id,qa.answer_index from public.quiz_questions qq join private.quiz_answers qa on qa.question_id=qq.id where qq.quiz_id=p_quiz order by qq.position loop t:=t+1;if array_length(p_answers,1)>=i and p_answers[i]=q.answer_index then s:=s+1;end if;i:=i+1;end loop;if t=0 then raise exception 'Quiz vide';end if;ok:=s*3>=t*2;select coalesce(passed,false) into old_ok from public.quiz_results where user_id=auth.uid() and quiz_id=p_quiz;insert into public.quiz_results values(auth.uid(),p_quiz,s,t,ok,now()) on conflict(user_id,quiz_id) do update set score=excluded.score,total=excluded.total,passed=excluded.passed,completed_at=now();if ok and not coalesce(old_ok,false) then select xp_reward into reward from public.quizzes where id=p_quiz;update public.profiles set xp=xp+reward where id=auth.uid();perform private.relevel(auth.uid());end if;perform private.log('Quiz terminé',s||'/'||t);return jsonb_build_object('score',s,'total',t,'passed',ok);end$$;

create or replace function public.use_hint(p_challenge uuid,p_event uuid default null) returns jsonb language plpgsql security definer set search_path=public,private as $$
declare c public.challenges%rowtype;h public.hint_usage%rowtype;p integer;begin select * into c from public.challenges where id=p_challenge;select * into h from public.hint_usage where user_id=auth.uid() and challenge_id=p_challenge and event_id is not distinct from p_event;if h.id is not null then return jsonb_build_object('hint',c.hint,'penalty',h.penalty);end if;p:=greatest(5,round(c.base_points*.10));insert into public.hint_usage(user_id,challenge_id,event_id,penalty) values(auth.uid(),p_challenge,p_event,p);perform private.log('Indice utilisé',c.title);return jsonb_build_object('hint',c.hint,'penalty',p);end$$;

create or replace function public.submit_flag(p_challenge uuid,p_flag text,p_event uuid default null) returns jsonb language plpgsql security definer set search_path=public,private as $$
declare c public.challenges%rowtype;f text;ok boolean;n integer;pts integer;pen integer:=0;aw integer;fb boolean;begin
if not public.is_active_member() then raise exception 'Compte actif requis';end if;select * into c from public.challenges where id=p_challenge and published=true;if c.id is null then raise exception 'Challenge introuvable';end if;
if p_event is not null then if not exists(select 1 from public.ctf_events where id=p_event and is_open=true and now() between starts_at and ends_at) then raise exception 'CTF fermé';end if;if not exists(select 1 from public.ctf_registrations where event_id=p_event and user_id=auth.uid()) then raise exception 'Inscription CTF requise';end if;end if;
select count(*) into n from private.flag_attempts where user_id=auth.uid() and challenge_id=p_challenge and created_at>now()-interval '60 seconds';if n>=12 then raise exception 'Trop de tentatives. Attends une minute.';end if;
select flag into f from private.challenge_secrets where challenge_id=p_challenge;ok:=p_flag is not distinct from f;insert into private.flag_attempts(user_id,challenge_id,event_id,submitted_flag,is_correct) values(auth.uid(),p_challenge,p_event,p_flag,ok);
if not ok then perform private.log('Flag incorrect',c.title);return jsonb_build_object('ok',false);end if;
if exists(select 1 from public.solves where user_id=auth.uid() and challenge_id=p_challenge and event_id is not distinct from p_event) then return jsonb_build_object('ok',true,'new_solve',false);end if;
pts:=private.points_now(p_challenge,p_event);select coalesce(penalty,0) into pen from public.hint_usage where user_id=auth.uid() and challenge_id=p_challenge and event_id is not distinct from p_event;pen:=coalesce(pen,0);aw:=greatest(1,pts-pen);fb:=not exists(select 1 from public.solves where challenge_id=p_challenge and event_id is not distinct from p_event);
insert into public.solves(user_id,challenge_id,event_id,points) values(auth.uid(),p_challenge,p_event,aw);update public.profiles set xp=xp+greatest(10,aw/2) where id=auth.uid();perform private.relevel(auth.uid());insert into public.notifications(user_id,title,body) values(auth.uid(),'Challenge résolu',c.title||' : +'||aw||' points');perform private.log('Challenge résolu',c.title);return jsonb_build_object('ok',true,'new_solve',true,'points',aw,'first_blood',fb);end$$;

create or replace function public.register_ctf(p_event uuid) returns boolean language plpgsql security definer set search_path=public,private as $$declare t text;begin select title into t from public.ctf_events where id=p_event;insert into public.ctf_registrations(event_id,user_id) values(p_event,auth.uid()) on conflict do nothing;insert into public.notifications(user_id,title,body) values(auth.uid(),'Inscription CTF',coalesce(t,''));perform private.log('Inscription CTF',coalesce(t,''));return true;end$$;
create or replace function public.create_team(p_name text,p_description text default '') returns jsonb language plpgsql security definer set search_path=public,private as $$declare idd uuid;c text;begin if exists(select 1 from public.team_members where user_id=auth.uid()) then raise exception 'Déjà dans une équipe';end if;c:=upper(substr(encode(gen_random_bytes(6),'hex'),1,8));insert into public.teams(name,join_code,captain_id,description) values(trim(p_name),c,auth.uid(),p_description) returning id into idd;insert into public.team_members values(idd,auth.uid(),now());perform private.log('Équipe créée',p_name);return jsonb_build_object('id',idd,'code',c);end$$;
create or replace function public.join_team(p_code text) returns boolean language plpgsql security definer set search_path=public,private as $$declare idd uuid;t text;begin if exists(select 1 from public.team_members where user_id=auth.uid()) then raise exception 'Déjà dans une équipe';end if;select id,name into idd,t from public.teams where upper(join_code)=upper(trim(p_code));if idd is null then raise exception 'Code invalide';end if;insert into public.team_members values(idd,auth.uid(),now());perform private.log('Équipe rejointe',t);return true;end$$;
create or replace function public.leave_team() returns boolean language plpgsql security definer set search_path=public as $$declare tid uuid;cap uuid;n integer;begin select tm.team_id,t.captain_id into tid,cap from public.team_members tm join public.teams t on t.id=tm.team_id where tm.user_id=auth.uid();if tid is null then return true;end if;if cap=auth.uid() then select count(*) into n from public.team_members where team_id=tid;if n>1 then raise exception 'Le capitaine ne peut pas quitter avec des membres';end if;delete from public.teams where id=tid;else delete from public.team_members where user_id=auth.uid();end if;return true;end$$;

create or replace function public.save_course(p_id uuid,p_title text,p_slug text,p_description text,p_level text,p_icon text,p_published boolean,p_lessons text[]) returns uuid language plpgsql security definer set search_path=public,private as $$declare cid uuid;l text;i integer:=1;begin if not public.has_role(array['trainer','admin']) then raise exception 'Formateur requis';end if;if p_id is null then insert into public.courses(title,slug,description,level,icon,published,created_by) values(p_title,lower(p_slug),p_description,p_level,p_icon,p_published,auth.uid()) returning id into cid;else cid:=p_id;update public.courses set title=p_title,description=p_description,level=p_level,icon=p_icon,published=p_published where id=cid;end if;if p_lessons is not null and array_length(p_lessons,1)>0 then delete from public.lessons where course_id=cid;foreach l in array p_lessons loop if trim(l)<>'' then insert into public.lessons(course_id,position,title,content) values(cid,i,trim(l),'Contenu à compléter.');i:=i+1;end if;end loop;end if;perform private.log('Cours enregistré',p_title);return cid;end$$;
create or replace function public.delete_course(p_id uuid) returns boolean language plpgsql security definer set search_path=public as $$begin if not public.has_role(array['trainer','admin']) then raise exception 'Formateur requis';end if;delete from public.courses where id=p_id;return true;end$$;
create or replace function public.save_challenge(p_id uuid,p_title text,p_slug text,p_category text,p_difficulty text,p_base_points integer,p_min_points integer,p_dynamic boolean,p_description text,p_flag text,p_hint text,p_published boolean,p_training boolean,p_lab_url text) returns uuid language plpgsql security definer set search_path=public,private as $$declare cid uuid;begin if not public.has_role(array['trainer','admin']) then raise exception 'Formateur requis';end if;if p_flag not like 'CYBERCLUB{%}' then raise exception 'Format flag invalide';end if;if p_id is null then insert into public.challenges(title,slug,category,difficulty,base_points,min_points,dynamic_enabled,description,hint,published,training_enabled,lab_url,created_by) values(p_title,lower(p_slug),p_category,p_difficulty,p_base_points,p_min_points,p_dynamic,p_description,p_hint,p_published,p_training,nullif(p_lab_url,''),auth.uid()) returning id into cid;insert into private.challenge_secrets values(cid,p_flag);else cid:=p_id;update public.challenges set title=p_title,category=p_category,difficulty=p_difficulty,base_points=p_base_points,min_points=p_min_points,dynamic_enabled=p_dynamic,description=p_description,hint=p_hint,published=p_published,training_enabled=p_training,lab_url=nullif(p_lab_url,'') where id=cid;insert into private.challenge_secrets values(cid,p_flag) on conflict(challenge_id) do update set flag=excluded.flag;end if;perform private.log('Challenge enregistré',p_title);return cid;end$$;
create or replace function public.delete_challenge(p_id uuid) returns boolean language plpgsql security definer set search_path=public as $$begin if not public.has_role(array['trainer','admin']) then raise exception 'Formateur requis';end if;delete from public.challenges where id=p_id;return true;end$$;
create or replace function public.save_writeup(p_challenge uuid,p_title text,p_content text,p_unlock_after timestamptz default null) returns boolean language plpgsql security definer set search_path=public as $$begin if not public.has_role(array['trainer','admin']) then raise exception 'Formateur requis';end if;insert into public.writeups(challenge_id,title,content,unlock_after) values(p_challenge,p_title,p_content,p_unlock_after) on conflict(challenge_id) do update set title=excluded.title,content=excluded.content,unlock_after=excluded.unlock_after;return true;end$$;

create or replace function public.create_season(p_title text,p_start timestamptz,p_end timestamptz) returns uuid language plpgsql security definer set search_path=public as $$declare idd uuid;begin if not public.has_role(array['organizer','admin']) then raise exception 'Organisateur requis';end if;insert into public.seasons(title,starts_at,ends_at) values(p_title,p_start,p_end) returning id into idd;return idd;end$$;
create or replace function public.activate_season(p_id uuid) returns boolean language plpgsql security definer set search_path=public as $$begin if not public.has_role(array['organizer','admin']) then raise exception 'Organisateur requis';end if;update public.seasons set is_active=false;update public.seasons set is_active=true where id=p_id;return true;end$$;
create or replace function public.create_ctf(p_title text,p_description text,p_start timestamptz,p_end timestamptz,p_team boolean,p_season uuid,p_challenges uuid[]) returns uuid language plpgsql security definer set search_path=public as $$declare eid uuid;cid uuid;begin if not public.has_role(array['organizer','admin']) then raise exception 'Organisateur requis';end if;insert into public.ctf_events(title,description,starts_at,ends_at,team_mode,season_id,created_by) values(p_title,p_description,p_start,p_end,p_team,p_season,auth.uid()) returning id into eid;if p_challenges is not null then foreach cid in array p_challenges loop insert into public.ctf_event_challenges values(eid,cid) on conflict do nothing;end loop;end if;return eid;end$$;
create or replace function public.set_ctf_state(p_event uuid,p_open boolean) returns boolean language plpgsql security definer set search_path=public as $$begin if not public.has_role(array['organizer','admin']) then raise exception 'Organisateur requis';end if;if p_open then update public.ctf_events set is_open=false where id<>p_event;end if;update public.ctf_events set is_open=p_open where id=p_event;return true;end$$;

create or replace function public.admin_set_status(p_user uuid,p_status text) returns boolean language plpgsql security definer set search_path=public as $$begin if not public.has_role(array['admin']) then raise exception 'Admin requis';end if;if p_user=auth.uid() then raise exception 'Impossible sur ton propre compte';end if;update public.profiles set status=p_status where id=p_user;return true;end$$;
create or replace function public.admin_set_role(p_user uuid,p_role text) returns boolean language plpgsql security definer set search_path=public as $$begin if not public.has_role(array['admin']) then raise exception 'Admin requis';end if;if p_user=auth.uid() then raise exception 'Impossible sur ton propre compte';end if;update public.profiles set role=p_role where id=p_user;return true;end$$;
create or replace function public.admin_settings(p_invite text,p_maintenance boolean,p_registrations boolean) returns boolean language plpgsql security definer set search_path=public,private as $$begin if not public.has_role(array['admin']) then raise exception 'Admin requis';end if;update private.app_settings set invite_code=p_invite,maintenance=p_maintenance,registrations_open=p_registrations where id=1;return true;end$$;
create or replace function public.admin_announcement(p_title text,p_body text,p_pinned boolean) returns uuid language plpgsql security definer set search_path=public as $$declare idd uuid;begin if not public.has_role(array['admin']) then raise exception 'Admin requis';end if;insert into public.announcements(title,body,pinned,created_by) values(p_title,p_body,p_pinned,auth.uid()) returning id into idd;insert into public.notifications(user_id,title,body) select id,'Nouvelle annonce',p_title from public.profiles where status='ACTIVE';return idd;end$$;


create or replace function public.get_my_team()
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare tid uuid;t jsonb;members jsonb;
begin
 select tm.team_id into tid from public.team_members tm where tm.user_id=auth.uid();
 if tid is null then return null; end if;
 select to_jsonb(x) into t from(select id,name,join_code,description,captain_id from public.teams where id=tid)x;
 select coalesce(jsonb_agg(x),'[]') into members from(
   select p.name,p.username,p.xp,p.level,tm.joined_at from public.team_members tm join public.profiles p on p.id=tm.user_id
   where tm.team_id=tid order by tm.joined_at
 )x;
 return jsonb_build_object('team',t,'members',members);
end$$;

create or replace function public.save_quiz(p_course uuid,p_title text,p_questions jsonb)
returns uuid language plpgsql security definer set search_path=public,private as $$
declare qid uuid;item jsonb;qst uuid;pos integer:=1;
begin
 if not public.has_role(array['trainer','admin']) then raise exception 'Formateur requis'; end if;
 select id into qid from public.quizzes where course_id=p_course;
 if qid is null then insert into public.quizzes(course_id,title) values(p_course,p_title) returning id into qid;
 else update public.quizzes set title=p_title where id=qid; delete from public.quiz_questions where quiz_id=qid; end if;
 for item in select * from jsonb_array_elements(p_questions) loop
   insert into public.quiz_questions(quiz_id,position,question,options)
   values(qid,pos,item->>'question',item->'options') returning id into qst;
   insert into private.quiz_answers(question_id,answer_index) values(qst,(item->>'answer')::integer);
   pos:=pos+1;
 end loop;
 perform private.log('Quiz enregistré',p_title);
 return qid;
end$$;

create or replace function public.get_leaderboard(p_mode text default 'training',p_event uuid default null,p_season uuid default null) returns table(name text,username text,solves bigint,score bigint,xp integer) language sql stable security definer set search_path=public as $$
select p.name,p.username,count(s.id),coalesce(sum(s.points),0),p.xp from public.profiles p left join public.solves s on s.user_id=p.id left join public.ctf_events e on e.id=s.event_id where p.status='ACTIVE' and ((p_mode='training' and s.event_id is null) or (p_mode='event' and s.event_id=p_event) or (p_mode='season' and e.season_id=p_season) or s.id is null) group by p.id order by coalesce(sum(s.points),0) desc,count(s.id) desc,p.xp desc limit 200$$;

create or replace function public.get_supervision_members() returns table(id uuid,name text,username text,email text,university text,study_level text,status text,xp integer,level integer,last_seen timestamptz,lessons bigint,quiz_passed bigint,solves bigint,score bigint,attempts bigint,team_name text,ctf_count bigint) language sql stable security definer set search_path=public,private as $$
select p.id,p.name,p.username,p.email,p.university,p.study_level,p.status,p.xp,p.level,p.last_seen,(select count(*) from public.lesson_progress x where x.user_id=p.id),(select count(*) from public.quiz_results x where x.user_id=p.id and x.passed),(select count(*) from public.solves x where x.user_id=p.id),(select coalesce(sum(points),0) from public.solves x where x.user_id=p.id),(select count(*) from private.flag_attempts x where x.user_id=p.id),(select t.name from public.teams t join public.team_members tm on tm.team_id=t.id where tm.user_id=p.id limit 1),(select count(*) from public.ctf_registrations x where x.user_id=p.id) from public.profiles p where p.role='member' and public.has_role(array['trainer','organizer','admin']) order by p.name$$;

create or replace function public.get_member_supervision(p_user uuid) returns jsonb language plpgsql stable security definer set search_path=public,private as $$
declare r text;prof jsonb;crs jsonb;qz jsonb;sv jsonb;at jsonb;ac jsonb;rg jsonb;tm jsonb;begin r:=public.current_role();if r not in('trainer','organizer','admin') then raise exception 'Superviseur requis';end if;select to_jsonb(p) into prof from public.profiles p where id=p_user and role='member';
if r in('trainer','admin') then select coalesce(jsonb_agg(x),'[]') into crs from(select c.title,c.icon,c.level,count(l.id) total,count(lp.lesson_id) completed from public.courses c left join public.lessons l on l.course_id=c.id left join public.lesson_progress lp on lp.lesson_id=l.id and lp.user_id=p_user where c.published group by c.id)x;select coalesce(jsonb_agg(x),'[]') into qz from(select q.title,c.title course_title,qr.score,qr.total,qr.passed,qr.completed_at from public.quiz_results qr join public.quizzes q on q.id=qr.quiz_id join public.courses c on c.id=q.course_id where qr.user_id=p_user order by qr.completed_at desc)x;else crs:='[]';qz:='[]';end if;
select coalesce(jsonb_agg(x),'[]') into sv from(select s.solved_at,c.title,c.category,c.difficulty,coalesce(e.title,'Training Arena') event_title,s.points from public.solves s join public.challenges c on c.id=s.challenge_id left join public.ctf_events e on e.id=s.event_id where s.user_id=p_user order by s.solved_at desc limit 100)x;
select coalesce(jsonb_agg(x),'[]') into at from(select a.created_at,c.title,c.category,coalesce(e.title,'Training Arena') event_title,a.is_correct from private.flag_attempts a join public.challenges c on c.id=a.challenge_id left join public.ctf_events e on e.id=a.event_id where a.user_id=p_user order by a.created_at desc limit 100)x;
select coalesce(jsonb_agg(x),'[]') into ac from(select action,details,created_at from private.activity_log where user_id=p_user order by id desc limit 100)x;
select coalesce(jsonb_agg(x),'[]') into rg from(select e.title,e.starts_at,e.ends_at,e.is_open,x.registered_at from public.ctf_registrations x join public.ctf_events e on e.id=x.event_id where x.user_id=p_user order by x.registered_at desc)x;
select to_jsonb(x) into tm from(select t.name,t.description,t.join_code from public.teams t join public.team_members m on m.team_id=t.id where m.user_id=p_user limit 1)x;
return jsonb_build_object('profile',prof,'courses',crs,'quizzes',qz,'solves',sv,'attempts',at,'activity',ac,'registrations',rg,'team',tm,'viewer_role',r);end$$;

create or replace function public.get_live_ctf(p_event uuid) returns jsonb language plpgsql stable security definer set search_path=public,private as $$
declare st jsonb;fd jsonb;bd jsonb;begin if not public.has_role(array['trainer','organizer','admin']) then raise exception 'Superviseur requis';end if;
select coalesce(jsonb_agg(x),'[]') into st from(select c.title,c.category,(select count(*) from public.solves s where s.challenge_id=c.id and s.event_id=p_event) solves,(select count(*) from private.flag_attempts a where a.challenge_id=c.id and a.event_id=p_event) attempts,(select p.username from public.solves s join public.profiles p on p.id=s.user_id where s.challenge_id=c.id and s.event_id=p_event order by s.solved_at limit 1) first_blood from public.ctf_event_challenges ec join public.challenges c on c.id=ec.challenge_id where ec.event_id=p_event)x;
select coalesce(jsonb_agg(x),'[]') into fd from(select p.username,c.title,s.points,s.solved_at from public.solves s join public.profiles p on p.id=s.user_id join public.challenges c on c.id=s.challenge_id where s.event_id=p_event order by s.solved_at desc limit 30)x;
select coalesce(jsonb_agg(x),'[]') into bd from(select p.username,p.name,count(s.id) solves,coalesce(sum(s.points),0) score from public.profiles p left join public.solves s on s.user_id=p.id and s.event_id=p_event where p.status='ACTIVE' group by p.id order by score desc,solves desc limit 100)x;
return jsonb_build_object('challenges',st,'feed',fd,'leaderboard',bd);end$$;

create or replace function public.get_admin_dashboard() returns jsonb language plpgsql stable security definer set search_path=public,private as $$
declare ct jsonb;ca jsonb;ha jsonb;au jsonb;se jsonb;begin if not public.has_role(array['admin']) then raise exception 'Admin requis';end if;ct:=jsonb_build_object('users',(select count(*) from public.profiles),'active',(select count(*) from public.profiles where status='ACTIVE'),'pending',(select count(*) from public.profiles where status='PENDING'),'solves',(select count(*) from public.solves),'attempts',(select count(*) from private.flag_attempts),'teams',(select count(*) from public.teams));
select coalesce(jsonb_agg(x),'[]') into ca from(select c.category,count(s.id) solves from public.challenges c left join public.solves s on s.challenge_id=c.id group by c.category)x;
select coalesce(jsonb_agg(x),'[]') into ha from(select c.title,c.category,count(a.id) attempts,count(a.id) filter(where a.is_correct) correct from public.challenges c left join private.flag_attempts a on a.challenge_id=c.id group by c.id having count(a.id)>0 order by correct::numeric/greatest(count(a.id),1),count(a.id) desc limit 8)x;
select coalesce(jsonb_agg(x),'[]') into au from(select a.action,a.details,a.created_at,p.name from private.activity_log a left join public.profiles p on p.id=a.user_id order by a.id desc limit 50)x;
select jsonb_build_object('invite_code',invite_code,'maintenance',maintenance,'registrations_open',registrations_open) into se from private.app_settings where id=1;return jsonb_build_object('counts',ct,'categories',ca,'hardest',ha,'audit',au,'settings',se);end$$;

alter table public.profiles enable row level security;alter table public.courses enable row level security;alter table public.lessons enable row level security;alter table public.lesson_progress enable row level security;alter table public.quizzes enable row level security;alter table public.quiz_questions enable row level security;alter table public.quiz_results enable row level security;alter table public.challenges enable row level security;alter table public.challenge_files enable row level security;alter table public.writeups enable row level security;alter table public.seasons enable row level security;alter table public.ctf_events enable row level security;alter table public.ctf_event_challenges enable row level security;alter table public.ctf_registrations enable row level security;alter table public.solves enable row level security;alter table public.hint_usage enable row level security;alter table public.teams enable row level security;alter table public.team_members enable row level security;alter table public.announcements enable row level security;alter table public.notifications enable row level security;

create policy p_profiles on public.profiles for select to authenticated using(id=auth.uid() or public.has_role(array['admin']));
create policy p_courses on public.courses for select to authenticated using(public.is_active_member());
create policy p_lessons on public.lessons for select to authenticated using(public.is_active_member());
create policy p_progress on public.lesson_progress for select to authenticated using(user_id=auth.uid());
create policy p_quizzes on public.quizzes for select to authenticated using(public.is_active_member());
create policy p_questions on public.quiz_questions for select to authenticated using(public.is_active_member());
create policy p_qresults on public.quiz_results for select to authenticated using(user_id=auth.uid());
create policy p_challenges on public.challenges for select to authenticated using(public.is_active_member());
create policy p_cfiles on public.challenge_files for select to authenticated using(public.is_active_member());
create policy p_writeups on public.writeups for select to authenticated using(public.is_active_member() and published and (public.has_role(array['trainer','admin']) or (coalesce(unlock_after,now())<=now() and exists(select 1 from public.solves s where s.user_id=auth.uid() and s.challenge_id=writeups.challenge_id))));
create policy p_seasons on public.seasons for select to authenticated using(public.is_active_member());
create policy p_events on public.ctf_events for select to authenticated using(public.is_active_member());
create policy p_event_ch on public.ctf_event_challenges for select to authenticated using(public.is_active_member());
create policy p_regs on public.ctf_registrations for select to authenticated using(user_id=auth.uid() or public.has_role(array['organizer','admin']));
create policy p_solves on public.solves for select to authenticated using(user_id=auth.uid() or public.has_role(array['trainer','organizer','admin']));
create policy p_hints on public.hint_usage for select to authenticated using(user_id=auth.uid());
create policy p_teams on public.teams for select to authenticated using(public.is_active_member());
create policy p_tm on public.team_members for select to authenticated using(public.is_active_member());
create policy p_ann on public.announcements for select to authenticated using(public.is_active_member());
create policy p_not on public.notifications for select to authenticated using(user_id=auth.uid());
create policy p_not_upd on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy p_cfiles_manage on public.challenge_files for all to authenticated using(public.has_role(array['trainer','admin'])) with check(public.has_role(array['trainer','admin']));
create policy p_ann_manage on public.announcements for all to authenticated using(public.has_role(array['admin'])) with check(public.has_role(array['admin']));

revoke all on all tables in schema public from anon;
grant select on all tables in schema public to authenticated;
grant update(is_read) on public.notifications to authenticated;
grant insert,update,delete on public.challenge_files,public.announcements to authenticated;
revoke all on all functions in schema public from public;
grant execute on all functions in schema public to authenticated;
grant execute on function public.get_app_state() to anon;

insert into storage.buckets(id,name,public,file_size_limit) values('challenge-files','challenge-files',false,52428800) on conflict(id) do nothing;
drop policy if exists "cc storage read" on storage.objects;create policy "cc storage read" on storage.objects for select to authenticated using(bucket_id='challenge-files' and public.is_active_member());
drop policy if exists "cc storage insert" on storage.objects;create policy "cc storage insert" on storage.objects for insert to authenticated with check(bucket_id='challenge-files' and public.has_role(array['trainer','admin']));
drop policy if exists "cc storage delete" on storage.objects;create policy "cc storage delete" on storage.objects for delete to authenticated using(bucket_id='challenge-files' and public.has_role(array['trainer','admin']));

insert into public.courses(id,slug,title,description,level,icon) values
('11111111-1111-4111-8111-111111111111','linux','Linux pour la cybersécurité','Commandes, permissions et réseau Linux.','Débutant','🐧'),
('22222222-2222-4222-8222-222222222222','reseaux','Réseaux & TCP/IP','Bases réseau indispensables.','Débutant','🌐'),
('33333333-3333-4333-8333-333333333333','crypto','Cryptographie CTF','Encodages et chiffrements classiques.','Intermédiaire','🔐')
on conflict(id) do nothing;
insert into public.lessons(id,course_id,position,title,content) values
('11000000-0000-4000-8000-000000000001','11111111-1111-4111-8111-111111111111',1,'Terminal Linux','pwd, ls, cd, cat, less, man.'),
('11000000-0000-4000-8000-000000000002','11111111-1111-4111-8111-111111111111',2,'Permissions','chmod, chown et rwx.'),
('22000000-0000-4000-8000-000000000001','22222222-2222-4222-8222-222222222222',1,'Modèle OSI','Comprendre les couches réseau.'),
('22000000-0000-4000-8000-000000000002','22222222-2222-4222-8222-222222222222',2,'IPv4','Adresses, masques et sous-réseaux.'),
('33000000-0000-4000-8000-000000000001','33333333-3333-4333-8333-333333333333',1,'Base64 et hex','Encodages courants en CTF.'),
('33000000-0000-4000-8000-000000000002','33333333-3333-4333-8333-333333333333',2,'César','Chiffrement par décalage.')
on conflict(id) do nothing;
insert into public.challenges(id,slug,title,category,difficulty,base_points,min_points,dynamic_enabled,description,hint) values
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1','welcome','Welcome Flag','Misc','Easy',50,50,false,'Soumets ton premier flag.','Format CYBERCLUB{...}.'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2','caesar','Caesar Rookie','Crypto','Easy',100,60,true,'Déchiffre : FDHVDU LV IXQ.','Décalage de 3 vers la gauche.')
on conflict(id) do nothing;
insert into private.challenge_secrets(challenge_id,flag) values
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1','CYBERCLUB{welcome_to_ctf}'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2','CYBERCLUB{caesar_is_fun}')
on conflict(challenge_id) do update set flag=excluded.flag;
insert into public.writeups(challenge_id,title,content) values
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1','Write-up Welcome','Le premier challenge apprend le format du flag.'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2','Write-up César','Décale chaque lettre de trois positions vers la gauche.')
on conflict(challenge_id) do nothing;
insert into public.announcements(title,body,pinned) select 'Bienvenue au Cyber Club','Commence par les cours puis essaie le Training Arena.',true where not exists(select 1 from public.announcements);

-- APRÈS TON INSCRIPTION, CRÉE LE PREMIER ADMIN :
-- update public.profiles set role='admin',status='ACTIVE',invite_verified=true where email='TON_EMAIL';

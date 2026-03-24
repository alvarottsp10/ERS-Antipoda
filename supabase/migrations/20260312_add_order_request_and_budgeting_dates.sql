alter table public.orders
  add column requested_at date;

update public.orders
set requested_at = coalesce(created_at::date, current_date)
where requested_at is null;

alter table public.orders
  alter column requested_at set default current_date;

alter table public.orders
  alter column requested_at set not null;


alter table public.order_versions
  add column requested_at date,
  add column sent_to_budgeting_at timestamp with time zone;

update public.order_versions ov
set requested_at = coalesce(
  case
    when ov.version_number = 1 then o.requested_at
    else ov.created_at::date
  end,
  o.requested_at,
  current_date
)
from public.orders o
where o.id = ov.order_id
  and ov.requested_at is null;

alter table public.order_versions
  alter column requested_at set default current_date;

alter table public.order_versions
  alter column requested_at set not null;


drop function if exists public.create_order(uuid, uuid, text, bigint);

create function public.create_order(
  p_customer_id uuid,
  p_commercial_user_id uuid,
  p_commercial_sigla text,
  p_commercial_phase_id bigint default null::bigint,
  p_requested_at date default null::date
) returns table(id uuid, order_ref text, order_year integer, order_seq integer)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_phase_id bigint;
  v_requested_at date := coalesce(p_requested_at, current_date);
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_commercial_user_id is null then
    raise exception 'Commercial user is required';
  end if;

  if p_commercial_phase_id is null then
    select wf.id
      into v_phase_id
    from public.workflow_phases wf
    where wf.department_code = 'COM'
      and wf.is_active = true
    order by wf.sort_order asc
    limit 1;
  else
    v_phase_id := p_commercial_phase_id;
  end if;

  insert into public.orders (
    customer_id,
    commercial_user_id,
    commercial_sigla,
    commercial_phase_id,
    requested_at
  )
  values (
    p_customer_id,
    p_commercial_user_id,
    p_commercial_sigla,
    v_phase_id,
    v_requested_at
  )
  returning orders.id, orders.order_ref, orders.order_year, orders.order_seq
  into id, order_ref, order_year, order_seq;

  perform public.create_order_revision(id, v_requested_at);

  return next;
end;
$$;


drop function if exists public.create_order(uuid, uuid, text, bigint, uuid);

create function public.create_order(
  p_customer_id uuid,
  p_commercial_user_id uuid,
  p_commercial_sigla text,
  p_commercial_phase_id bigint default null::bigint,
  p_contact_id uuid default null::uuid,
  p_requested_at date default null::date
) returns table(id uuid, order_ref text, order_year integer, order_seq integer)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_phase_id bigint;
  v_requested_at date := coalesce(p_requested_at, current_date);
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_commercial_user_id is null then
    raise exception 'Commercial user is required';
  end if;

  if p_commercial_phase_id is null then
    select wf.id
    into v_phase_id
    from public.workflow_phases wf
    where wf.department_code = 'COM'
      and wf.is_active = true
    order by wf.sort_order asc
    limit 1;
  else
    v_phase_id := p_commercial_phase_id;
  end if;

  insert into public.orders (
    customer_id,
    commercial_user_id,
    commercial_sigla,
    commercial_phase_id,
    contact_id,
    requested_at
  )
  values (
    p_customer_id,
    p_commercial_user_id,
    p_commercial_sigla,
    v_phase_id,
    p_contact_id,
    v_requested_at
  )
  returning orders.id, orders.order_ref, orders.order_year, orders.order_seq
  into id, order_ref, order_year, order_seq;

  perform public.create_order_revision(id, v_requested_at);

  return next;
end;
$$;


drop function if exists public.create_order_revision(uuid);

create function public.create_order_revision(
  p_order_id uuid,
  p_requested_at date default null::date
) returns uuid
language plpgsql
as $$
declare
  v_order_ref text;
  v_next_code text;
  v_revision_id uuid;
  v_next_version_number integer;
  v_prev_version_id uuid;
  v_requested_at date;
begin
  select order_ref, requested_at
  into v_order_ref, v_requested_at
  from public.orders
  where id = p_order_id;

  if v_order_ref is null then
    raise exception 'Pedido nao encontrado.';
  end if;

  v_requested_at := coalesce(p_requested_at, v_requested_at, current_date);

  select
    ov.version_number,
    ov.id
  into
    v_next_version_number,
    v_prev_version_id
  from public.order_versions ov
  where ov.order_id = p_order_id
  order by ov.version_number desc, ov.created_at desc, ov.id desc
  limit 1;

  v_next_version_number := coalesce(v_next_version_number, 0) + 1;

  if v_next_version_number = 1 then
    v_next_code := null;
  else
    v_next_code := chr(ascii('A') + v_next_version_number - 2);
  end if;

  insert into public.order_versions (
    order_id,
    revision_code,
    revision_ref,
    version_number,
    requested_by_contact_id,
    requested_at,
    created_by,
    supersedes_version_id
  )
  select
    o.id,
    v_next_code,
    case
      when v_next_code is null then o.order_ref
      else o.order_ref || ' ' || v_next_code
    end,
    v_next_version_number,
    o.primary_contact_id,
    v_requested_at,
    auth.uid(),
    v_prev_version_id
  from public.orders o
  where o.id = p_order_id
  returning id into v_revision_id;

  return v_revision_id;
end;
$$;


drop function if exists public.create_order_revision_from_crm(uuid, uuid);

create function public.create_order_revision_from_crm(
  p_order_id uuid,
  p_contact_id uuid default null::uuid,
  p_requested_at date default null::date
) returns uuid
language plpgsql
security definer
as $$
declare
  v_revision_id uuid;
  v_com_phase_id bigint;
  v_requested_at date := coalesce(p_requested_at, current_date);
begin
  if p_order_id is null then
    raise exception 'Order is required';
  end if;

  if not exists (
    select 1 from public.orders where id = p_order_id
  ) then
    raise exception 'Pedido nao encontrado.';
  end if;

  select wf.id
    into v_com_phase_id
  from public.workflow_phases wf
  where wf.department_code = 'COM'
    and wf.code = 'em_analise'
    and wf.is_active = true
  limit 1;

  if v_com_phase_id is null then
    raise exception 'Fase comercial inicial nao encontrada.';
  end if;

  update public.orders
  set
    contact_id = coalesce(p_contact_id, contact_id),
    commercial_phase_id = v_com_phase_id,
    status = 'Em análise'
  where id = p_order_id;

  v_revision_id := public.create_order_revision(p_order_id, v_requested_at);

  if p_contact_id is not null then
    update public.order_versions
    set requested_by_contact_id = p_contact_id
    where id = v_revision_id;
  end if;

  return v_revision_id;
end;
$$;


drop function if exists public.set_order_commercial_phase(uuid, bigint);

create function public.set_order_commercial_phase(
  p_order_id uuid,
  p_commercial_phase_id bigint
) returns public.orders
language plpgsql
security definer
as $$
declare
  v_row public.orders;
  v_first_budget_phase_id bigint;
  v_phase_code text;
  v_latest_version_id uuid;
begin
  select *
  into v_row
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found: %', p_order_id using errcode = 'P0002';
  end if;

  select wf.code
  into v_phase_code
  from public.workflow_phases wf
  where wf.id = p_commercial_phase_id
    and wf.department_code = 'COM';

  if v_phase_code is null then
    raise exception 'Fase comercial invalida: %', p_commercial_phase_id;
  end if;

  update public.orders
  set commercial_phase_id = p_commercial_phase_id
  where id = p_order_id
  returning * into v_row;

  if v_phase_code = 'em_orcamentacao' then
    select id
    into v_first_budget_phase_id
    from public.workflow_phases
    where department_code = 'ORC'
      and is_active = true
    order by sort_order asc
    limit 1;

    if v_first_budget_phase_id is null then
      raise exception 'No active ORC workflow phase found' using errcode = 'P0001';
    end if;

    update public.orders
    set budgeting_phase_id = v_first_budget_phase_id
    where id = p_order_id
    returning * into v_row;

    select ov.id
    into v_latest_version_id
    from public.order_versions ov
    where ov.order_id = p_order_id
    order by ov.version_number desc, ov.created_at desc, ov.id desc
    limit 1;

    if v_latest_version_id is not null then
      update public.order_versions
      set sent_to_budgeting_at = coalesce(sent_to_budgeting_at, now())
      where id = v_latest_version_id;
    end if;
  end if;

  return v_row;
end;
$$;

--
-- PostgreSQL database dump
--

\restrict bO7LH43NodjBNCxD2VsHV3knCBp5g4sb27VKiMenpU3Wa8QcmTLzg7FFlUTkeox

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9 (Debian 17.9-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: order_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.order_status AS ENUM (
    'Em análise',
    'Espera informações adicionais',
    'Em orçamentação',
    'Proposta em validação',
    'Enviado'
);


--
-- Name: add_customer_contact(uuid, text, text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_customer_contact(p_customer_id uuid, p_name text, p_email text, p_phone text, p_role text, p_is_primary boolean DEFAULT false) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_contact_id uuid;
  v_existing_count int;
begin
  -- validações mínimas
  if p_customer_id is null then
    raise exception 'Customer obrigatório.';
  end if;

  if p_email is null or length(trim(p_email)) = 0 then
    raise exception 'Email obrigatório.';
  end if;

  if p_role is null or length(trim(p_role)) = 0 then
    raise exception 'Role obrigatório.';
  end if;

  -- contar contactos existentes
  select count(*) into v_existing_count
  from public.contacts
  where customer_id = p_customer_id;

  -- se for o primeiro contacto, força primário
  if v_existing_count = 0 then
    p_is_primary := true;
  end if;

  -- se estiver a adicionar como primário, desmarca os outros
  if p_is_primary then
    update public.contacts
    set is_primary = false
    where customer_id = p_customer_id;
  end if;

  insert into public.contacts (
    customer_id,
    name,
    email,
    phone,
    role,
    is_primary
  )
  values (
    p_customer_id,
    p_name,
    p_email,
    p_phone,
    p_role,
    p_is_primary
  )
  returning id into v_contact_id;

  return v_contact_id;
end;
$$;


--
-- Name: add_customer_site(uuid, text, text, text, text, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_customer_site(p_customer_id uuid, p_name text, p_address_line_1 text, p_postal_code text, p_city text, p_country_id integer, p_address_line_2 text DEFAULT NULL::text, p_code text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_site_id uuid;
begin
  if p_customer_id is null then
    raise exception 'Customer obrigatorio.';
  end if;

  if p_name is null or length(trim(p_name)) = 0 then
    raise exception 'Nome do local obrigatorio.';
  end if;

  if p_address_line_1 is null or length(trim(p_address_line_1)) = 0 then
    raise exception 'Morada do local obrigatoria.';
  end if;

  if p_postal_code is null or length(trim(p_postal_code)) = 0 then
    raise exception 'Codigo postal do local obrigatorio.';
  end if;

  if p_city is null or length(trim(p_city)) = 0 then
    raise exception 'Cidade do local obrigatoria.';
  end if;

  if p_country_id is null then
    raise exception 'Pais do local obrigatorio.';
  end if;

  if not exists (
    select 1
    from public.customers
    where id = p_customer_id
  ) then
    raise exception 'Cliente nao existe.';
  end if;

  insert into public.customer_sites (
    customer_id,
    name,
    code,
    address_line_1,
    address_line_2,
    postal_code,
    city,
    country_id,
    is_active,
    created_at
  )
  values (
    p_customer_id,
    trim(p_name),
    nullif(trim(p_code), ''),
    trim(p_address_line_1),
    nullif(trim(p_address_line_2), ''),
    trim(p_postal_code),
    trim(p_city),
    p_country_id,
    true,
    now()
  )
  returning id into v_site_id;

  return v_site_id;
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: work_time_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_time_entries (
    id bigint NOT NULL,
    budget_assignment_id bigint NOT NULL,
    category_definition_id bigint NOT NULL,
    hours numeric NOT NULL,
    note text,
    work_date date,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: add_work_time_entry(bigint, bigint, numeric, date, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_work_time_entry(p_budget_assignment_id bigint, p_category_definition_id bigint, p_hours numeric, p_work_date date DEFAULT NULL::date, p_note text DEFAULT NULL::text) RETURNS public.work_time_entries
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_row public.work_time_entries;
  v_assignment public.order_budget_assignments;
  v_category public.work_time_category_definitions;
begin
  if p_budget_assignment_id is null then
    raise exception 'Budget assignment is required';
  end if;

  if p_category_definition_id is null then
    raise exception 'Category definition is required';
  end if;

  if p_hours is null or p_hours <= 0 then
    raise exception 'Hours must be greater than 0';
  end if;

  select *
  into v_assignment
  from public.order_budget_assignments
  where id = p_budget_assignment_id;

  if not found then
    raise exception 'Budget assignment not found.';
  end if;

  select *
  into v_category
  from public.work_time_category_definitions
  where id = p_category_definition_id
    and is_active = true;

  if not found then
    raise exception 'Work time category not found or inactive.';
  end if;

  insert into public.work_time_entries (
    budget_assignment_id,
    category_definition_id,
    hours,
    note,
    work_date
  )
  values (
    p_budget_assignment_id,
    p_category_definition_id,
    p_hours,
    nullif(trim(coalesce(p_note, '')), ''),
    p_work_date
  )
  returning * into v_row;

  update public.order_budget_assignments oba
  set worked_hours = coalesce((
    select sum(wte.hours)
    from public.work_time_entries wte
    where wte.budget_assignment_id = p_budget_assignment_id
  ), 0)
  where oba.id = p_budget_assignment_id;

  return v_row;
end;
$$;


--
-- Name: assign_budgeter(uuid, uuid, bigint, bigint, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assign_budgeter(p_order_id uuid, p_assignee_user_id uuid, p_budget_typology_id bigint, p_product_type_id bigint DEFAULT NULL::bigint, p_is_special boolean DEFAULT false) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_order_version_id uuid;
begin
  select ov.id
  into v_order_version_id
  from public.order_versions ov
  where ov.order_id = p_order_id
  order by ov.version_number desc, ov.created_at desc
  limit 1;

  if v_order_version_id is null then
    raise exception 'Nao foi encontrada uma revisao atual para o pedido %', p_order_id;
  end if;

  update public.order_budget_assignments
  set is_active = false
  where order_version_id = v_order_version_id
    and is_active = true;

  insert into public.order_budget_assignments (
    order_version_id,
    assignee_user_id,
    assigned_by,
    assigned_at,
    is_active,
    is_special,
    budget_typology_id,
    product_type_id
  )
  values (
    v_order_version_id,
    p_assignee_user_id,
    auth.uid(),
    now(),
    true,
    p_is_special,
    p_budget_typology_id,
    p_product_type_id
  );
end;
$$;


--
-- Name: assign_budgeter(uuid, uuid, bigint, bigint, boolean, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assign_budgeter(p_order_id uuid, p_assignee_user_id uuid, p_budget_typology_id bigint, p_product_type_id bigint DEFAULT NULL::bigint, p_is_special boolean DEFAULT false, p_assignment_role text DEFAULT 'support'::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_order_version_id uuid;
  v_active_count integer;
  v_active_lead_count integer;
  v_assignment_role text := lower(trim(coalesce(p_assignment_role, 'support')));
begin
  if v_assignment_role not in ('lead', 'support') then
    raise exception 'assignment_role invalido. Use lead ou support.';
  end if;

  select ov.id
  into v_order_version_id
  from public.order_versions ov
  where ov.order_id = p_order_id
  order by ov.version_number desc, ov.created_at desc
  limit 1;

  if v_order_version_id is null then
    raise exception 'Nao foi encontrada uma revisao atual para o pedido %', p_order_id;
  end if;

  if exists (
    select 1
    from public.order_budget_assignments oba
    where oba.order_version_id = v_order_version_id
      and oba.assignee_user_id = p_assignee_user_id
      and oba.is_active = true
  ) then
    raise exception 'Este orcamentista ja esta ativo neste processo.';
  end if;

  select count(*)
  into v_active_count
  from public.order_budget_assignments oba
  where oba.order_version_id = v_order_version_id
    and oba.is_active = true;

  if v_active_count >= 2 then
    raise exception 'Esta versao ja tem 2 orcamentistas ativos.';
  end if;

  if v_assignment_role = 'lead' then
    select count(*)
    into v_active_lead_count
    from public.order_budget_assignments oba
    where oba.order_version_id = v_order_version_id
      and oba.is_active = true
      and oba.assignment_role = 'lead';

    if v_active_lead_count >= 1 then
      raise exception 'Ja existe um orcamentista lead ativo nesta versao.';
    end if;
  end if;

  insert into public.order_budget_assignments (
    order_version_id,
    assignee_user_id,
    assigned_by,
    assigned_at,
    is_active,
    is_special,
    budget_typology_id,
    product_type_id,
    worked_hours,
    assignment_role
  )
  values (
    v_order_version_id,
    p_assignee_user_id,
    auth.uid(),
    now(),
    true,
    p_is_special,
    p_budget_typology_id,
    p_product_type_id,
    0,
    v_assignment_role
  );
end;
$$;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_year integer NOT NULL,
    commercial_sigla text NOT NULL,
    order_seq integer NOT NULL,
    order_ref text NOT NULL,
    customer_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    commercial_user_id uuid,
    outcome text,
    commercial_phase_id bigint,
    budgeting_phase_id bigint,
    project_phase_id bigint,
    production_phase_id bigint,
    awarded_order_version_id uuid,
    contact_id uuid,
    customer_site_id uuid,
    primary_contact_id uuid,
    status public.order_status DEFAULT 'Em análise'::public.order_status NOT NULL,
    closed_at timestamp with time zone,
    requested_at date DEFAULT CURRENT_DATE NOT NULL
);


--
-- Name: cancel_order_from_crm(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cancel_order_from_crm(p_order_id uuid, p_reason text DEFAULT NULL::text) RETURNS public.orders
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_row public.orders;
  v_concluded_phase_id bigint;
  v_old_status text;
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
begin
  if p_order_id is null then
    raise exception 'Order is required';
  end if;

  select *
  into v_row
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Pedido nao encontrado.';
  end if;

  select wf.id
  into v_concluded_phase_id
  from public.workflow_phases wf
  where wf.department_code = 'COM'
    and wf.code = 'concluido'
    and wf.is_active = true
  limit 1;

  if v_concluded_phase_id is null then
    raise exception 'Fase comercial concluido nao encontrada.';
  end if;

  v_old_status := v_row.status::text;

  update public.orders
  set
    commercial_phase_id = v_concluded_phase_id,
    closed_at = coalesce(closed_at, now()),
    outcome = coalesce(v_reason, 'Anulado')
  where id = p_order_id
  returning * into v_row;

  insert into public.order_status_history (
    order_id,
    old_status,
    new_status,
    changed_by,
    changed_at
  )
  values (
    p_order_id,
    v_old_status,
    v_old_status,
    auth.uid(),
    now()
  );

  return v_row;
end;
$$;


--
-- Name: create_customer_with_contacts(text, integer, text, text, text, uuid, jsonb, text, text, text, text, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_customer_with_contacts(p_name text, p_country_id integer, p_vat_number text, p_email text, p_phone text, p_commercial_user_id uuid, p_contacts jsonb, p_site_name text, p_site_address_line_1 text, p_site_postal_code text, p_site_city text, p_site_country_id integer, p_site_address_line_2 text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_customer_id uuid;
  v_contact jsonb;
  v_primary_count int := 0;
begin
  if p_commercial_user_id is null then
    raise exception 'Comercial responsavel obrigatorio.';
  end if;

  if not exists (
    select 1
    from public.commercials_list_view clv
    where clv.user_id = p_commercial_user_id
      and clv.is_active = true
  ) then
    raise exception 'Comercial responsavel invalido ou inativo.';
  end if;

  if exists (
    select 1
    from public.customers
    where vat_number = p_vat_number
  ) then
    raise exception 'Ja existe um cliente com este VAT/NIF.';
  end if;

  if p_site_name is null or length(trim(p_site_name)) = 0 then
    raise exception 'Nome do local obrigatorio.';
  end if;

  if p_site_address_line_1 is null or length(trim(p_site_address_line_1)) = 0 then
    raise exception 'Morada do local obrigatoria.';
  end if;

  if p_site_postal_code is null or length(trim(p_site_postal_code)) = 0 then
    raise exception 'Codigo postal do local obrigatorio.';
  end if;

  if p_site_city is null or length(trim(p_site_city)) = 0 then
    raise exception 'Cidade do local obrigatoria.';
  end if;

  if p_site_country_id is null then
    raise exception 'Pais do local obrigatorio.';
  end if;

  if jsonb_array_length(p_contacts) = 0 then
    raise exception 'E obrigatorio pelo menos um contacto.';
  end if;

  select count(*)
  into v_primary_count
  from jsonb_array_elements(p_contacts) elem
  where coalesce((elem->>'is_primary')::boolean, false) = true;

  if v_primary_count = 0 then
    raise exception 'Deve existir exatamente um contacto primario.';
  end if;

  if v_primary_count > 1 then
    raise exception 'So pode existir um contacto primario.';
  end if;

  insert into public.customers (
    name,
    country_id,
    vat_number,
    email,
    phone,
    commercial_user_id,
    created_at
  )
  values (
    trim(p_name),
    p_country_id,
    nullif(trim(p_vat_number), ''),
    nullif(trim(p_email), ''),
    nullif(trim(p_phone), ''),
    p_commercial_user_id,
    now()
  )
  returning id into v_customer_id;

  insert into public.customer_sites (
    customer_id,
    name,
    address_line_1,
    address_line_2,
    postal_code,
    city,
    country_id,
    is_active,
    created_at
  )
  values (
    v_customer_id,
    trim(p_site_name),
    trim(p_site_address_line_1),
    nullif(trim(p_site_address_line_2), ''),
    trim(p_site_postal_code),
    trim(p_site_city),
    p_site_country_id,
    true,
    now()
  );

  for v_contact in
    select *
    from jsonb_array_elements(p_contacts)
  loop
    insert into public.contacts (
      customer_id,
      name,
      email,
      phone,
      role,
      is_primary,
      created_at
    )
    values (
      v_customer_id,
      trim(v_contact->>'name'),
      nullif(trim(v_contact->>'email'), ''),
      nullif(trim(v_contact->>'phone'), ''),
      trim(v_contact->>'role'),
      (v_contact->>'is_primary')::boolean,
      now()
    );
  end loop;

  return v_customer_id;
end;
$$;


--
-- Name: create_order(uuid, uuid, text, bigint, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_order(p_customer_id uuid, p_commercial_user_id uuid, p_commercial_sigla text, p_commercial_phase_id bigint DEFAULT NULL::bigint, p_requested_at date DEFAULT NULL::date, p_expected_delivery_date date DEFAULT NULL::date) RETURNS TABLE(id uuid, order_ref text, order_year integer, order_seq integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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

  perform public.create_order_revision(
    id,
    v_requested_at,
    p_expected_delivery_date
  );

  return next;
end;
$$;


--
-- Name: create_order(uuid, uuid, text, bigint, uuid, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_order(p_customer_id uuid, p_commercial_user_id uuid, p_commercial_sigla text, p_commercial_phase_id bigint DEFAULT NULL::bigint, p_contact_id uuid DEFAULT NULL::uuid, p_requested_at date DEFAULT NULL::date, p_expected_delivery_date date DEFAULT NULL::date) RETURNS TABLE(id uuid, order_ref text, order_year integer, order_seq integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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

  perform public.create_order_revision(
    id,
    v_requested_at,
    p_expected_delivery_date
  );

  return next;
end;
$$;


--
-- Name: create_order_revision(uuid, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_order_revision(p_order_id uuid, p_requested_at date DEFAULT NULL::date, p_expected_delivery_date date DEFAULT NULL::date) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
declare
  v_order_ref text;
  v_revision_id uuid;
  v_prev_version_id uuid;
  v_prev_expected_delivery_date date;
  v_next_index integer;
  v_next_code text;
  v_requested_at date;
  v_expected_delivery_date date;
begin
  select o.order_ref, o.requested_at
  into v_order_ref, v_requested_at
  from public.orders o
  where o.id = p_order_id;

  if v_order_ref is null then
    raise exception 'Pedido nao encontrado.';
  end if;

  v_requested_at := coalesce(p_requested_at, v_requested_at, current_date);

  select ov.id, ov.expected_delivery_date
  into v_prev_version_id, v_prev_expected_delivery_date
  from public.order_versions ov
  where ov.order_id = p_order_id
  order by ov.version_number desc nulls last, ov.created_at desc, ov.id desc
  limit 1;

  v_expected_delivery_date := coalesce(
    p_expected_delivery_date,
    v_prev_expected_delivery_date
  );

  select coalesce(max(ov.version_number), 0) + 1
  into v_next_index
  from public.order_versions ov
  where ov.order_id = p_order_id;

  if v_next_index = 1 then
    v_next_code := null;
  else
    v_next_code := chr(ascii('A') + v_next_index - 2);
  end if;

  insert into public.order_versions (
    order_id,
    revision_code,
    revision_ref,
    version_number,
    requested_by_contact_id,
    requested_at,
    expected_delivery_date,
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
    v_next_index,
    o.primary_contact_id,
    v_requested_at,
    v_expected_delivery_date,
    auth.uid(),
    v_prev_version_id
  from public.orders o
  where o.id = p_order_id
  returning id into v_revision_id;

  return v_revision_id;
end;
$$;


--
-- Name: create_order_revision_from_crm(uuid, uuid, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_order_revision_from_crm(p_order_id uuid, p_contact_id uuid DEFAULT NULL::uuid, p_requested_at date DEFAULT NULL::date, p_expected_delivery_date date DEFAULT NULL::date) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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

  v_revision_id := public.create_order_revision(
    p_order_id,
    v_requested_at,
    p_expected_delivery_date
  );

  if p_contact_id is not null then
    update public.order_versions
    set requested_by_contact_id = p_contact_id
    where id = v_revision_id;
  end if;

  return v_revision_id;
end;
$$;


--
-- Name: order_budget_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_budget_assignments (
    id bigint NOT NULL,
    assignee_user_id uuid NOT NULL,
    assigned_by uuid,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    note text,
    is_special boolean,
    budget_typology_id bigint,
    product_type_id bigint,
    order_version_id uuid NOT NULL,
    worked_hours numeric(10,2) DEFAULT 0 NOT NULL,
    assignment_role text DEFAULT 'support'::text NOT NULL,
    CONSTRAINT order_budget_assignments_assignment_role_check CHECK ((assignment_role = ANY (ARRAY['lead'::text, 'support'::text])))
);


--
-- Name: deactivate_budget_assignment(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deactivate_budget_assignment(p_assignment_id uuid) RETURNS public.order_budget_assignments
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_row public.order_budget_assignments;
begin
  if p_assignment_id is null then
    raise exception 'Assignment is required';
  end if;

  update public.order_budget_assignments
  set is_active = false
  where id = p_assignment_id
  returning * into v_row;

  if not found then
    raise exception 'Assignment nao encontrado.';
  end if;

  return v_row;
end;
$$;


--
-- Name: proposals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_version_id uuid NOT NULL,
    title text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    solution_type text,
    is_standard boolean,
    sell_total numeric(14,2),
    sell_total_before_discount numeric(14,2),
    cost_material_total numeric(14,2),
    cost_labor_total numeric(14,2),
    cost_project_total numeric(14,2),
    cost_other_total numeric(14,2),
    cost_total numeric(14,2),
    discount_pct numeric(5,2),
    discount_amount numeric(14,2),
    margin_amount numeric(14,2),
    margin_pct numeric(5,2),
    phase_id bigint,
    sent_at timestamp with time zone,
    accepted_at timestamp with time zone,
    rejected_at timestamp with time zone,
    feedback_at timestamp with time zone,
    valid_until timestamp with time zone,
    budget_typology_id bigint,
    product_type_id bigint,
    is_special boolean,
    original_margin_pct numeric(5,2),
    commercial_adjustment_pct numeric(5,2),
    final_margin_pct numeric(5,2),
    sent_by uuid,
    CONSTRAINT chk_proposals_commercial_adjustment_pct CHECK (((commercial_adjustment_pct IS NULL) OR ((commercial_adjustment_pct >= ('-100'::integer)::numeric) AND (commercial_adjustment_pct <= (100)::numeric)))),
    CONSTRAINT chk_proposals_discount_pct CHECK (((discount_pct IS NULL) OR ((discount_pct >= (0)::numeric) AND (discount_pct <= (100)::numeric)))),
    CONSTRAINT chk_proposals_final_margin_pct CHECK (((final_margin_pct IS NULL) OR ((final_margin_pct >= ('-100'::integer)::numeric) AND (final_margin_pct <= (100)::numeric)))),
    CONSTRAINT chk_proposals_margin_pct CHECK (((margin_pct IS NULL) OR ((margin_pct >= ('-100'::integer)::numeric) AND (margin_pct <= (100)::numeric)))),
    CONSTRAINT chk_proposals_original_margin_pct CHECK (((original_margin_pct IS NULL) OR ((original_margin_pct >= ('-100'::integer)::numeric) AND (original_margin_pct <= (100)::numeric))))
);


--
-- Name: COLUMN proposals.solution_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.proposals.solution_type IS 'Tipologia do pedido / solucao a aplicar. Nao representa product_type nem budget_typology.';


--
-- Name: delete_draft_proposal(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_draft_proposal(p_proposal_id uuid) RETURNS public.proposals
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_proposal public.proposals%rowtype;
begin
  if p_proposal_id is null then
    raise exception 'p_proposal_id is required';
  end if;

  select *
  into v_proposal
  from public.proposals
  where id = p_proposal_id
  for update;

  if not found then
    raise exception 'Proposal not found: %', p_proposal_id;
  end if;

  if v_proposal.sent_at is not null then
    raise exception 'Sent proposals cannot be deleted: %', p_proposal_id;
  end if;

  delete from public.proposals
  where id = p_proposal_id;

  return v_proposal;
end;
$$;


--
-- Name: get_next_order_seq(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_next_order_seq(p_year integer, p_sigla text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_next integer;
BEGIN

  UPDATE order_counters
  SET last_seq = last_seq + 1
  WHERE order_year = p_year
  AND commercial_sigla = p_sigla
  RETURNING last_seq INTO v_next;

  IF v_next IS NULL THEN
    INSERT INTO order_counters(order_year, commercial_sigla, last_seq)
    VALUES (p_year, p_sigla, 1)
    RETURNING last_seq INTO v_next;
  END IF;

  RETURN v_next;

END;
$$;


--
-- Name: import_proposal_from_excel(uuid, text, numeric, numeric, numeric, numeric, numeric, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.import_proposal_from_excel(p_order_version_id uuid, p_file_name text, p_total_material numeric, p_total_mo numeric, p_total_projeto numeric, p_total_venda numeric, p_margem_pct numeric, p_equipment_blocks jsonb) RETURNS TABLE(proposal_id uuid, inserted_items_count integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_proposal_id uuid;
  v_user_id uuid;
  v_item jsonb;
  v_attr record;
  v_attr_def record;
  v_item_id bigint;
  v_item_index integer := 0;
  v_inserted_items_count integer := 0;

  v_equipment_name text;
  v_specification text;
  v_quantity_text text;
  v_quantity_normalized text;
  v_quantity numeric;
  v_cost_total numeric;
  v_margin numeric;
  v_value_text text;
  v_value_number numeric;
  v_value_boolean boolean;
begin
  v_user_id := auth.uid();

  if p_order_version_id is null then
    raise exception 'order_version_id is required';
  end if;

  if not exists (
    select 1
    from public.order_versions ov
    where ov.id = p_order_version_id
  ) then
    raise exception 'Order version not found: %', p_order_version_id;
  end if;

  if exists (
    select 1
    from public.proposals p
    where p.order_version_id = p_order_version_id
  ) then
    raise exception 'A proposal already exists for order_version_id: %', p_order_version_id;
  end if;

  if p_equipment_blocks is null then
    p_equipment_blocks := '[]'::jsonb;
  end if;

  if jsonb_typeof(p_equipment_blocks) <> 'array' then
    raise exception 'p_equipment_blocks must be a JSON array';
  end if;

  insert into public.proposals (
    order_version_id,
    cost_material_total,
    cost_labor_total,
    cost_project_total,
    cost_total,
    sell_total,
    margin_pct,
    original_margin_pct,
    final_margin_pct
  )
  values (
    p_order_version_id,
    coalesce(p_total_material, 0),
    coalesce(p_total_mo, 0),
    coalesce(p_total_projeto, 0),
    coalesce(p_total_material, 0)
      + coalesce(p_total_mo, 0)
      + coalesce(p_total_projeto, 0),
    coalesce(p_total_venda, 0),
    coalesce(p_margem_pct, 0) * 100,
    coalesce(p_margem_pct, 0) * 100,
    coalesce(p_margem_pct, 0) * 100
  )
  returning id into v_proposal_id;

  for v_item in
    select value
    from jsonb_array_elements(p_equipment_blocks)
  loop
    v_item_index := v_item_index + 1;

    v_equipment_name := nullif(trim(coalesce(v_item->>'main_equipment', '')), '');
    v_specification := nullif(trim(coalesce(v_item->>'main_description', '')), '');

    if v_equipment_name is null then
      v_equipment_name := coalesce(v_specification, 'Item ' || v_item_index::text);
    end if;

    v_quantity_text := nullif(trim(coalesce(v_item->>'quantity', '')), '');
    v_quantity := 1;

    if v_quantity_text is not null then
      v_quantity_normalized := replace(replace(replace(v_quantity_text, ' ', ''), '.', ''), ',', '.');

      begin
        v_quantity := coalesce(nullif(v_quantity_normalized, '')::numeric, 1);
      exception
        when others then
          v_quantity := 1;
      end;
    end if;

    v_cost_total := 0;
    begin
      v_cost_total := coalesce((v_item->>'cost_total')::numeric, 0);
    exception
      when others then
        v_cost_total := 0;
    end;

    v_margin := 0;
    begin
      v_margin := coalesce((v_item->>'margin')::numeric, 0);
    exception
      when others then
        v_margin := 0;
    end;

    insert into public.proposal_items (
      proposal_id,
      order_version_id,
      position,
      equipment_name,
      specification,
      quantity,
      cost_total,
      margin,
      raw_payload
    )
    values (
      v_proposal_id,
      p_order_version_id,
      v_item_index,
      v_equipment_name,
      v_specification,
      v_quantity,
      v_cost_total,
      v_margin,
      v_item
    )
    returning id into v_item_id;

    v_inserted_items_count := v_inserted_items_count + 1;

    for v_attr in
      select key, value
      from jsonb_each_text(coalesce(v_item->'detected_attributes', '{}'::jsonb))
    loop
      v_value_text := nullif(trim(coalesce(v_attr.value, '')), '');

      if v_value_text is null then
        continue;
      end if;

      select
        pad.id,
        pad.value_type
      into v_attr_def
      from public.product_attribute_definitions pad
      where pad.code = v_attr.key
        and pad.is_active = true
      limit 1;

      if not found then
        continue;
      end if;

      v_value_number := null;
      v_value_boolean := null;

      if v_attr_def.value_type = 'number' then
        begin
          v_value_number := replace(replace(replace(v_value_text, ' ', ''), '.', ''), ',', '.')::numeric;
        exception
          when others then
            continue;
        end;
      elsif v_attr_def.value_type = 'boolean' then
        v_value_boolean := lower(v_value_text) in ('true', '1', 'yes', 'y', 'sim');
      end if;

      insert into public.proposal_item_attribute_values (
        proposal_item_id,
        attribute_definition_id,
        value_text,
        value_number,
        value_boolean
      )
      values (
        v_item_id,
        v_attr_def.id,
        case when v_attr_def.value_type = 'text' then v_value_text else null end,
        case when v_attr_def.value_type = 'number' then v_value_number else null end,
        case when v_attr_def.value_type = 'boolean' then v_value_boolean else null end
      );
    end loop;
  end loop;

  insert into public.budget_import_data (
    order_version_id,
    proposal_id,
    imported_by,
    source_name,
    raw_payload
  )
  values (
    p_order_version_id,
    v_proposal_id,
    v_user_id,
    nullif(trim(coalesce(p_file_name, '')), ''),
    jsonb_build_object(
      'file_name', p_file_name,
      'total_material', p_total_material,
      'total_mo', p_total_mo,
      'total_projeto', p_total_projeto,
      'total_venda', p_total_venda,
      'margem_pct', p_margem_pct,
      'equipment_blocks', p_equipment_blocks
    )
  );

  return query
  select v_proposal_id, v_inserted_items_count;
end;
$$;


--
-- Name: log_order_status_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_order_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if (new.status::text) is distinct from (old.status::text) then
    insert into order_status_history (order_id, old_status, new_status)
    values (new.id, old.status::text, new.status::text);
  end if;
  return new;
end;
$$;


--
-- Name: orders_set_ref(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.orders_set_ref() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_sigla text;
  v_next int;
begin

  -- 1) Se já vier sigla no registo (ex: enviada pela SP), usa-a
  v_sigla := nullif(trim(new.commercial_sigla), '');

  -- 2) Se não vier, busca pela sigla do user associado
  if v_sigla is null then
    select initials into v_sigla
    from profiles
    where user_id = new.commercial_user_id;

    v_sigla := nullif(trim(v_sigla), '');
  end if;

  if v_sigla is null then
    raise exception 'Comercial sem sigla (commercial_sigla ou profiles.initials).';
  end if;

  new.commercial_sigla := v_sigla;

  if new.order_year is null then
    new.order_year := extract(year from current_date)::int;
  end if;

  -- garantir linha de contador
  insert into order_counters(order_year, commercial_sigla, last_seq)
  values (new.order_year, new.commercial_sigla, 0)
  on conflict (order_year, commercial_sigla) do nothing;

  -- obter próximo número
  update order_counters
  set last_seq = last_seq + 1
  where order_year = new.order_year
    and commercial_sigla = new.commercial_sigla
  returning last_seq into v_next;

  new.order_seq := v_next;

  -- gerar ref
  new.order_ref :=
    new.order_year::text || ' ' ||
    new.commercial_sigla || ' ' ||
    lpad(new.order_seq::text, 3, '0');

  return new;

end;
$$;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    vat_number text,
    email text,
    phone text,
    created_at timestamp with time zone DEFAULT now(),
    country_id smallint,
    vat_country_prefix character(2),
    vat_number_digits text,
    commercial_user_id uuid
);


--
-- Name: reassign_customer_commercial(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reassign_customer_commercial(p_customer_id uuid, p_commercial_user_id uuid) RETURNS public.customers
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_row public.customers;
begin
  if p_customer_id is null then
    raise exception 'Customer is required';
  end if;

  if p_commercial_user_id is null then
    raise exception 'Commercial user is required';
  end if;

  if not exists (
    select 1
    from public.commercials_list_view clv
    where clv.user_id = p_commercial_user_id
      and clv.is_active = true
  ) then
    raise exception 'Comercial responsavel invalido ou inativo.';
  end if;

  update public.customers
  set commercial_user_id = p_commercial_user_id
  where id = p_customer_id
  returning * into v_row;

  if not found then
    raise exception 'Cliente nao encontrado.';
  end if;

  return v_row;
end;
$$;


--
-- Name: remove_customer_contact(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_customer_contact(p_contact_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_customer_id uuid;
  v_was_primary boolean;
  v_remaining_count int;
  v_new_primary uuid;
begin
  -- obter info do contacto
  select customer_id, is_primary
  into v_customer_id, v_was_primary
  from public.contacts
  where id = p_contact_id;

  if v_customer_id is null then
    raise exception 'Contacto não existe.';
  end if;

  -- contar contactos do cliente
  select count(*) into v_remaining_count
  from public.contacts
  where customer_id = v_customer_id;

  -- impedir ficar sem contactos
  if v_remaining_count <= 1 then
    raise exception 'O cliente tem de ter pelo menos 1 contacto.';
  end if;

  -- remover contacto
  delete from public.contacts
  where id = p_contact_id;

  -- se removeste o primário, escolher outro (mais antigo)
  if v_was_primary then
    select id into v_new_primary
    from public.contacts
    where customer_id = v_customer_id
    order by created_at asc
    limit 1;

    update public.contacts
    set is_primary = (id = v_new_primary)
    where customer_id = v_customer_id;
  end if;
end;
$$;


--
-- Name: remove_customer_site(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_customer_site(p_site_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_customer_id uuid;
  v_remaining_count int;
  v_linked_orders_count int;
begin
  select customer_id
  into v_customer_id
  from public.customer_sites
  where id = p_site_id;

  if v_customer_id is null then
    raise exception 'Local nao existe.';
  end if;

  select count(*)
  into v_remaining_count
  from public.customer_sites
  where customer_id = v_customer_id;

  if v_remaining_count <= 1 then
    raise exception 'O cliente tem de ter pelo menos 1 local.';
  end if;

  select count(*)
  into v_linked_orders_count
  from public.orders
  where customer_site_id = p_site_id;

  if v_linked_orders_count > 0 then
    raise exception 'Nao podes remover um local ja associado a pedidos.';
  end if;

  delete from public.customer_sites
  where id = p_site_id;
end;
$$;


--
-- Name: rls_auto_enable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rls_auto_enable() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


--
-- Name: send_proposal(uuid, timestamp with time zone, timestamp with time zone, timestamp with time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.send_proposal(p_proposal_id uuid, p_sent_at timestamp with time zone, p_feedback_at timestamp with time zone, p_valid_until timestamp with time zone, p_note text DEFAULT NULL::text) RETURNS public.proposals
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_proposal public.proposals%rowtype;
  v_old_phase_id bigint;
  v_sent_phase_id bigint;
  v_order_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Utilizador autenticado obrigatorio';
  end if;

  if p_sent_at is null then
    raise exception 'p_sent_at e obrigatorio';
  end if;

  if p_feedback_at is null then
    raise exception 'p_feedback_at e obrigatorio';
  end if;

  if p_valid_until is null then
    raise exception 'p_valid_until e obrigatorio';
  end if;

  select p.*
  into v_proposal
  from public.proposals p
  where p.id = p_proposal_id;

  if not found then
    raise exception 'Proposal nao encontrada: %', p_proposal_id;
  end if;

  v_old_phase_id := v_proposal.phase_id;

  select pp.id
  into v_sent_phase_id
  from public.proposal_phases pp
  where lower(pp.code) = 'enviado'
  limit 1;

  update public.proposals
  set
    sent_at = p_sent_at,
    feedback_at = p_feedback_at,
    valid_until = p_valid_until,
    sent_by = v_user_id,
    phase_id = coalesce(v_sent_phase_id, phase_id)
  where id = p_proposal_id
  returning *
  into v_proposal;

  if v_old_phase_id is distinct from v_proposal.phase_id then
    insert into public.proposal_phase_history (
      proposal_id,
      old_phase_id,
      new_phase_id,
      changed_by,
      changed_at
    )
    values (
      v_proposal.id,
      v_old_phase_id,
      v_proposal.phase_id,
      v_user_id,
      now()
    );
  end if;

  if p_note is not null and btrim(p_note) <> '' then
    insert into public.proposal_feedback_history (
      proposal_id,
      created_by,
      created_at
    )
    values (
      v_proposal.id,
      v_user_id,
      now()
    );
  end if;

  select ov.order_id
  into v_order_id
  from public.order_versions ov
  where ov.id = v_proposal.order_version_id;

  if v_order_id is not null then
    update public.orders o
    set commercial_phase_id = wp.id
    from public.workflow_phases wp
    where o.id = v_order_id
      and wp.department_code = 'COM'
      and lower(wp.code) = 'enviado';
  end if;

  return v_proposal;
end;
$$;


--
-- Name: set_order_commercial_phase(uuid, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_order_commercial_phase(p_order_id uuid, p_commercial_phase_id bigint) RETURNS public.orders
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
    order by ov.created_at desc, ov.id desc
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


--
-- Name: sync_budget_assignment_worked_hours(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_budget_assignment_worked_hours() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_assignment_id bigint;
begin
  v_assignment_id := coalesce(new.budget_assignment_id, old.budget_assignment_id);

  update public.order_budget_assignments oba
  set worked_hours = coalesce((
    select sum(wte.hours)
    from public.work_time_entries wte
    where wte.budget_assignment_id = v_assignment_id
  ), 0)
  where oba.id = v_assignment_id;

  return coalesce(new, old);
end;
$$;


--
-- Name: sync_proposal_validity_followup(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_proposal_validity_followup() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_order_id uuid;
begin
  select ov.order_id
  into v_order_id
  from public.order_versions ov
  where ov.id = new.order_version_id;

  if v_order_id is null then
    raise exception 'Order nao encontrada para a proposal.';
  end if;

  if new.valid_until is null then
    delete from public.proposal_followups
    where proposal_id = new.id
      and followup_type = 'validity_reminder'
      and completed_at is null;
    return new;
  end if;

  delete from public.proposal_followups
  where proposal_id = new.id
    and followup_type = 'validity_reminder'
    and completed_at is null;

  insert into public.proposal_followups (
    proposal_id,
    order_id,
    order_version_id,
    assigned_to,
    followup_type,
    scheduled_for,
    status,
    note
  )
  values (
    new.id,
    v_order_id,
    new.order_version_id,
    new.sent_by,
    'validity_reminder',
    new.valid_until - interval '1 day',
    'pending',
    'Follow-up automatico na vespera da validade da proposta.'
  );

  return new;
end;
$$;


--
-- Name: update_budget_assignment_hours(uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_budget_assignment_hours(p_assignment_id uuid, p_worked_hours numeric) RETURNS public.order_budget_assignments
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_row public.order_budget_assignments;
begin
  if p_assignment_id is null then
    raise exception 'Assignment is required';
  end if;

  if p_worked_hours is null or p_worked_hours < 0 then
    raise exception 'Worked hours invalidas';
  end if;

  update public.order_budget_assignments
  set worked_hours = p_worked_hours
  where id = p_assignment_id
  returning * into v_row;

  if not found then
    raise exception 'Assignment nao encontrado.';
  end if;

  return v_row;
end;
$$;


--
-- Name: order_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    revision_code text,
    revision_ref text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    version_number integer NOT NULL,
    requested_by_contact_id uuid,
    change_reason text,
    created_by uuid,
    supersedes_version_id uuid,
    requested_at date DEFAULT CURRENT_DATE NOT NULL,
    sent_to_budgeting_at timestamp with time zone,
    expected_delivery_date date,
    budget_delivered_at timestamp with time zone,
    actually_delivered_at timestamp with time zone,
    CONSTRAINT order_versions_revision_code_format_chk CHECK (((revision_code IS NULL) OR (revision_code ~ '^[A-Z]$'::text)))
);


--
-- Name: update_latest_order_version_expected_delivery(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_latest_order_version_expected_delivery(p_order_id uuid, p_expected_delivery_date date) RETURNS public.order_versions
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_version public.order_versions;
begin
  if p_order_id is null then
    raise exception 'Order is required';
  end if;

  update public.order_versions ov
  set expected_delivery_date = p_expected_delivery_date
  where ov.id = (
    select v.id
    from public.order_versions v
    where v.order_id = p_order_id
    order by v.version_number desc nulls last, v.created_at desc, v.id desc
    limit 1
  )
  returning * into v_version;

  if not found then
    raise exception 'Versao atual nao encontrada para o pedido.';
  end if;

  return v_version;
end;
$$;


--
-- Name: update_order_budget_details(uuid, bigint, bigint, bigint, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_order_budget_details(p_order_id uuid, p_budgeting_phase_id bigint, p_budget_typology_id bigint, p_product_type_id bigint, p_is_special boolean) RETURNS TABLE(order_id uuid, budgeting_phase_id bigint, assignment_id bigint, budget_typology_id bigint, product_type_id bigint, is_special boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_assignment_id bigint;
begin
  -- 1) Atualizar estado de orçamentação no order (se vier preenchido)
  if p_budgeting_phase_id is not null then
    update public.orders o
    set budgeting_phase_id = p_budgeting_phase_id
    where o.id = p_order_id;
  end if;

  -- 2) Atualizar a assignment ativa (sem trocar assignee)
  update public.order_budget_assignments oba
  set
    budget_typology_id = p_budget_typology_id,
    product_type_id = p_product_type_id, -- pode ser null
    is_special = coalesce(p_is_special, false)
  where oba.order_id = p_order_id
    and oba.is_active = true
  returning oba.id into v_assignment_id;

  if v_assignment_id is null then
    raise exception 'No active budget assignment found for order %', p_order_id;
  end if;

  -- 3) Retornar dados úteis
  return query
  select
    o.id as order_id,
    o.budgeting_phase_id,
    oba.id as assignment_id,
    oba.budget_typology_id,
    oba.product_type_id,
    oba.is_special
  from public.orders o
  join public.order_budget_assignments oba
    on oba.order_id = o.id
  where o.id = p_order_id
    and oba.id = v_assignment_id;
end;
$$;


--
-- Name: update_order_budget_details(uuid, uuid, bigint, bigint, bigint, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_order_budget_details(p_order_id uuid, p_order_version_id uuid, p_budgeting_phase_id bigint, p_budget_typology_id bigint, p_product_type_id bigint, p_is_special boolean) RETURNS TABLE(order_id uuid, budgeting_phase_id bigint, assignment_id bigint, budget_typology_id bigint, product_type_id bigint, is_special boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_assignment_id bigint;
begin
  if p_budgeting_phase_id is not null then
    update public.orders o
    set budgeting_phase_id = p_budgeting_phase_id
    where o.id = p_order_id;
  end if;

  update public.order_budget_assignments oba
  set
    budget_typology_id = coalesce(p_budget_typology_id, oba.budget_typology_id),
    product_type_id = p_product_type_id,
    is_special = coalesce(p_is_special, false)
  where oba.order_version_id = p_order_version_id
    and oba.is_active = true
  returning oba.id into v_assignment_id;

  if v_assignment_id is null then
    raise exception 'No active budget assignment found for order_version %', p_order_version_id;
  end if;

  return query
  select
    o.id as order_id,
    o.budgeting_phase_id,
    oba.id as assignment_id,
    oba.budget_typology_id,
    oba.product_type_id,
    oba.is_special
  from public.orders o
  join public.order_versions ov
    on ov.order_id = o.id
  join public.order_budget_assignments oba
    on oba.order_version_id = ov.id
  where o.id = p_order_id
    and ov.id = p_order_version_id
    and oba.id = v_assignment_id;
end;
$$;


--
-- Name: update_order_status(uuid, public.order_status); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_order_status(p_order_id uuid, p_new_status public.order_status) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_old public.order_status;
begin
  select status into v_old
  from public.orders
  where id = p_order_id;

  update public.orders
  set status = p_new_status
  where id = p_order_id;

  insert into public.order_status_history (
    order_id,
    old_status,
    new_status,
    changed_by,
    changed_at
  )
  values (
    p_order_id,
    v_old::text,
    p_new_status::text,
    auth.uid(),
    now()
  );
end;
$$;


--
-- Name: validate_adjudication_business_refs(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_adjudication_business_refs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_version_order_id uuid;
  v_proposal_version_id uuid;
  v_contact_customer_id uuid;
  v_order_customer_id uuid;
begin
  select ov.order_id
  into v_version_order_id
  from public.order_versions ov
  where ov.id = new.order_version_id;

  if v_version_order_id is null then
    raise exception 'Order version nao encontrada.';
  end if;

  if v_version_order_id <> new.order_id then
    raise exception 'A order_version_id nao pertence a order_id.';
  end if;

  if new.proposal_id is not null then
    select p.order_version_id
    into v_proposal_version_id
    from public.proposals p
    where p.id = new.proposal_id;

    if v_proposal_version_id is null then
      raise exception 'Proposal nao encontrada.';
    end if;

    if v_proposal_version_id <> new.order_version_id then
      raise exception 'A proposal nao pertence a order_version adjudicada.';
    end if;
  end if;

  if new.customer_contact_id is not null then
    select c.customer_id
    into v_contact_customer_id
    from public.contacts c
    where c.id = new.customer_contact_id;

    select o.customer_id
    into v_order_customer_id
    from public.orders o
    where o.id = new.order_id;

    if v_contact_customer_id is null then
      raise exception 'Customer contact nao encontrado.';
    end if;

    if v_order_customer_id is null then
      raise exception 'Order nao encontrada.';
    end if;

    if v_contact_customer_id <> v_order_customer_id then
      raise exception 'O contacto da adjudicacao nao pertence ao cliente da order.';
    end if;
  end if;

  return new;
end;
$$;


--
-- Name: validate_awarded_order_version(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_awarded_order_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.awarded_order_version_id is null then
    return new;
  end if;

  if not exists (
    select 1
    from public.order_versions ov
    where ov.id = new.awarded_order_version_id
      and ov.order_id = new.id
  ) then
    raise exception 'A versão adjudicada não pertence ao pedido.';
  end if;

  return new;
end;
$$;


--
-- Name: validate_order_business_refs(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_order_business_refs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_site_customer_id uuid;
  v_primary_contact_customer_id uuid;
  v_contact_customer_id uuid;
begin
  if new.customer_site_id is not null then
    select cs.customer_id
    into v_site_customer_id
    from public.customer_sites cs
    where cs.id = new.customer_site_id;

    if v_site_customer_id is null then
      raise exception 'Customer site nao encontrado.';
    end if;

    if new.customer_id is null or v_site_customer_id <> new.customer_id then
      raise exception 'O local selecionado nao pertence ao cliente da order.';
    end if;
  end if;

  if new.primary_contact_id is not null then
    select c.customer_id
    into v_primary_contact_customer_id
    from public.contacts c
    where c.id = new.primary_contact_id;

    if v_primary_contact_customer_id is null then
      raise exception 'Primary contact nao encontrado.';
    end if;

    if new.customer_id is null or v_primary_contact_customer_id <> new.customer_id then
      raise exception 'O primary_contact_id nao pertence ao cliente da order.';
    end if;
  end if;

  if new.contact_id is not null then
    select c.customer_id
    into v_contact_customer_id
    from public.contacts c
    where c.id = new.contact_id;

    if v_contact_customer_id is null then
      raise exception 'Contact nao encontrado.';
    end if;

    if new.customer_id is null or v_contact_customer_id <> new.customer_id then
      raise exception 'O contact_id nao pertence ao cliente da order.';
    end if;
  end if;

  return new;
end;
$$;


--
-- Name: validate_order_version_business_refs(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_order_version_business_refs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_order_customer_id uuid;
  v_contact_customer_id uuid;
begin
  if new.requested_by_contact_id is null then
    return new;
  end if;

  select o.customer_id
  into v_order_customer_id
  from public.orders o
  where o.id = new.order_id;

  if v_order_customer_id is null then
    raise exception 'Order nao encontrada para a versao.';
  end if;

  select c.customer_id
  into v_contact_customer_id
  from public.contacts c
  where c.id = new.requested_by_contact_id;

  if v_contact_customer_id is null then
    raise exception 'Requested-by contact nao encontrado.';
  end if;

  if v_contact_customer_id <> v_order_customer_id then
    raise exception 'O requested_by_contact_id nao pertence ao cliente da order.';
  end if;

  return new;
end;
$$;


--
-- Name: adjudications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adjudications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    order_version_id uuid NOT NULL,
    proposal_id uuid,
    adjudicated_by uuid,
    adjudicated_at timestamp with time zone DEFAULT now() NOT NULL,
    customer_contact_id uuid,
    note text,
    status text DEFAULT 'awarded'::text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_adjudications_status CHECK ((status = ANY (ARRAY['awarded'::text, 'cancelled'::text])))
);


--
-- Name: budget_import_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget_import_data (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_version_id uuid NOT NULL,
    proposal_id uuid,
    imported_by uuid,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    source_name text,
    raw_payload jsonb
);


--
-- Name: budget_supplier_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget_supplier_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_version_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    requested_by uuid,
    requested_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    request_subject text,
    request_details text NOT NULL,
    response_summary text,
    response_amount numeric(14,2),
    currency_code text DEFAULT 'EUR'::text,
    status text DEFAULT 'pending'::text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_budget_supplier_requests_status CHECK ((status = ANY (ARRAY['pending'::text, 'answered'::text, 'cancelled'::text])))
);


--
-- Name: budget_typologies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget_typologies (
    id bigint NOT NULL,
    name text NOT NULL,
    sort_order integer,
    is_active boolean DEFAULT true
);


--
-- Name: budget_typologies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budget_typologies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budget_typologies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budget_typologies_id_seq OWNED BY public.budget_typologies.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id smallint NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


--
-- Name: profile_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_roles (
    user_id uuid NOT NULL,
    role_id smallint NOT NULL
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    user_id uuid NOT NULL,
    full_name text NOT NULL,
    initials text,
    department_id smallint,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    pin text
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id smallint NOT NULL,
    code text NOT NULL,
    name text NOT NULL
);


--
-- Name: commercials_list_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.commercials_list_view AS
 SELECT p.user_id,
    p.full_name,
    p.initials,
    p.is_active,
    d.name AS department_name
   FROM (((public.profiles p
     LEFT JOIN public.departments d ON ((d.id = p.department_id)))
     JOIN public.profile_roles pr ON ((pr.user_id = p.user_id)))
     JOIN public.roles r ON ((r.id = pr.role_id)))
  WHERE (r.code = 'COMERCIAL'::text)
  ORDER BY p.is_active DESC, p.full_name;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    name text NOT NULL,
    email text,
    phone text,
    role text,
    is_primary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    id smallint NOT NULL,
    name text NOT NULL,
    iso2 character(2) NOT NULL,
    iso3 character(3),
    phone_prefix text,
    vat_prefix text NOT NULL
);


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.countries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_list_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.customer_list_view AS
SELECT
    NULL::uuid AS id,
    NULL::text AS name,
    NULL::text AS vat_number,
    NULL::text AS email,
    NULL::text AS phone,
    NULL::text AS country_name,
    NULL::uuid AS commercial_user_id,
    NULL::text AS commercial_name,
    NULL::bigint AS contact_count;


--
-- Name: customer_sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_sites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    name text NOT NULL,
    code text,
    address_line_1 text,
    address_line_2 text,
    postal_code text,
    city text,
    country_id smallint,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.departments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: order_budget_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_budget_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_budget_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.order_budget_assignments_id_seq OWNED BY public.order_budget_assignments.id;


--
-- Name: order_counters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_counters (
    order_year integer NOT NULL,
    commercial_sigla text NOT NULL,
    last_seq integer DEFAULT 0 NOT NULL
);


--
-- Name: order_phase_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_phase_history (
    id bigint NOT NULL,
    order_id uuid NOT NULL,
    department_code text NOT NULL,
    old_phase_id bigint,
    new_phase_id bigint NOT NULL,
    changed_by uuid,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    note text
);


--
-- Name: order_phase_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_phase_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_phase_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.order_phase_history_id_seq OWNED BY public.order_phase_history.id;


--
-- Name: order_status_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_status_history (
    id bigint NOT NULL,
    order_id uuid NOT NULL,
    old_status text,
    new_status text NOT NULL,
    changed_by uuid,
    changed_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: order_status_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.order_status_history ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.order_status_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_attribute_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_attribute_definitions (
    id bigint NOT NULL,
    code text NOT NULL,
    label text NOT NULL,
    value_type text NOT NULL,
    source_type text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sort_order integer,
    CONSTRAINT product_attribute_definitions_source_type_check CHECK ((source_type = ANY (ARRAY['reference'::text, 'derived'::text, 'manual'::text]))),
    CONSTRAINT product_attribute_definitions_value_type_check CHECK ((value_type = ANY (ARRAY['number'::text, 'text'::text, 'boolean'::text])))
);


--
-- Name: product_attribute_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.product_attribute_definitions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.product_attribute_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_types (
    id bigint NOT NULL,
    name text NOT NULL,
    sort_order integer,
    is_active boolean DEFAULT true
);


--
-- Name: product_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_types_id_seq OWNED BY public.product_types.id;


--
-- Name: proposal_feedback_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposal_feedback_history (
    id bigint NOT NULL,
    proposal_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    contact_type text NOT NULL,
    note text NOT NULL,
    next_followup_at timestamp with time zone,
    outcome text
);


--
-- Name: proposal_feedback_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.proposal_feedback_history ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.proposal_feedback_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: proposal_followups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposal_followups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    proposal_id uuid NOT NULL,
    order_id uuid NOT NULL,
    order_version_id uuid NOT NULL,
    assigned_to uuid,
    followup_type text NOT NULL,
    scheduled_for timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    status text DEFAULT 'pending'::text NOT NULL,
    outcome text,
    note text,
    rescheduled_from timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_proposal_followups_status CHECK ((status = ANY (ARRAY['pending'::text, 'done'::text, 'cancelled'::text])))
);


--
-- Name: proposal_item_attribute_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposal_item_attribute_values (
    id bigint NOT NULL,
    proposal_item_id bigint NOT NULL,
    attribute_definition_id bigint NOT NULL,
    value_text text,
    value_number numeric,
    value_boolean boolean,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: proposal_item_attribute_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.proposal_item_attribute_values ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.proposal_item_attribute_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: proposal_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposal_items (
    id bigint NOT NULL,
    proposal_id uuid NOT NULL,
    order_version_id uuid NOT NULL,
    "position" integer NOT NULL,
    equipment_name text NOT NULL,
    specification text,
    quantity numeric DEFAULT 1 NOT NULL,
    cost_total numeric,
    sell_unit numeric,
    sell_total numeric,
    margin numeric,
    is_special boolean DEFAULT false NOT NULL,
    raw_payload jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: proposal_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.proposal_items ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.proposal_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: proposal_phase_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposal_phase_history (
    id bigint NOT NULL,
    proposal_id uuid NOT NULL,
    old_phase_id bigint,
    new_phase_id bigint NOT NULL,
    changed_by uuid,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    note text
);


--
-- Name: proposal_phase_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proposal_phase_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: proposal_phase_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proposal_phase_history_id_seq OWNED BY public.proposal_phase_history.id;


--
-- Name: proposal_phases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposal_phases (
    id bigint NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    sort_order integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_terminal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT proposal_phases_sort_order_check CHECK ((sort_order > 0))
);


--
-- Name: proposal_phases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proposal_phases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: proposal_phases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proposal_phases_id_seq OWNED BY public.proposal_phases.id;


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    email text,
    phone text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: work_time_category_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_time_category_definitions (
    id bigint NOT NULL,
    department_id smallint NOT NULL,
    code text NOT NULL,
    label text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: work_time_category_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.work_time_category_definitions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.work_time_category_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: work_time_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.work_time_entries ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.work_time_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_phases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_phases (
    id bigint NOT NULL,
    department_code text NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    sort_order integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_terminal boolean DEFAULT false NOT NULL,
    requires_note boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT workflow_phases_sort_order_check CHECK ((sort_order > 0))
);


--
-- Name: workflow_phases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_phases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_phases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_phases_id_seq OWNED BY public.workflow_phases.id;


--
-- Name: budget_typologies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_typologies ALTER COLUMN id SET DEFAULT nextval('public.budget_typologies_id_seq'::regclass);


--
-- Name: order_budget_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_budget_assignments ALTER COLUMN id SET DEFAULT nextval('public.order_budget_assignments_id_seq'::regclass);


--
-- Name: order_phase_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_phase_history ALTER COLUMN id SET DEFAULT nextval('public.order_phase_history_id_seq'::regclass);


--
-- Name: product_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_types ALTER COLUMN id SET DEFAULT nextval('public.product_types_id_seq'::regclass);


--
-- Name: proposal_phase_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_phase_history ALTER COLUMN id SET DEFAULT nextval('public.proposal_phase_history_id_seq'::regclass);


--
-- Name: proposal_phases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_phases ALTER COLUMN id SET DEFAULT nextval('public.proposal_phases_id_seq'::regclass);


--
-- Name: workflow_phases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_phases ALTER COLUMN id SET DEFAULT nextval('public.workflow_phases_id_seq'::regclass);


--
-- Name: adjudications adjudications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjudications
    ADD CONSTRAINT adjudications_pkey PRIMARY KEY (id);


--
-- Name: budget_import_data budget_import_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_import_data
    ADD CONSTRAINT budget_import_data_pkey PRIMARY KEY (id);


--
-- Name: budget_supplier_requests budget_supplier_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_supplier_requests
    ADD CONSTRAINT budget_supplier_requests_pkey PRIMARY KEY (id);


--
-- Name: budget_typologies budget_typologies_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_typologies
    ADD CONSTRAINT budget_typologies_name_key UNIQUE (name);


--
-- Name: budget_typologies budget_typologies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_typologies
    ADD CONSTRAINT budget_typologies_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: countries countries_iso2_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_iso2_key UNIQUE (iso2);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: countries countries_vat_prefix_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_vat_prefix_key UNIQUE (vat_prefix);


--
-- Name: customer_sites customer_sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_sites
    ADD CONSTRAINT customer_sites_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: departments departments_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_code_key UNIQUE (code);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: order_budget_assignments order_budget_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_budget_assignments
    ADD CONSTRAINT order_budget_assignments_pkey PRIMARY KEY (id);


--
-- Name: order_counters order_counters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_counters
    ADD CONSTRAINT order_counters_pkey PRIMARY KEY (order_year, commercial_sigla);


--
-- Name: order_phase_history order_phase_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_phase_history
    ADD CONSTRAINT order_phase_history_pkey PRIMARY KEY (id);


--
-- Name: order_versions order_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_versions
    ADD CONSTRAINT order_revisions_pkey PRIMARY KEY (id);


--
-- Name: order_versions order_revisions_revision_ref_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_versions
    ADD CONSTRAINT order_revisions_revision_ref_key UNIQUE (revision_ref);


--
-- Name: order_status_history order_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_pkey PRIMARY KEY (id);


--
-- Name: order_versions order_versions_order_id_revision_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_versions
    ADD CONSTRAINT order_versions_order_id_revision_code_key UNIQUE (order_id, revision_code);


--
-- Name: orders orders_order_ref_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_order_ref_key UNIQUE (order_ref);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: orders orders_year_sigla_seq_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_year_sigla_seq_unique UNIQUE (order_year, commercial_sigla, order_seq);


--
-- Name: product_attribute_definitions product_attribute_definitions_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_attribute_definitions
    ADD CONSTRAINT product_attribute_definitions_code_key UNIQUE (code);


--
-- Name: product_attribute_definitions product_attribute_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_attribute_definitions
    ADD CONSTRAINT product_attribute_definitions_pkey PRIMARY KEY (id);


--
-- Name: product_types product_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT product_types_name_key UNIQUE (name);


--
-- Name: product_types product_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT product_types_pkey PRIMARY KEY (id);


--
-- Name: profile_roles profile_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_roles
    ADD CONSTRAINT profile_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (user_id);


--
-- Name: proposal_feedback_history proposal_feedback_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_feedback_history
    ADD CONSTRAINT proposal_feedback_history_pkey PRIMARY KEY (id);


--
-- Name: proposal_followups proposal_followups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_followups
    ADD CONSTRAINT proposal_followups_pkey PRIMARY KEY (id);


--
-- Name: proposal_item_attribute_values proposal_item_attribute_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_item_attribute_values
    ADD CONSTRAINT proposal_item_attribute_values_pkey PRIMARY KEY (id);


--
-- Name: proposal_item_attribute_values proposal_item_attribute_values_unique_attribute; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_item_attribute_values
    ADD CONSTRAINT proposal_item_attribute_values_unique_attribute UNIQUE (proposal_item_id, attribute_definition_id);


--
-- Name: proposal_items proposal_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_items
    ADD CONSTRAINT proposal_items_pkey PRIMARY KEY (id);


--
-- Name: proposal_items proposal_items_unique_position; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_items
    ADD CONSTRAINT proposal_items_unique_position UNIQUE (proposal_id, "position");


--
-- Name: proposal_phase_history proposal_phase_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_phase_history
    ADD CONSTRAINT proposal_phase_history_pkey PRIMARY KEY (id);


--
-- Name: proposal_phases proposal_phases_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_phases
    ADD CONSTRAINT proposal_phases_code_key UNIQUE (code);


--
-- Name: proposal_phases proposal_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_phases
    ADD CONSTRAINT proposal_phases_pkey PRIMARY KEY (id);


--
-- Name: proposals proposals_order_revision_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_order_revision_id_key UNIQUE (order_version_id);


--
-- Name: proposals proposals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_pkey PRIMARY KEY (id);


--
-- Name: roles roles_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_code_key UNIQUE (code);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: work_time_category_definitions work_time_category_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_time_category_definitions
    ADD CONSTRAINT work_time_category_definitions_pkey PRIMARY KEY (id);


--
-- Name: work_time_category_definitions work_time_category_definitions_unique_code_per_department; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_time_category_definitions
    ADD CONSTRAINT work_time_category_definitions_unique_code_per_department UNIQUE (department_id, code);


--
-- Name: work_time_entries work_time_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_time_entries
    ADD CONSTRAINT work_time_entries_pkey PRIMARY KEY (id);


--
-- Name: workflow_phases workflow_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_phases
    ADD CONSTRAINT workflow_phases_pkey PRIMARY KEY (id);


--
-- Name: idx_order_budget_assignments_assignee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_order_budget_assignments_assignee ON public.order_budget_assignments USING btree (assignee_user_id);


--
-- Name: idx_proposal_item_attr_attribute_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_proposal_item_attr_attribute_id ON public.proposal_item_attribute_values USING btree (attribute_definition_id);


--
-- Name: idx_proposal_item_attr_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_proposal_item_attr_item_id ON public.proposal_item_attribute_values USING btree (proposal_item_id);


--
-- Name: idx_proposal_items_order_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_proposal_items_order_version_id ON public.proposal_items USING btree (order_version_id);


--
-- Name: idx_proposal_items_proposal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_proposal_items_proposal_id ON public.proposal_items USING btree (proposal_id);


--
-- Name: ix_budget_assign_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_budget_assign_active ON public.order_budget_assignments USING btree (is_active);


--
-- Name: ix_budget_assign_assigned_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_budget_assign_assigned_at ON public.order_budget_assignments USING btree (assigned_at DESC);


--
-- Name: ix_budget_assign_assignee_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_budget_assign_assignee_active ON public.order_budget_assignments USING btree (assignee_user_id) WHERE (is_active = true);


--
-- Name: ix_budget_import_data_order_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_budget_import_data_order_version ON public.budget_import_data USING btree (order_version_id);


--
-- Name: ix_budget_supplier_requests_order_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_budget_supplier_requests_order_version ON public.budget_supplier_requests USING btree (order_version_id);


--
-- Name: ix_budget_supplier_requests_supplier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_budget_supplier_requests_supplier ON public.budget_supplier_requests USING btree (supplier_id);


--
-- Name: ix_customer_sites_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_customer_sites_customer ON public.customer_sites USING btree (customer_id);


--
-- Name: ix_order_phase_history_dept; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_order_phase_history_dept ON public.order_phase_history USING btree (department_code, changed_at DESC);


--
-- Name: ix_order_phase_history_new_phase; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_order_phase_history_new_phase ON public.order_phase_history USING btree (new_phase_id);


--
-- Name: ix_order_phase_history_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_order_phase_history_order ON public.order_phase_history USING btree (order_id, changed_at DESC);


--
-- Name: ix_order_status_history_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_order_status_history_order ON public.order_status_history USING btree (order_id, changed_at DESC);


--
-- Name: ix_proposal_followups_scheduled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_proposal_followups_scheduled ON public.proposal_followups USING btree (status, scheduled_for);


--
-- Name: ix_proposal_phase_history_proposal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_proposal_phase_history_proposal ON public.proposal_phase_history USING btree (proposal_id, changed_at DESC);


--
-- Name: ix_workflow_phases_dept; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_workflow_phases_dept ON public.workflow_phases USING btree (department_code);


--
-- Name: order_versions_unique_base; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX order_versions_unique_base ON public.order_versions USING btree (order_id) WHERE (revision_code IS NULL);


--
-- Name: order_versions_unique_letter; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX order_versions_unique_letter ON public.order_versions USING btree (order_id, revision_code) WHERE (revision_code IS NOT NULL);


--
-- Name: proposals_order_version_id_ux; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX proposals_order_version_id_ux ON public.proposals USING btree (order_version_id);


--
-- Name: ux_adjudications_one_active_per_order; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_adjudications_one_active_per_order ON public.adjudications USING btree (order_id) WHERE (is_active = true);


--
-- Name: ux_customer_sites_customer_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_customer_sites_customer_code ON public.customer_sites USING btree (customer_id, code) WHERE (code IS NOT NULL);


--
-- Name: ux_order_versions_order_version_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_order_versions_order_version_number ON public.order_versions USING btree (order_id, version_number) WHERE (version_number IS NOT NULL);


--
-- Name: ux_proposal_phases_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_proposal_phases_sort ON public.proposal_phases USING btree (sort_order);


--
-- Name: ux_suppliers_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_suppliers_name ON public.suppliers USING btree (name);


--
-- Name: ux_workflow_phases_dept_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_workflow_phases_dept_code ON public.workflow_phases USING btree (department_code, code);


--
-- Name: ux_workflow_phases_dept_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_workflow_phases_dept_sort ON public.workflow_phases USING btree (department_code, sort_order);


--
-- Name: customer_list_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.customer_list_view AS
 SELECT c.id,
    c.name,
    c.vat_number,
    c.email,
    c.phone,
    co.name AS country_name,
    c.commercial_user_id,
    p.full_name AS commercial_name,
    count(ct.id) AS contact_count
   FROM (((public.customers c
     LEFT JOIN public.contacts ct ON ((ct.customer_id = c.id)))
     LEFT JOIN public.countries co ON ((co.id = c.country_id)))
     LEFT JOIN public.profiles p ON ((p.user_id = c.commercial_user_id)))
  GROUP BY c.id, co.name, p.full_name;


--
-- Name: orders trg_orders_set_ref; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_orders_set_ref BEFORE INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION public.orders_set_ref();


--
-- Name: work_time_entries trg_sync_budget_assignment_worked_hours; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sync_budget_assignment_worked_hours AFTER INSERT OR DELETE OR UPDATE ON public.work_time_entries FOR EACH ROW EXECUTE FUNCTION public.sync_budget_assignment_worked_hours();


--
-- Name: proposals trg_sync_proposal_validity_followup; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sync_proposal_validity_followup AFTER INSERT OR UPDATE OF valid_until, sent_by ON public.proposals FOR EACH ROW EXECUTE FUNCTION public.sync_proposal_validity_followup();


--
-- Name: adjudications trg_validate_adjudication_business_refs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_validate_adjudication_business_refs BEFORE INSERT OR UPDATE ON public.adjudications FOR EACH ROW EXECUTE FUNCTION public.validate_adjudication_business_refs();


--
-- Name: orders trg_validate_awarded_order_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_validate_awarded_order_version BEFORE INSERT OR UPDATE OF awarded_order_version_id ON public.orders FOR EACH ROW EXECUTE FUNCTION public.validate_awarded_order_version();


--
-- Name: orders trg_validate_order_business_refs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_validate_order_business_refs BEFORE INSERT OR UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.validate_order_business_refs();


--
-- Name: order_versions trg_validate_order_version_business_refs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_validate_order_version_business_refs BEFORE INSERT OR UPDATE ON public.order_versions FOR EACH ROW EXECUTE FUNCTION public.validate_order_version_business_refs();


--
-- Name: adjudications adjudications_adjudicated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjudications
    ADD CONSTRAINT adjudications_adjudicated_by_fkey FOREIGN KEY (adjudicated_by) REFERENCES public.profiles(user_id);


--
-- Name: adjudications adjudications_customer_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjudications
    ADD CONSTRAINT adjudications_customer_contact_id_fkey FOREIGN KEY (customer_contact_id) REFERENCES public.contacts(id);


--
-- Name: adjudications adjudications_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjudications
    ADD CONSTRAINT adjudications_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: adjudications adjudications_order_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjudications
    ADD CONSTRAINT adjudications_order_version_id_fkey FOREIGN KEY (order_version_id) REFERENCES public.order_versions(id) ON DELETE RESTRICT;


--
-- Name: adjudications adjudications_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjudications
    ADD CONSTRAINT adjudications_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.proposals(id) ON DELETE SET NULL;


--
-- Name: budget_import_data budget_import_data_imported_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_import_data
    ADD CONSTRAINT budget_import_data_imported_by_fkey FOREIGN KEY (imported_by) REFERENCES public.profiles(user_id);


--
-- Name: budget_import_data budget_import_data_order_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_import_data
    ADD CONSTRAINT budget_import_data_order_version_id_fkey FOREIGN KEY (order_version_id) REFERENCES public.order_versions(id) ON DELETE CASCADE;


--
-- Name: budget_import_data budget_import_data_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_import_data
    ADD CONSTRAINT budget_import_data_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.proposals(id) ON DELETE SET NULL;


--
-- Name: budget_supplier_requests budget_supplier_requests_order_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_supplier_requests
    ADD CONSTRAINT budget_supplier_requests_order_version_id_fkey FOREIGN KEY (order_version_id) REFERENCES public.order_versions(id) ON DELETE CASCADE;


--
-- Name: budget_supplier_requests budget_supplier_requests_requested_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_supplier_requests
    ADD CONSTRAINT budget_supplier_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.profiles(user_id);


--
-- Name: budget_supplier_requests budget_supplier_requests_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_supplier_requests
    ADD CONSTRAINT budget_supplier_requests_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: contacts contacts_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_sites customer_sites_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_sites
    ADD CONSTRAINT customer_sites_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(id);


--
-- Name: customer_sites customer_sites_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_sites
    ADD CONSTRAINT customer_sites_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customers customers_commercial_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_commercial_user_id_fkey FOREIGN KEY (commercial_user_id) REFERENCES public.profiles(user_id) ON DELETE SET NULL;


--
-- Name: customers customers_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(id);


--
-- Name: orders fk_orders_budgeting_phase; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_orders_budgeting_phase FOREIGN KEY (budgeting_phase_id) REFERENCES public.workflow_phases(id) ON DELETE SET NULL;


--
-- Name: orders fk_orders_commercial_phase; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_orders_commercial_phase FOREIGN KEY (commercial_phase_id) REFERENCES public.workflow_phases(id) ON DELETE SET NULL;


--
-- Name: orders fk_orders_production_phase; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_orders_production_phase FOREIGN KEY (production_phase_id) REFERENCES public.workflow_phases(id) ON DELETE SET NULL;


--
-- Name: orders fk_orders_project_phase; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_orders_project_phase FOREIGN KEY (project_phase_id) REFERENCES public.workflow_phases(id) ON DELETE SET NULL;


--
-- Name: order_budget_assignments order_budget_assignments_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_budget_assignments
    ADD CONSTRAINT order_budget_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.profiles(user_id) ON DELETE SET NULL;


--
-- Name: order_budget_assignments order_budget_assignments_assignee_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_budget_assignments
    ADD CONSTRAINT order_budget_assignments_assignee_user_id_fkey FOREIGN KEY (assignee_user_id) REFERENCES public.profiles(user_id) ON DELETE RESTRICT;


--
-- Name: order_budget_assignments order_budget_assignments_budget_typology_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_budget_assignments
    ADD CONSTRAINT order_budget_assignments_budget_typology_id_fkey FOREIGN KEY (budget_typology_id) REFERENCES public.budget_typologies(id);


--
-- Name: order_budget_assignments order_budget_assignments_order_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_budget_assignments
    ADD CONSTRAINT order_budget_assignments_order_version_id_fkey FOREIGN KEY (order_version_id) REFERENCES public.order_versions(id) ON DELETE CASCADE;


--
-- Name: order_budget_assignments order_budget_assignments_product_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_budget_assignments
    ADD CONSTRAINT order_budget_assignments_product_type_id_fkey FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- Name: order_phase_history order_phase_history_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_phase_history
    ADD CONSTRAINT order_phase_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: order_phase_history order_phase_history_department_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_phase_history
    ADD CONSTRAINT order_phase_history_department_code_fkey FOREIGN KEY (department_code) REFERENCES public.departments(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: order_phase_history order_phase_history_new_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_phase_history
    ADD CONSTRAINT order_phase_history_new_phase_id_fkey FOREIGN KEY (new_phase_id) REFERENCES public.workflow_phases(id) ON DELETE RESTRICT;


--
-- Name: order_phase_history order_phase_history_old_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_phase_history
    ADD CONSTRAINT order_phase_history_old_phase_id_fkey FOREIGN KEY (old_phase_id) REFERENCES public.workflow_phases(id) ON DELETE SET NULL;


--
-- Name: order_phase_history order_phase_history_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_phase_history
    ADD CONSTRAINT order_phase_history_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_versions order_revisions_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_versions
    ADD CONSTRAINT order_revisions_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_status_history order_status_history_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.profiles(user_id);


--
-- Name: order_status_history order_status_history_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_versions order_versions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_versions
    ADD CONSTRAINT order_versions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(user_id);


--
-- Name: order_versions order_versions_requested_by_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_versions
    ADD CONSTRAINT order_versions_requested_by_contact_id_fkey FOREIGN KEY (requested_by_contact_id) REFERENCES public.contacts(id);


--
-- Name: order_versions order_versions_supersedes_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_versions
    ADD CONSTRAINT order_versions_supersedes_version_id_fkey FOREIGN KEY (supersedes_version_id) REFERENCES public.order_versions(id);


--
-- Name: orders orders_awarded_order_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_awarded_order_version_id_fkey FOREIGN KEY (awarded_order_version_id) REFERENCES public.order_versions(id);


--
-- Name: orders orders_commercial_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_commercial_user_id_fkey FOREIGN KEY (commercial_user_id) REFERENCES public.profiles(user_id);


--
-- Name: orders orders_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id);


--
-- Name: orders orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: orders orders_customer_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customer_site_id_fkey FOREIGN KEY (customer_site_id) REFERENCES public.customer_sites(id);


--
-- Name: orders orders_primary_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_primary_contact_id_fkey FOREIGN KEY (primary_contact_id) REFERENCES public.contacts(id);


--
-- Name: profile_roles profile_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_roles
    ADD CONSTRAINT profile_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: profile_roles profile_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_roles
    ADD CONSTRAINT profile_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(user_id) ON DELETE CASCADE;


--
-- Name: profiles profiles_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: profiles profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: proposal_feedback_history proposal_feedback_history_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_feedback_history
    ADD CONSTRAINT proposal_feedback_history_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(user_id);


--
-- Name: proposal_feedback_history proposal_feedback_history_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_feedback_history
    ADD CONSTRAINT proposal_feedback_history_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.proposals(id);


--
-- Name: proposal_followups proposal_followups_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_followups
    ADD CONSTRAINT proposal_followups_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(user_id);


--
-- Name: proposal_followups proposal_followups_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_followups
    ADD CONSTRAINT proposal_followups_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: proposal_followups proposal_followups_order_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_followups
    ADD CONSTRAINT proposal_followups_order_version_id_fkey FOREIGN KEY (order_version_id) REFERENCES public.order_versions(id) ON DELETE CASCADE;


--
-- Name: proposal_followups proposal_followups_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_followups
    ADD CONSTRAINT proposal_followups_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.proposals(id) ON DELETE CASCADE;


--
-- Name: proposal_item_attribute_values proposal_item_attribute_values_attribute_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_item_attribute_values
    ADD CONSTRAINT proposal_item_attribute_values_attribute_fk FOREIGN KEY (attribute_definition_id) REFERENCES public.product_attribute_definitions(id) ON DELETE RESTRICT;


--
-- Name: proposal_item_attribute_values proposal_item_attribute_values_item_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_item_attribute_values
    ADD CONSTRAINT proposal_item_attribute_values_item_fk FOREIGN KEY (proposal_item_id) REFERENCES public.proposal_items(id) ON DELETE CASCADE;


--
-- Name: proposal_items proposal_items_order_version_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_items
    ADD CONSTRAINT proposal_items_order_version_fk FOREIGN KEY (order_version_id) REFERENCES public.order_versions(id) ON DELETE CASCADE;


--
-- Name: proposal_items proposal_items_proposal_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_items
    ADD CONSTRAINT proposal_items_proposal_fk FOREIGN KEY (proposal_id) REFERENCES public.proposals(id) ON DELETE CASCADE;


--
-- Name: proposal_phase_history proposal_phase_history_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_phase_history
    ADD CONSTRAINT proposal_phase_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: proposal_phase_history proposal_phase_history_new_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_phase_history
    ADD CONSTRAINT proposal_phase_history_new_phase_id_fkey FOREIGN KEY (new_phase_id) REFERENCES public.proposal_phases(id) ON DELETE RESTRICT;


--
-- Name: proposal_phase_history proposal_phase_history_old_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_phase_history
    ADD CONSTRAINT proposal_phase_history_old_phase_id_fkey FOREIGN KEY (old_phase_id) REFERENCES public.proposal_phases(id) ON DELETE SET NULL;


--
-- Name: proposal_phase_history proposal_phase_history_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposal_phase_history
    ADD CONSTRAINT proposal_phase_history_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.proposals(id) ON DELETE CASCADE;


--
-- Name: proposals proposals_budget_typology_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_budget_typology_id_fkey FOREIGN KEY (budget_typology_id) REFERENCES public.budget_typologies(id);


--
-- Name: proposals proposals_order_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_order_version_id_fkey FOREIGN KEY (order_version_id) REFERENCES public.order_versions(id) ON DELETE CASCADE;


--
-- Name: proposals proposals_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_phase_id_fkey FOREIGN KEY (phase_id) REFERENCES public.proposal_phases(id) ON DELETE SET NULL;


--
-- Name: proposals proposals_product_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_product_type_id_fkey FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- Name: proposals proposals_sent_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_sent_by_fkey FOREIGN KEY (sent_by) REFERENCES public.profiles(user_id);


--
-- Name: work_time_category_definitions work_time_category_definitions_department_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_time_category_definitions
    ADD CONSTRAINT work_time_category_definitions_department_fk FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE RESTRICT;


--
-- Name: work_time_entries work_time_entries_assignment_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_time_entries
    ADD CONSTRAINT work_time_entries_assignment_fk FOREIGN KEY (budget_assignment_id) REFERENCES public.order_budget_assignments(id) ON DELETE CASCADE;


--
-- Name: work_time_entries work_time_entries_category_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_time_entries
    ADD CONSTRAINT work_time_entries_category_fk FOREIGN KEY (category_definition_id) REFERENCES public.work_time_category_definitions(id) ON DELETE RESTRICT;


--
-- Name: workflow_phases workflow_phases_department_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_phases
    ADD CONSTRAINT workflow_phases_department_code_fkey FOREIGN KEY (department_code) REFERENCES public.departments(code) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: adjudications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.adjudications ENABLE ROW LEVEL SECURITY;

--
-- Name: adjudications adjudications_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY adjudications_select_all_auth ON public.adjudications FOR SELECT TO authenticated USING (true);


--
-- Name: adjudications adjudications_write_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY adjudications_write_all_auth ON public.adjudications TO authenticated USING (true) WITH CHECK (true);


--
-- Name: contacts allow_anon_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_insert ON public.contacts FOR INSERT TO anon WITH CHECK (true);


--
-- Name: customers allow_anon_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_insert ON public.customers FOR INSERT TO anon WITH CHECK (true);


--
-- Name: order_counters allow_anon_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_insert ON public.order_counters FOR INSERT TO anon WITH CHECK (true);


--
-- Name: orders allow_anon_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_insert ON public.orders FOR INSERT TO anon WITH CHECK (true);


--
-- Name: contacts allow_anon_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_select ON public.contacts FOR SELECT TO anon USING (true);


--
-- Name: customers allow_anon_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_select ON public.customers FOR SELECT TO anon USING (true);


--
-- Name: departments allow_anon_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_select ON public.departments FOR SELECT TO anon USING (true);


--
-- Name: order_counters allow_anon_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_select ON public.order_counters FOR SELECT TO anon USING (true);


--
-- Name: orders allow_anon_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_select ON public.orders FOR SELECT TO anon USING (true);


--
-- Name: profiles allow_anon_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_select ON public.profiles FOR SELECT TO anon USING (true);


--
-- Name: workflow_phases allow_anon_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_select ON public.workflow_phases FOR SELECT TO anon USING (true);


--
-- Name: order_counters allow_anon_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_update ON public.order_counters FOR UPDATE TO anon USING (true) WITH CHECK (true);


--
-- Name: profiles allow_anon_update_pin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_anon_update_pin ON public.profiles FOR UPDATE TO anon USING (true) WITH CHECK (true);


--
-- Name: budget_import_data; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.budget_import_data ENABLE ROW LEVEL SECURITY;

--
-- Name: budget_import_data budget_import_data_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY budget_import_data_select_all_auth ON public.budget_import_data FOR SELECT TO authenticated USING (true);


--
-- Name: budget_import_data budget_import_data_write_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY budget_import_data_write_all_auth ON public.budget_import_data TO authenticated USING (true) WITH CHECK (true);


--
-- Name: budget_supplier_requests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.budget_supplier_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: budget_supplier_requests budget_supplier_requests_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY budget_supplier_requests_select_all_auth ON public.budget_supplier_requests FOR SELECT TO authenticated USING (true);


--
-- Name: budget_supplier_requests budget_supplier_requests_write_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY budget_supplier_requests_write_all_auth ON public.budget_supplier_requests TO authenticated USING (true) WITH CHECK (true);


--
-- Name: budget_typologies; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.budget_typologies ENABLE ROW LEVEL SECURITY;

--
-- Name: budget_typologies budget_typologies_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY budget_typologies_select_all_auth ON public.budget_typologies FOR SELECT TO authenticated USING (true);


--
-- Name: contacts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

--
-- Name: contacts contacts_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY contacts_select_all_auth ON public.contacts FOR SELECT TO authenticated USING (true);


--
-- Name: countries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;

--
-- Name: countries countries_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY countries_select_all_auth ON public.countries FOR SELECT TO authenticated USING (true);


--
-- Name: customer_sites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.customer_sites ENABLE ROW LEVEL SECURITY;

--
-- Name: customer_sites customer_sites_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY customer_sites_select_all_auth ON public.customer_sites FOR SELECT TO authenticated USING (true);


--
-- Name: customer_sites customer_sites_write_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY customer_sites_write_all_auth ON public.customer_sites TO authenticated USING (true) WITH CHECK (true);


--
-- Name: customers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

--
-- Name: customers customers_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY customers_select_all_auth ON public.customers FOR SELECT TO authenticated USING (true);


--
-- Name: departments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

--
-- Name: order_budget_assignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.order_budget_assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: order_budget_assignments order_budget_assignments_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY order_budget_assignments_select_all_auth ON public.order_budget_assignments FOR SELECT TO authenticated USING (true);


--
-- Name: order_budget_assignments order_budget_assignments_write_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY order_budget_assignments_write_all_auth ON public.order_budget_assignments TO authenticated USING (true) WITH CHECK (true);


--
-- Name: order_counters; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.order_counters ENABLE ROW LEVEL SECURITY;

--
-- Name: order_phase_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.order_phase_history ENABLE ROW LEVEL SECURITY;

--
-- Name: order_status_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

--
-- Name: order_versions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.order_versions ENABLE ROW LEVEL SECURITY;

--
-- Name: order_versions order_versions_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY order_versions_select_all_auth ON public.order_versions FOR SELECT TO authenticated USING (true);


--
-- Name: orders; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

--
-- Name: orders orders_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY orders_select_all_auth ON public.orders FOR SELECT TO authenticated USING (true);


--
-- Name: product_attribute_definitions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_attribute_definitions ENABLE ROW LEVEL SECURITY;

--
-- Name: product_attribute_definitions product_attribute_definitions_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY product_attribute_definitions_select_all_auth ON public.product_attribute_definitions FOR SELECT TO authenticated USING (true);


--
-- Name: product_attribute_definitions product_attribute_definitions_write_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY product_attribute_definitions_write_all_auth ON public.product_attribute_definitions TO authenticated USING (true) WITH CHECK (true);


--
-- Name: product_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_types ENABLE ROW LEVEL SECURITY;

--
-- Name: product_types product_types_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY product_types_select_all_auth ON public.product_types FOR SELECT TO authenticated USING (true);


--
-- Name: profile_roles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profile_roles ENABLE ROW LEVEL SECURITY;

--
-- Name: profile_roles profile_roles_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_roles_select_all_auth ON public.profile_roles FOR SELECT TO authenticated USING (true);


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_select_all_auth ON public.profiles FOR SELECT TO authenticated USING (true);


--
-- Name: proposal_feedback_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.proposal_feedback_history ENABLE ROW LEVEL SECURITY;

--
-- Name: proposal_followups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.proposal_followups ENABLE ROW LEVEL SECURITY;

--
-- Name: proposal_followups proposal_followups_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY proposal_followups_select_all_auth ON public.proposal_followups FOR SELECT TO authenticated USING (true);


--
-- Name: proposal_followups proposal_followups_write_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY proposal_followups_write_all_auth ON public.proposal_followups TO authenticated USING (true) WITH CHECK (true);


--
-- Name: proposal_item_attribute_values; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.proposal_item_attribute_values ENABLE ROW LEVEL SECURITY;

--
-- Name: proposal_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.proposal_items ENABLE ROW LEVEL SECURITY;

--
-- Name: proposal_items proposal_items_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY proposal_items_select_all_auth ON public.proposal_items FOR SELECT TO authenticated USING (true);


--
-- Name: proposal_phase_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.proposal_phase_history ENABLE ROW LEVEL SECURITY;

--
-- Name: proposal_phases; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.proposal_phases ENABLE ROW LEVEL SECURITY;

--
-- Name: proposals; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.proposals ENABLE ROW LEVEL SECURITY;

--
-- Name: proposals proposals_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY proposals_select_all_auth ON public.proposals FOR SELECT TO authenticated USING (true);


--
-- Name: roles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

--
-- Name: roles roles_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY roles_select_all_auth ON public.roles FOR SELECT TO authenticated USING (true);


--
-- Name: suppliers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;

--
-- Name: suppliers suppliers_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY suppliers_select_all_auth ON public.suppliers FOR SELECT TO authenticated USING (true);


--
-- Name: suppliers suppliers_write_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY suppliers_write_all_auth ON public.suppliers TO authenticated USING (true) WITH CHECK (true);


--
-- Name: work_time_category_definitions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.work_time_category_definitions ENABLE ROW LEVEL SECURITY;

--
-- Name: work_time_category_definitions work_time_category_definitions_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY work_time_category_definitions_select_all_auth ON public.work_time_category_definitions FOR SELECT TO authenticated USING (true);


--
-- Name: work_time_entries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.work_time_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: workflow_phases; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workflow_phases ENABLE ROW LEVEL SECURITY;

--
-- Name: workflow_phases workflow_phases_select_all_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY workflow_phases_select_all_auth ON public.workflow_phases FOR SELECT TO authenticated USING (true);


--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: supabase_realtime_messages_publication; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime_messages_publication WITH (publish = 'insert, update, delete, truncate');


--
-- Name: supabase_realtime order_budget_assignments; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.order_budget_assignments;


--
-- Name: supabase_realtime order_versions; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.order_versions;


--
-- Name: supabase_realtime orders; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.orders;


--
-- Name: supabase_realtime proposals; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.proposals;


--
-- Name: ensure_rls; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER ensure_rls ON ddl_command_end
         WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
   EXECUTE FUNCTION public.rls_auto_enable();


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

\unrestrict bO7LH43NodjBNCxD2VsHV3knCBp5g4sb27VKiMenpU3Wa8QcmTLzg7FFlUTkeox


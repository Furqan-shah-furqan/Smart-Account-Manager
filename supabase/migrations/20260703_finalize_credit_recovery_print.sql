-- Final targeted DMS fixes:
-- 1. Keep Credit Sale available through Order Booking.
-- 2. Repair Recovery validation and persistence.
-- 3. Do not change investment, stock, load-form, or unrelated data flows.

begin;

alter table public.recoveries
  add column if not exists date date not null default current_date,
  add column if not exists cheque_bill_no text not null default '',
  add column if not exists dsr_id uuid,
  add column if not exists shopkeeper_id uuid,
  add column if not exists received_amount numeric(18,2) not null default 0,
  add column if not exists balance_after numeric(18,2) not null default 0,
  add column if not exists created_by uuid default auth.uid();

create index if not exists recoveries_company_dsr_date_idx
  on public.recoveries(company_id, dsr_id, date desc);

-- Keep the existing Order Booking flow but make the sale-type conversion
-- explicit for databases where public.sales.sale_type is an enum.
create or replace function public.book_sale_atomic(
  p_company_id uuid,
  p_bill_no text,
  p_dsr_id uuid,
  p_product_id uuid,
  p_quantity integer,
  p_price numeric,
  p_sale_type text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stock integer;
  v_cost numeric(18,2);
  v_sale_id uuid;
begin
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and company_id = p_company_id
  ) then
    raise exception 'You do not have access to this company';
  end if;

  if nullif(trim(p_bill_no), '') is null then
    raise exception 'Bill number is required';
  end if;
  if p_quantity <= 0 then
    raise exception 'Quantity must be greater than 0';
  end if;
  if p_price <= 0 then
    raise exception 'Price must be greater than 0';
  end if;
  if lower(trim(p_sale_type)) not in ('cash', 'credit') then
    raise exception 'Invalid sale type';
  end if;
  if not exists (
    select 1 from public.dsrs
    where id = p_dsr_id and company_id = p_company_id
  ) then
    raise exception 'Invalid DSR';
  end if;

  select warehouse_stock, purchase_price
    into v_stock, v_cost
  from public.products
  where id = p_product_id and company_id = p_company_id
  for update;

  if not found then
    raise exception 'Invalid product';
  end if;
  if v_stock < p_quantity then
    raise exception 'Not enough distributor stock';
  end if;

  update public.products
  set warehouse_stock = warehouse_stock - p_quantity,
      updated_at = now()
  where id = p_product_id and company_id = p_company_id;

  insert into public.sales (
    company_id, date, bill_no, dsr_id, shopkeeper_id, product_id,
    quantity, price, sale_type, purchase_cost, created_by, updated_at
  ) values (
    p_company_id, current_date, trim(p_bill_no), p_dsr_id, null, p_product_id,
    p_quantity, round(p_price, 2),
    lower(trim(p_sale_type))::public.sale_type,
    round(coalesce(v_cost, 0), 2), auth.uid(), now()
  ) returning id into v_sale_id;

  insert into public.stock_movements (
    company_id, product_id, dsr_id, movement_type,
    quantity, note, created_by
  ) values (
    p_company_id, p_product_id, p_dsr_id,
    case when lower(trim(p_sale_type)) = 'cash'
      then 'Cash Sale' else 'Credit Sale' end,
    -p_quantity,
    trim(p_bill_no) || ' • Deducted from warehouse stock',
    auth.uid()
  );

  return v_sale_id;
end;
$$;

revoke all on function public.book_sale_atomic(
  uuid, text, uuid, uuid, integer, numeric, text
) from public;
grant execute on function public.book_sale_atomic(
  uuid, text, uuid, uuid, integer, numeric, text
) to authenticated;

-- Recovery is calculated only against saved Credit Sales for the selected DSR.
create or replace function public.add_recovery_atomic(
  p_company_id uuid,
  p_cheque_bill_no text,
  p_dsr_id uuid,
  p_amount numeric
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_credit numeric(18,2) := 0;
  v_recovered numeric(18,2) := 0;
  v_pending numeric(18,2) := 0;
  v_recovery_id uuid;
begin
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and company_id = p_company_id
  ) then
    raise exception 'You do not have access to this company';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Recovery amount must be greater than 0';
  end if;
  if not exists (
    select 1 from public.dsrs
    where id = p_dsr_id and company_id = p_company_id
  ) then
    raise exception 'Invalid DSR';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(p_company_id::text || ':' || p_dsr_id::text, 0)
  );

  select coalesce(sum(quantity * price), 0)
    into v_credit
  from public.sales
  where company_id = p_company_id
    and dsr_id = p_dsr_id
    and lower(sale_type::text) = 'credit';

  select coalesce(sum(received_amount), 0)
    into v_recovered
  from public.recoveries
  where company_id = p_company_id
    and dsr_id = p_dsr_id;

  v_pending := round(greatest(v_credit - v_recovered, 0), 2);

  if v_pending <= 0 then
    raise exception 'No pending credit is available for this DSR';
  end if;
  if round(p_amount, 2) > v_pending then
    raise exception 'Recovery cannot be greater than pending credit';
  end if;

  insert into public.recoveries (
    company_id, date, cheque_bill_no, dsr_id, shopkeeper_id,
    received_amount, balance_after, created_by
  ) values (
    p_company_id, current_date,
    trim(coalesce(p_cheque_bill_no, '')),
    p_dsr_id, null,
    round(p_amount, 2),
    round(v_pending - p_amount, 2),
    auth.uid()
  ) returning id into v_recovery_id;

  return v_recovery_id;
end;
$$;

revoke all on function public.add_recovery_atomic(
  uuid, text, uuid, numeric
) from public;
grant execute on function public.add_recovery_atomic(
  uuid, text, uuid, numeric
) to authenticated;

commit;

notify pgrst, 'reload schema';

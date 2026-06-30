-- DMS calculation, persistence, reporting and Investment module upgrade.
-- Run once in Supabase SQL Editor before using the updated Flutter files.

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Shared columns and constraints
-- ---------------------------------------------------------------------------

alter table public.products
  add column if not exists updated_at timestamptz not null default now();

-- Existing databases may already contain duplicate SKUs inside one company.
-- Preserve every product row: keep one SKU unchanged and rename only additional
-- duplicates before enforcing the unique company/SKU index.
with ranked_duplicate_skus as (
  select
    id,
    row_number() over (
      partition by company_id, lower(sku)
      order by id
    ) as duplicate_number
  from public.products
  where nullif(trim(sku), '') is not null
)
update public.products as p
set sku = trim(p.sku) || '-DUP-' || left(p.id::text, 8)
from ranked_duplicate_skus as d
where p.id = d.id
  and d.duplicate_number > 1;

create unique index if not exists products_company_sku_unique
  on public.products (company_id, lower(sku))
  where nullif(trim(sku), '') is not null;

alter table public.company_purchases
  add column if not exists gross_bill numeric(18,2) not null default 0,
  add column if not exists company_discount_percent numeric(8,4) not null default 0,
  add column if not exists trade_discount_percent numeric(8,4) not null default 0,
  add column if not exists discount_total numeric(18,2) not null default 0,
  add column if not exists selling_price numeric(18,2) not null default 0,
  add column if not exists distributor_name text not null default '',
  add column if not exists manufacturer_name text not null default '',
  add column if not exists updated_at timestamptz not null default now();

alter table public.load_entries
  add column if not exists settlement_id uuid,
  add column if not exists load_cartons integer not null default 0,
  add column if not exists load_loose_boxes integer not null default 0,
  add column if not exists return_cartons integer not null default 0,
  add column if not exists return_loose_boxes integer not null default 0,
  add column if not exists return_quantity integer not null default 0,
  add column if not exists packets_per_carton integer not null default 1,
  add column if not exists selling_price numeric(18,2) not null default 0,
  add column if not exists company_discount_percent numeric(8,4) not null default 0,
  add column if not exists trade_offer_percent numeric(8,4) not null default 0,
  add column if not exists gross_amount numeric(18,2) not null default 0,
  add column if not exists return_amount numeric(18,2) not null default 0,
  add column if not exists discount_amount numeric(18,2) not null default 0,
  add column if not exists net_amount numeric(18,2) not null default 0,
  add column if not exists extra_amount numeric(18,2) not null default 0,
  add column if not exists physical_cash numeric(18,2) not null default 0,
  add column if not exists note text not null default '',
  add column if not exists updated_at timestamptz not null default now();

alter table public.sales
  add column if not exists purchase_cost numeric(18,2) not null default 0,
  add column if not exists updated_at timestamptz not null default now();

alter table public.deposits
  add column if not exists distributor_name text not null default '',
  add column if not exists payment_amount numeric(18,2) not null default 0,
  add column if not exists reference_no text not null default '',
  add column if not exists note text not null default '',
  add column if not exists updated_at timestamptz not null default now();

alter table public.claims
  add column if not exists stock_direction text not null default 'none',
  add column if not exists updated_at timestamptz not null default now();

alter table public.expenses
  add column if not exists updated_at timestamptz not null default now();

-- ---------------------------------------------------------------------------
-- Investment module
-- ---------------------------------------------------------------------------

create table if not exists public.investments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  date date not null default current_date,
  investor_name text not null,
  investment_type text not null,
  custom_investment_type text not null default '',
  payment_method text not null,
  custom_payment_method text not null default '',
  reference_no text not null default '',
  amount numeric(18,2) not null check (amount > 0),
  note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists investments_company_date_idx
  on public.investments(company_id, date desc);

alter table public.investments enable row level security;

drop policy if exists investments_company_select on public.investments;
create policy investments_company_select on public.investments
for select using (
  exists (
    select 1 from public.profiles p
    where p.user_id = auth.uid() and p.company_id = investments.company_id
  )
);

drop policy if exists investments_company_insert on public.investments;
create policy investments_company_insert on public.investments
for insert with check (
  created_by = auth.uid() and exists (
    select 1 from public.profiles p
    where p.user_id = auth.uid() and p.company_id = investments.company_id
  )
);

drop policy if exists investments_company_update on public.investments;
create policy investments_company_update on public.investments
for update using (
  exists (
    select 1 from public.profiles p
    where p.user_id = auth.uid() and p.company_id = investments.company_id
  )
) with check (
  exists (
    select 1 from public.profiles p
    where p.user_id = auth.uid() and p.company_id = investments.company_id
  )
);

drop policy if exists investments_company_delete on public.investments;
create policy investments_company_delete on public.investments
for delete using (
  exists (
    select 1 from public.profiles p
    where p.user_id = auth.uid() and p.company_id = investments.company_id
  )
);

grant select, insert, update, delete on public.investments to authenticated;

-- ---------------------------------------------------------------------------
-- Authorization helper used by all transaction RPCs
-- ---------------------------------------------------------------------------

create or replace function public.dms_assert_company(p_company_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'User not logged in';
  end if;

  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and company_id = p_company_id
  ) then
    raise exception 'You do not have access to this company';
  end if;
end;
$$;

revoke all on function public.dms_assert_company(uuid) from public;
grant execute on function public.dms_assert_company(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Atomic Primary Receiving
-- ---------------------------------------------------------------------------

create or replace function public.create_primary_receiving(
  p_company_id uuid,
  p_invoice_no text,
  p_distributor text,
  p_manufacturer text,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  item jsonb;
  v_product_id uuid;
  v_name text;
  v_sku text;
  v_brand text;
  v_cartons integer;
  v_pack integer;
  v_total_boxes integer;
  v_min_stock integer;
  v_purchase numeric(18,2);
  v_selling numeric(18,2);
  v_company_pct numeric(8,4);
  v_trade_pct numeric(8,4);
  v_gross numeric(18,2);
  v_discount numeric(18,2);
  v_net numeric(18,2);
  v_total_gross numeric(18,2) := 0;
  v_total_discount numeric(18,2) := 0;
  v_final_bill numeric(18,2) := 0;
  v_total_boxes_all integer := 0;
begin
  perform public.dms_assert_company(p_company_id);

  if nullif(trim(p_invoice_no), '') is null then
    raise exception 'Invoice number is required';
  end if;
  if nullif(trim(p_manufacturer), '') is null then
    raise exception 'Manufacturer / party is required';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'At least one product row is required';
  end if;

  for item in select value from jsonb_array_elements(p_items)
  loop
    v_name := trim(coalesce(item->>'name', ''));
    v_sku := trim(coalesce(item->>'sku', ''));
    v_brand := trim(coalesce(item->>'brand', ''));
    v_cartons := greatest(coalesce((item->>'cartons')::integer, 0), 0);
    v_pack := greatest(coalesce((item->>'packets_per_carton')::integer, 0), 0);
    v_min_stock := greatest(coalesce((item->>'minimum_stock')::integer, 0), 0);
    v_purchase := round(greatest(coalesce((item->>'purchase_price')::numeric, 0), 0), 2);
    v_selling := round(greatest(coalesce((item->>'selling_price')::numeric, 0), 0), 2);
    v_company_pct := least(greatest(coalesce((item->>'company_discount_percent')::numeric, 0), 0), 100);
    v_trade_pct := least(greatest(coalesce((item->>'trade_offer_percent')::numeric, 0), 0), 100);

    if v_name = '' then raise exception 'Product name is required'; end if;
    if v_sku = '' then raise exception 'SKU code is required for %', v_name; end if;
    if v_cartons <= 0 then raise exception 'Quantity CTN must be greater than 0 for %', v_name; end if;
    if v_pack <= 0 then raise exception 'Boxes per CTN must be greater than 0 for %', v_name; end if;
    if v_purchase <= 0 then raise exception 'Purchase price must be greater than 0 for %', v_name; end if;
    if v_selling <= 0 then raise exception 'Selling price must be greater than 0 for %', v_name; end if;

    v_total_boxes := v_cartons * v_pack;
    v_gross := round(v_total_boxes * v_purchase, 2);
    v_discount := round(v_gross * ((v_company_pct + v_trade_pct) / 100), 2);
    v_net := round(greatest(v_gross - v_discount, 0), 2);

    select id into v_product_id
    from public.products
    where company_id = p_company_id and lower(sku) = lower(v_sku)
    limit 1
    for update;

    if v_product_id is null then
      insert into public.products (
        company_id, name, sku, category, brand, batch_no, purchase_price,
        selling_price, warehouse_stock, low_stock_limit, packets_per_carton,
        company_discount, trade_discount, created_by, updated_at
      ) values (
        p_company_id, v_name, v_sku, 'Primary Receiving', v_brand, '',
        v_purchase, v_selling, v_total_boxes, v_min_stock, v_pack,
        v_company_pct, v_trade_pct, auth.uid(), now()
      ) returning id into v_product_id;
    else
      update public.products set
        name = v_name,
        brand = v_brand,
        purchase_price = v_purchase,
        selling_price = v_selling,
        warehouse_stock = warehouse_stock + v_total_boxes,
        low_stock_limit = v_min_stock,
        packets_per_carton = v_pack,
        company_discount = v_company_pct,
        trade_discount = v_trade_pct,
        updated_at = now()
      where id = v_product_id and company_id = p_company_id;
    end if;

    insert into public.company_purchases (
      company_id, date, invoice_no, company_name, product_id, batch_no,
      cartons, packets_per_carton, total_packets, packet_purchase_price,
      company_discount, total_bill, paid_amount, remaining_amount, note,
      gross_bill, company_discount_percent, trade_discount_percent,
      discount_total, selling_price, distributor_name, manufacturer_name,
      created_by, updated_at
    ) values (
      p_company_id, current_date, trim(p_invoice_no), trim(p_manufacturer),
      v_product_id, v_sku, v_cartons, v_pack, v_total_boxes, v_purchase,
      v_discount, v_net, 0, v_net, '', v_gross, v_company_pct, v_trade_pct,
      v_discount, v_selling, trim(coalesce(p_distributor, '')),
      trim(p_manufacturer), auth.uid(), now()
    );

    insert into public.stock_movements (
      company_id, product_id, movement_type, quantity, note, created_by
    ) values (
      p_company_id, v_product_id, 'Primary Receiving', v_total_boxes,
      trim(p_invoice_no) || ' • ' || trim(p_manufacturer), auth.uid()
    );

    v_total_gross := v_total_gross + v_gross;
    v_total_discount := v_total_discount + v_discount;
    v_final_bill := v_final_bill + v_net;
    v_total_boxes_all := v_total_boxes_all + v_total_boxes;
  end loop;

  return jsonb_build_object(
    'invoice_no', trim(p_invoice_no),
    'total_boxes', v_total_boxes_all,
    'gross_total', round(v_total_gross, 2),
    'discount_total', round(v_total_discount, 2),
    'final_bill', round(v_final_bill, 2)
  );
end;
$$;

revoke all on function public.create_primary_receiving(uuid,text,text,text,jsonb) from public;
grant execute on function public.create_primary_receiving(uuid,text,text,text,jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Atomic Secondary Order / load settlement
-- ---------------------------------------------------------------------------

create or replace function public.create_secondary_order(
  p_company_id uuid,
  p_dsr_id uuid,
  p_supplier_id uuid,
  p_extra_amount numeric,
  p_physical_cash numeric,
  p_note text,
  p_items jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  item jsonb;
  v_settlement_id uuid := gen_random_uuid();
  v_product_id uuid;
  v_pack integer;
  v_load_cartons integer;
  v_load_loose integer;
  v_return_cartons integer;
  v_return_loose integer;
  v_load_boxes integer;
  v_return_boxes integer;
  v_available integer;
  v_price numeric(18,2);
  v_company_pct numeric(8,4);
  v_trade_pct numeric(8,4);
  v_gross numeric(18,2);
  v_return_amount numeric(18,2);
  v_discount numeric(18,2);
  v_net numeric(18,2);
begin
  perform public.dms_assert_company(p_company_id);

  if not exists (select 1 from public.dsrs where id = p_dsr_id and company_id = p_company_id) then
    raise exception 'Invalid DSR';
  end if;
  if not exists (select 1 from public.suppliers where id = p_supplier_id and company_id = p_company_id) then
    raise exception 'Invalid salesman';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'At least one load product is required';
  end if;

  for item in select value from jsonb_array_elements(p_items)
  loop
    v_product_id := (item->>'product_id')::uuid;
    v_pack := greatest(coalesce((item->>'packets_per_carton')::integer, 0), 0);
    v_load_cartons := greatest(coalesce((item->>'load_cartons')::integer, 0), 0);
    v_load_loose := greatest(coalesce((item->>'load_loose_boxes')::integer, 0), 0);
    v_return_cartons := greatest(coalesce((item->>'return_cartons')::integer, 0), 0);
    v_return_loose := greatest(coalesce((item->>'return_loose_boxes')::integer, 0), 0);
    v_price := round(greatest(coalesce((item->>'selling_price')::numeric, 0), 0), 2);
    v_company_pct := least(greatest(coalesce((item->>'company_discount_percent')::numeric, 0), 0), 100);
    v_trade_pct := least(greatest(coalesce((item->>'trade_offer_percent')::numeric, 0), 0), 100);

    if v_pack <= 0 then raise exception 'Boxes per CTN must be greater than 0'; end if;
    if v_price <= 0 then raise exception 'Selling price must be greater than 0'; end if;

    v_load_boxes := v_load_cartons * v_pack + v_load_loose;
    v_return_boxes := v_return_cartons * v_pack + v_return_loose;
    if v_load_boxes <= 0 and v_return_boxes <= 0 then
      raise exception 'Load or return quantity must be greater than 0';
    end if;

    select warehouse_stock into v_available
    from public.products
    where id = v_product_id and company_id = p_company_id;
    if not found then raise exception 'Invalid product'; end if;
    if v_load_boxes > v_available then raise exception 'Not enough distributor stock'; end if;

    v_gross := round(v_load_boxes * v_price, 2);
    v_return_amount := round(v_return_boxes * v_price, 2);
    v_discount := round(v_gross * ((v_company_pct + v_trade_pct) / 100), 2);
    v_net := round(greatest(v_gross - v_return_amount - v_discount, 0), 2);

    insert into public.load_entries (
      company_id, date, dsr_id, supplier_id, product_id, quantity,
      settlement_id, load_cartons, load_loose_boxes, return_cartons,
      return_loose_boxes, return_quantity, packets_per_carton, selling_price,
      company_discount_percent, trade_offer_percent, gross_amount,
      return_amount, discount_amount, net_amount, extra_amount, physical_cash,
      note, created_by, updated_at
    ) values (
      p_company_id, current_date, p_dsr_id, p_supplier_id, v_product_id,
      v_load_boxes, v_settlement_id, v_load_cartons, v_load_loose,
      v_return_cartons, v_return_loose, v_return_boxes, v_pack, v_price,
      v_company_pct, v_trade_pct, v_gross, v_return_amount, v_discount, v_net,
      greatest(coalesce(p_extra_amount, 0), 0), greatest(coalesce(p_physical_cash, 0), 0),
      trim(coalesce(p_note, '')), auth.uid(), now()
    );

    insert into public.stock_movements (
      company_id, product_id, dsr_id, movement_type, quantity, note, created_by
    ) values (
      p_company_id, v_product_id, p_dsr_id, 'Load Form Created', v_load_boxes,
      'Secondary order allocation only; warehouse stock unchanged.', auth.uid()
    );
  end loop;

  return v_settlement_id;
end;
$$;

revoke all on function public.create_secondary_order(uuid,uuid,uuid,numeric,numeric,text,jsonb) from public;
grant execute on function public.create_secondary_order(uuid,uuid,uuid,numeric,numeric,text,jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Atomic sale with stock validation and cost snapshot
-- ---------------------------------------------------------------------------

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
  perform public.dms_assert_company(p_company_id);

  if nullif(trim(p_bill_no), '') is null then raise exception 'Bill number is required'; end if;
  if p_quantity <= 0 then raise exception 'Quantity must be greater than 0'; end if;
  if p_price <= 0 then raise exception 'Price must be greater than 0'; end if;
  if lower(p_sale_type) not in ('cash', 'credit') then raise exception 'Invalid sale type'; end if;
  if not exists (
    select 1 from public.dsrs where id = p_dsr_id and company_id = p_company_id
  ) then
    raise exception 'Invalid DSR';
  end if;

  select warehouse_stock, purchase_price into v_stock, v_cost
  from public.products
  where id = p_product_id and company_id = p_company_id
  for update;

  if not found then raise exception 'Invalid product'; end if;
  if v_stock < p_quantity then raise exception 'Not enough distributor stock'; end if;

  update public.products set
    warehouse_stock = warehouse_stock - p_quantity,
    updated_at = now()
  where id = p_product_id and company_id = p_company_id;

  insert into public.sales (
    company_id, date, bill_no, dsr_id, shopkeeper_id, product_id,
    quantity, price, sale_type, purchase_cost, created_by, updated_at
  ) values (
    p_company_id, current_date, trim(p_bill_no), p_dsr_id, null, p_product_id,
    p_quantity, round(p_price,2), lower(p_sale_type), round(v_cost,2), auth.uid(), now()
  ) returning id into v_sale_id;

  insert into public.stock_movements (
    company_id, product_id, dsr_id, movement_type, quantity, note, created_by
  ) values (
    p_company_id, p_product_id, p_dsr_id,
    case when lower(p_sale_type) = 'cash' then 'Cash Sale' else 'Credit Sale' end,
    -p_quantity, trim(p_bill_no) || ' • Deducted from warehouse stock', auth.uid()
  );

  return v_sale_id;
end;
$$;

revoke all on function public.book_sale_atomic(uuid,text,uuid,uuid,integer,numeric,text) from public;
grant execute on function public.book_sale_atomic(uuid,text,uuid,uuid,integer,numeric,text) to authenticated;

-- ---------------------------------------------------------------------------
-- Atomic recovery with pending-credit validation
-- ---------------------------------------------------------------------------

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
  v_credit numeric(18,2);
  v_recovered numeric(18,2);
  v_pending numeric(18,2);
  v_recovery_id uuid;
begin
  perform public.dms_assert_company(p_company_id);
  if p_amount <= 0 then raise exception 'Amount must be greater than 0'; end if;
  if not exists (
    select 1 from public.dsrs where id = p_dsr_id and company_id = p_company_id
  ) then
    raise exception 'Invalid DSR';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(p_company_id::text || ':' || p_dsr_id::text, 0)
  );

  select coalesce(sum(quantity * price), 0) into v_credit
  from public.sales
  where company_id = p_company_id
    and dsr_id = p_dsr_id
    and sale_type = 'credit';

  select coalesce(sum(received_amount), 0) into v_recovered
  from public.recoveries
  where company_id = p_company_id and dsr_id = p_dsr_id;

  v_pending := round(greatest(v_credit - v_recovered, 0), 2);
  if p_amount > v_pending then
    raise exception 'Recovery is greater than pending credit';
  end if;

  insert into public.recoveries (
    company_id, date, cheque_bill_no, dsr_id, shopkeeper_id,
    received_amount, balance_after, created_by
  ) values (
    p_company_id, current_date, trim(coalesce(p_cheque_bill_no, '')),
    p_dsr_id, null, round(p_amount, 2), round(v_pending - p_amount, 2),
    auth.uid()
  ) returning id into v_recovery_id;

  return v_recovery_id;
end;
$$;

revoke all on function public.add_recovery_atomic(uuid,text,uuid,numeric) from public;
grant execute on function public.add_recovery_atomic(uuid,text,uuid,numeric) to authenticated;

-- ---------------------------------------------------------------------------
-- Atomic FIFO Deposit payment
-- ---------------------------------------------------------------------------

create or replace function public.pay_primary_invoices(
  p_company_id uuid,
  p_purchase_ids uuid[],
  p_distributor text,
  p_party text,
  p_amount numeric,
  p_reference_no text default ''
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  row_item record;
  v_pending numeric(18,2);
  v_remaining numeric(18,2);
  v_apply numeric(18,2);
begin
  perform public.dms_assert_company(p_company_id);

  if p_amount <= 0 then raise exception 'Amount must be greater than 0'; end if;

  select coalesce(sum(remaining_amount),0) into v_pending
  from public.company_purchases
  where company_id = p_company_id
    and id = any(p_purchase_ids)
    and remaining_amount > 0;

  if p_amount > v_pending then
    raise exception 'Amount cannot be greater than pending total';
  end if;

  v_remaining := round(p_amount, 2);

  for row_item in
    select id, paid_amount, remaining_amount
    from public.company_purchases
    where company_id = p_company_id
      and id = any(p_purchase_ids)
      and remaining_amount > 0
    order by date asc, created_at asc, id asc
    for update
  loop
    exit when v_remaining <= 0;
    v_apply := least(v_remaining, row_item.remaining_amount);

    update public.company_purchases set
      paid_amount = round(row_item.paid_amount + v_apply, 2),
      remaining_amount = round(row_item.remaining_amount - v_apply, 2),
      updated_at = now()
    where id = row_item.id and company_id = p_company_id;

    v_remaining := round(v_remaining - v_apply, 2);
  end loop;

  insert into public.deposits (
    company_id, date, party, note_5000, note_1000, note_500, note_100,
    note_50, note_20, note_10, coins, distributor_name, payment_amount,
    reference_no, note, created_by, updated_at
  ) values (
    p_company_id, current_date, trim(coalesce(p_party, 'Company Payment')),
    0,0,0,0,0,0,0, round(p_amount,2), trim(coalesce(p_distributor,'')),
    round(p_amount,2), trim(coalesce(p_reference_no,'')),
    'FIFO payment against Primary Receiving invoices', auth.uid(), now()
  );

  return round(v_pending - p_amount, 2);
end;
$$;

revoke all on function public.pay_primary_invoices(uuid,uuid[],text,text,numeric,text) from public;
grant execute on function public.pay_primary_invoices(uuid,uuid[],text,text,numeric,text) to authenticated;

-- ---------------------------------------------------------------------------
-- Atomic claim / expiry stock handling
-- ---------------------------------------------------------------------------

create or replace function public.add_claim_atomic(
  p_company_id uuid,
  p_product_id uuid,
  p_type text,
  p_quantity integer,
  p_amount numeric,
  p_note text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stock integer;
  v_direction text := 'none';
  v_claim_id uuid;
begin
  perform public.dms_assert_company(p_company_id);
  if p_quantity <= 0 then raise exception 'Quantity must be greater than 0'; end if;
  if p_amount < 0 then raise exception 'Amount cannot be negative'; end if;
  if p_type not in ('Expiry','Claim','Damage','Return Stock') then raise exception 'Invalid claim type'; end if;

  select warehouse_stock into v_stock
  from public.products
  where id = p_product_id and company_id = p_company_id
  for update;
  if not found then raise exception 'Invalid product'; end if;

  if p_type in ('Expiry','Damage') then
    if p_quantity > v_stock then raise exception 'Claim quantity cannot exceed current stock'; end if;
    update public.products set warehouse_stock = warehouse_stock - p_quantity, updated_at = now()
    where id = p_product_id and company_id = p_company_id;
    v_direction := 'out';
  elsif p_type = 'Return Stock' then
    update public.products set warehouse_stock = warehouse_stock + p_quantity, updated_at = now()
    where id = p_product_id and company_id = p_company_id;
    v_direction := 'in';
  end if;

  insert into public.claims (
    company_id, date, product_id, type, quantity, amount, note,
    stock_direction, created_by, updated_at
  ) values (
    p_company_id, current_date, p_product_id, p_type, p_quantity,
    round(greatest(p_amount,0),2), trim(coalesce(p_note,'')), v_direction,
    auth.uid(), now()
  ) returning id into v_claim_id;

  if v_direction <> 'none' then
    insert into public.stock_movements (
      company_id, product_id, movement_type, quantity, note, created_by
    ) values (
      p_company_id, p_product_id, p_type,
      case when v_direction = 'in' then p_quantity else -p_quantity end,
      trim(coalesce(p_note,'')), auth.uid()
    );
  end if;

  return v_claim_id;
end;
$$;

revoke all on function public.add_claim_atomic(uuid,uuid,text,integer,numeric,text) from public;
grant execute on function public.add_claim_atomic(uuid,uuid,text,integer,numeric,text) to authenticated;

commit;

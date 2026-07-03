-- Targeted DMS fix:
-- 1) Trade Offer is an amount per box, not a percentage.
-- 2) Load Form Settlement generation is made compatible with enum-backed sales
--    and existing stock-movement values.
-- 3) No existing tables, records, or unrelated flows are removed.

begin;

-- Required columns are added safely for databases that missed an earlier patch.
alter table public.load_entries
  add column if not exists generated_at timestamptz,
  add column if not exists generated_by uuid,
  add column if not exists updated_at timestamptz not null default now();

alter table public.sales
  add column if not exists source_type text not null default 'manual',
  add column if not exists load_settlement_id uuid,
  add column if not exists load_entry_id uuid,
  add column if not exists load_form_amount numeric(18,2) not null default 0,
  add column if not exists purchase_cost numeric(18,2) not null default 0,
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists sales_company_load_entry_unique
  on public.sales(company_id, load_entry_id)
  where load_entry_id is not null;

create index if not exists load_entries_company_dsr_date_generated_idx
  on public.load_entries(company_id, dsr_id, date, generated_at);

-- ---------------------------------------------------------------------------
-- Primary Receiving: Trade Offer = Rs per box
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
  v_trade_per_box numeric(18,2);
  v_company_discount numeric(18,2);
  v_trade_offer_amount numeric(18,2);
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
    v_company_pct := least(
      greatest(coalesce((item->>'company_discount_percent')::numeric, 0), 0),
      100
    );
    v_trade_per_box := round(greatest(coalesce(
      nullif(item->>'trade_offer_per_box', '')::numeric,
      nullif(item->>'trade_offer_percent', '')::numeric,
      0
    ), 0), 2);

    if v_name = '' then raise exception 'Product name is required'; end if;
    if v_sku = '' then raise exception 'SKU code is required for %', v_name; end if;
    if v_cartons <= 0 then raise exception 'Quantity CTN must be greater than 0 for %', v_name; end if;
    if v_pack <= 0 then raise exception 'Boxes per CTN must be greater than 0 for %', v_name; end if;
    if v_purchase <= 0 then raise exception 'Purchase price must be greater than 0 for %', v_name; end if;
    if v_selling <= 0 then raise exception 'Selling price must be greater than 0 for %', v_name; end if;

    v_total_boxes := v_cartons * v_pack;
    v_gross := round(v_total_boxes * v_purchase, 2);
    v_company_discount := round(v_gross * (v_company_pct / 100), 2);
    v_trade_offer_amount := round(v_total_boxes * v_trade_per_box, 2);
    v_discount := round(v_company_discount + v_trade_offer_amount, 2);
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
        v_company_pct, v_trade_per_box, auth.uid(), now()
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
        trade_discount = v_trade_per_box,
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
      v_discount, v_net, 0, v_net, '', v_gross, v_company_pct,
      v_trade_per_box, v_discount, v_selling,
      trim(coalesce(p_distributor, '')), trim(p_manufacturer), auth.uid(), now()
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
-- Secondary Order: Trade Offer = Rs per loaded box
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
  v_trade_per_box numeric(18,2);
  v_company_discount numeric(18,2);
  v_trade_offer_amount numeric(18,2);
  v_gross numeric(18,2);
  v_return_amount numeric(18,2);
  v_discount numeric(18,2);
  v_net numeric(18,2);
begin
  perform public.dms_assert_company(p_company_id);

  if not exists (
    select 1 from public.dsrs
    where id = p_dsr_id and company_id = p_company_id
  ) then
    raise exception 'Invalid DSR';
  end if;
  if not exists (
    select 1 from public.suppliers
    where id = p_supplier_id and company_id = p_company_id
  ) then
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
    v_company_pct := least(
      greatest(coalesce((item->>'company_discount_percent')::numeric, 0), 0),
      100
    );
    v_trade_per_box := round(greatest(coalesce(
      nullif(item->>'trade_offer_per_box', '')::numeric,
      nullif(item->>'trade_offer_percent', '')::numeric,
      0
    ), 0), 2);

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
    v_company_discount := round(v_gross * (v_company_pct / 100), 2);
    v_trade_offer_amount := round(v_load_boxes * v_trade_per_box, 2);
    v_discount := round(v_company_discount + v_trade_offer_amount, 2);
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
      v_company_pct, v_trade_per_box, v_gross, v_return_amount, v_discount,
      v_net, greatest(coalesce(p_extra_amount, 0), 0),
      greatest(coalesce(p_physical_cash, 0), 0),
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
-- Generate Load Form Settlement safely
-- ---------------------------------------------------------------------------
create or replace function public.generate_load_form_sales(
  p_company_id uuid,
  p_dsr_id uuid,
  p_date date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  load_row record;
  v_stock integer;
  v_purchase_cost numeric(18,2);
  v_product_selling numeric(18,2);
  v_price numeric(18,2);
  v_gross numeric(18,2);
  v_return_amount numeric(18,2);
  v_company_discount numeric(18,2);
  v_trade_offer_amount numeric(18,2);
  v_discount numeric(18,2);
  v_net numeric(18,2);
  v_loaded_sale_quantity integer;
  v_existing_quantity_total integer;
  v_existing_amount_total numeric(18,2);
  v_existing_quantity_used integer;
  v_existing_amount_used numeric(18,2);
  v_existing_quantity_remaining integer;
  v_existing_amount_remaining numeric(18,2);
  v_existing_quantity_for_row integer;
  v_existing_amount_for_row numeric(18,2);
  v_cash_quantity integer;
  v_cash_amount numeric(18,2);
  v_bill_no text;
  v_settlement_key uuid;
  v_applied_extra numeric(18,2);
  v_seen_settlements uuid[] := array[]::uuid[];
  v_allocated_quantity jsonb := '{}'::jsonb;
  v_allocated_amount jsonb := '{}'::jsonb;
  v_product_key text;
  v_row_number integer := 0;
  v_sales_count integer := 0;
  v_total_quantity integer := 0;
  v_total_amount numeric(18,2) := 0;
begin
  perform public.dms_assert_company(p_company_id);

  if p_dsr_id is null then raise exception 'Select DSR first'; end if;
  if p_date is null then raise exception 'Select load form date first'; end if;

  if not exists (
    select 1 from public.dsrs
    where id = p_dsr_id and company_id = p_company_id
  ) then
    raise exception 'Invalid DSR';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      p_company_id::text || ':' || p_dsr_id::text || ':' || p_date::text,
      0
    )
  );

  if not exists (
    select 1 from public.load_entries
    where company_id = p_company_id
      and dsr_id = p_dsr_id
      and date = p_date
  ) then
    raise exception 'No Secondary Order load found for the selected DSR and date';
  end if;

  if not exists (
    select 1 from public.load_entries
    where company_id = p_company_id
      and dsr_id = p_dsr_id
      and date = p_date
      and generated_at is null
  ) then
    raise exception 'This load form has already been generated';
  end if;

  for load_row in
    select le.*
    from public.load_entries le
    where le.company_id = p_company_id
      and le.dsr_id = p_dsr_id
      and le.date = p_date
      and le.generated_at is null
    order by le.created_at, le.id
    for update
  loop
    v_row_number := v_row_number + 1;
    v_settlement_key := coalesce(load_row.settlement_id, load_row.id);
    v_product_key := load_row.product_id::text;

    if not (v_settlement_key = any(v_seen_settlements)) then
      v_seen_settlements := array_append(v_seen_settlements, v_settlement_key);
      v_applied_extra := greatest(coalesce(load_row.extra_amount, 0), 0);
    else
      v_applied_extra := 0;
    end if;

    select warehouse_stock, purchase_price, selling_price
    into v_stock, v_purchase_cost, v_product_selling
    from public.products
    where id = load_row.product_id and company_id = p_company_id
    for update;

    if not found then
      raise exception 'A product in this load form no longer exists';
    end if;

    v_price := round(greatest(
      case
        when coalesce(load_row.selling_price, 0) > 0
          then load_row.selling_price
        else coalesce(v_product_selling, 0)
      end,
      0
    ), 2);

    if v_price <= 0 then
      raise exception 'Selling price must be greater than 0';
    end if;

    v_loaded_sale_quantity := greatest(
      coalesce(load_row.quantity, 0) - coalesce(load_row.return_quantity, 0),
      0
    );

    v_gross := round(
      case
        when coalesce(load_row.gross_amount, 0) > 0 then load_row.gross_amount
        else coalesce(load_row.quantity, 0) * v_price
      end,
      2
    );

    v_return_amount := round(
      case
        when coalesce(load_row.return_amount, 0) > 0 then load_row.return_amount
        else coalesce(load_row.return_quantity, 0) * v_price
      end,
      2
    );

    v_company_discount := round(
      v_gross * greatest(coalesce(load_row.company_discount_percent, 0), 0) / 100,
      2
    );
    v_trade_offer_amount := round(
      coalesce(load_row.quantity, 0) *
        greatest(coalesce(load_row.trade_offer_percent, 0), 0),
      2
    );
    v_discount := round(
      case
        when coalesce(load_row.discount_amount, 0) > 0
          then load_row.discount_amount
        else v_company_discount + v_trade_offer_amount
      end,
      2
    );

    v_net := round(
      case
        when coalesce(load_row.net_amount, 0) > 0 then load_row.net_amount
        else greatest(v_gross - v_return_amount - v_discount, 0)
      end,
      2
    );

    -- Orders already booked for the same DSR/date/product have already reduced
    -- stock. Allocate them against the Secondary Order so generation creates
    -- only the remaining Cash Sale instead of selling/deducting stock twice.
    select
      coalesce(sum(s.quantity), 0)::integer,
      round(coalesce(sum(
        case
          when coalesce(s.load_form_amount, 0) > 0 then s.load_form_amount
          when coalesce(s.total, 0) > 0 then s.total
          else s.quantity * s.price
        end
      ), 0), 2)
    into v_existing_quantity_total, v_existing_amount_total
    from public.sales s
    where s.company_id = p_company_id
      and s.dsr_id = p_dsr_id
      and s.date = p_date
      and s.product_id = load_row.product_id
      and coalesce(s.source_type, 'manual') <> 'load_form';

    v_existing_quantity_used := coalesce(
      nullif(v_allocated_quantity ->> v_product_key, '')::integer,
      0
    );
    v_existing_amount_used := coalesce(
      nullif(v_allocated_amount ->> v_product_key, '')::numeric,
      0
    );

    v_existing_quantity_remaining := greatest(
      v_existing_quantity_total - v_existing_quantity_used,
      0
    );
    v_existing_amount_remaining := greatest(
      v_existing_amount_total - v_existing_amount_used,
      0
    );

    v_existing_quantity_for_row := least(
      v_loaded_sale_quantity,
      v_existing_quantity_remaining
    );

    if v_existing_quantity_remaining > 0 and v_existing_quantity_for_row > 0 then
      v_existing_amount_for_row := round(least(
        v_net,
        v_existing_amount_remaining *
          v_existing_quantity_for_row / v_existing_quantity_remaining
      ), 2);
    else
      v_existing_amount_for_row := 0;
    end if;

    v_allocated_quantity := jsonb_set(
      v_allocated_quantity,
      array[v_product_key],
      to_jsonb(v_existing_quantity_used + v_existing_quantity_for_row),
      true
    );
    v_allocated_amount := jsonb_set(
      v_allocated_amount,
      array[v_product_key],
      to_jsonb(v_existing_amount_used + v_existing_amount_for_row),
      true
    );

    v_cash_quantity := greatest(
      v_loaded_sale_quantity - v_existing_quantity_for_row,
      0
    );
    v_cash_amount := round(greatest(
      v_net - v_existing_amount_for_row + v_applied_extra,
      0
    ), 2);

    if v_cash_quantity > 0 and v_cash_amount > 0 then
      if v_stock < v_cash_quantity then
        raise exception 'Not enough distributor stock. Available: %, required: %',
          v_stock, v_cash_quantity;
      end if;

      update public.products
      set warehouse_stock = warehouse_stock - v_cash_quantity,
          updated_at = now()
      where id = load_row.product_id and company_id = p_company_id;

      v_bill_no :=
        'LF-' || to_char(p_date, 'YYYYMMDD') || '-' ||
        left(replace(v_settlement_key::text, '-', ''), 8) || '-' ||
        lpad(v_row_number::text, 2, '0');

      insert into public.sales (
        company_id, date, bill_no, dsr_id, shopkeeper_id, product_id,
        quantity, price, sale_type, purchase_cost, source_type,
        load_settlement_id, load_entry_id, load_form_amount,
        created_by, updated_at
      ) values (
        p_company_id, p_date, v_bill_no, p_dsr_id, null,
        load_row.product_id, v_cash_quantity, v_price,
        'cash'::public.sale_type, round(coalesce(v_purchase_cost, 0), 2),
        'load_form', load_row.settlement_id, load_row.id, v_cash_amount,
        auth.uid(), now()
      );

      insert into public.stock_movements (
        company_id, product_id, dsr_id, movement_type, quantity, note, created_by
      ) values (
        p_company_id, load_row.product_id, p_dsr_id, 'Cash Sale',
        -v_cash_quantity,
        v_bill_no || ' • Generated from Secondary Order load form',
        auth.uid()
      );

      v_sales_count := v_sales_count + 1;
      v_total_quantity := v_total_quantity + v_cash_quantity;
      v_total_amount := v_total_amount + v_cash_amount;
    end if;

    update public.load_entries
    set selling_price = v_price,
        gross_amount = v_gross,
        return_amount = v_return_amount,
        discount_amount = v_discount,
        net_amount = v_net,
        generated_at = now(),
        generated_by = auth.uid(),
        updated_at = now()
    where id = load_row.id and company_id = p_company_id;
  end loop;

  return jsonb_build_object(
    'sales_count', v_sales_count,
    'total_quantity', v_total_quantity,
    'total_amount', round(v_total_amount, 2)
  );
end;
$$;

revoke all on function public.generate_load_form_sales(uuid, uuid, date) from public;
grant execute on function public.generate_load_form_sales(uuid, uuid, date) to authenticated;

create or replace function public.generate_load_form_settlement(
  p_company_id uuid,
  p_dsr_id uuid,
  p_date date,
  p_physical_cash numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
  v_physical_cash numeric(18,2) :=
    round(greatest(coalesce(p_physical_cash, 0), 0), 2);
  v_cash_row_id uuid;
begin
  perform public.dms_assert_company(p_company_id);

  v_result := public.generate_load_form_sales(
    p_company_id,
    p_dsr_id,
    p_date
  );

  update public.load_entries
  set physical_cash = 0,
      updated_at = now()
  where company_id = p_company_id
    and dsr_id = p_dsr_id
    and date = p_date;

  select id into v_cash_row_id
  from public.load_entries
  where company_id = p_company_id
    and dsr_id = p_dsr_id
    and date = p_date
  order by created_at, id
  limit 1;

  if v_cash_row_id is not null then
    update public.load_entries
    set physical_cash = v_physical_cash,
        updated_at = now()
    where id = v_cash_row_id and company_id = p_company_id;
  end if;

  return coalesce(v_result, '{}'::jsonb) || jsonb_build_object(
    'physical_cash', v_physical_cash
  );
end;
$$;

revoke all on function public.generate_load_form_settlement(uuid, uuid, date, numeric)
  from public;
grant execute on function public.generate_load_form_settlement(uuid, uuid, date, numeric)
  to authenticated;

commit;

notify pgrst, 'reload schema';

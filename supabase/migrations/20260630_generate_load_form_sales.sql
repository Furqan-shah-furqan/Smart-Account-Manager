-- Generate Load Form -> Cash Sales conversion.
-- Run this migration after the existing DMS calculation/investment migration.

begin;

alter table public.load_entries
  add column if not exists generated_at timestamptz,
  add column if not exists generated_by uuid;

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
  v_discount numeric(18,2);
  v_net numeric(18,2);
  v_sale_amount numeric(18,2);
  v_sale_quantity integer;
  v_bill_no text;
  v_settlement_key uuid;
  v_applied_extra numeric(18,2);
  v_seen_settlements uuid[] := array[]::uuid[];
  v_row_number integer := 0;
  v_sales_count integer := 0;
  v_total_quantity integer := 0;
  v_total_amount numeric(18,2) := 0;
begin
  perform public.dms_assert_company(p_company_id);

  if p_dsr_id is null then
    raise exception 'Select DSR first';
  end if;

  if p_date is null then
    raise exception 'Select load form date first';
  end if;

  if not exists (
    select 1
    from public.dsrs
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
    select 1
    from public.load_entries
    where company_id = p_company_id
      and dsr_id = p_dsr_id
      and date = p_date
  ) then
    raise exception 'No Secondary Order load found for the selected DSR and date';
  end if;

  if not exists (
    select 1
    from public.load_entries
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
    if not (v_settlement_key = any(v_seen_settlements)) then
      v_seen_settlements := array_append(v_seen_settlements, v_settlement_key);
      v_applied_extra := greatest(coalesce(load_row.extra_amount, 0), 0);
    else
      v_applied_extra := 0;
    end if;

    select
      warehouse_stock,
      purchase_price,
      selling_price
    into
      v_stock,
      v_purchase_cost,
      v_product_selling
    from public.products
    where id = load_row.product_id
      and company_id = p_company_id
    for update;

    if not found then
      raise exception 'Product linked with load entry % was not found', load_row.id;
    end if;

    v_price := round(
      greatest(
        case
          when coalesce(load_row.selling_price, 0) > 0
          then load_row.selling_price
          else coalesce(v_product_selling, 0)
        end,
        0
      ),
      2
    );

    if v_price <= 0 then
      raise exception 'Selling price must be greater than 0 for product %',
        load_row.product_id;
    end if;

    v_sale_quantity := greatest(
      coalesce(load_row.quantity, 0) - coalesce(load_row.return_quantity, 0),
      0
    );

    v_gross := round(
      case
        when coalesce(load_row.gross_amount, 0) > 0
        then load_row.gross_amount
        else coalesce(load_row.quantity, 0) * v_price
      end,
      2
    );

    v_return_amount := round(
      case
        when coalesce(load_row.return_amount, 0) > 0
        then load_row.return_amount
        else coalesce(load_row.return_quantity, 0) * v_price
      end,
      2
    );

    v_discount := round(
      case
        when coalesce(load_row.discount_amount, 0) > 0
        then load_row.discount_amount
        else v_gross * (
          greatest(coalesce(load_row.company_discount_percent, 0), 0) +
          greatest(coalesce(load_row.trade_offer_percent, 0), 0)
        ) / 100
      end,
      2
    );

    v_net := round(
      case
        when coalesce(load_row.net_amount, 0) > 0
        then load_row.net_amount
        else greatest(v_gross - v_return_amount - v_discount, 0)
      end,
      2
    );

    v_sale_amount := round(
      greatest(v_net + v_applied_extra, 0),
      2
    );

    if v_sale_quantity > 0 and v_sale_amount > 0 then
      if v_stock < v_sale_quantity then
        raise exception
          'Not enough distributor stock for product %. Available: %, required: %',
          load_row.product_id,
          v_stock,
          v_sale_quantity;
      end if;

      update public.products
      set
        warehouse_stock = warehouse_stock - v_sale_quantity,
        updated_at = now()
      where id = load_row.product_id
        and company_id = p_company_id;

      v_bill_no :=
        'LF-' || to_char(p_date, 'YYYYMMDD') || '-' ||
        left(
          replace(coalesce(load_row.settlement_id, load_row.id)::text, '-', ''),
          8
        ) || '-' || lpad(v_row_number::text, 2, '0');

      insert into public.sales (
        company_id,
        date,
        bill_no,
        dsr_id,
        shopkeeper_id,
        product_id,
        quantity,
        price,
        sale_type,
        purchase_cost,
        source_type,
        load_settlement_id,
        load_entry_id,
        load_form_amount,
        created_by,
        updated_at
      ) values (
        p_company_id,
        p_date,
        v_bill_no,
        p_dsr_id,
        null,
        load_row.product_id,
        v_sale_quantity,
        v_price,
        'cash',
        round(coalesce(v_purchase_cost, 0), 2),
        'load_form',
        load_row.settlement_id,
        load_row.id,
        v_sale_amount,
        auth.uid(),
        now()
      );

      insert into public.stock_movements (
        company_id,
        product_id,
        dsr_id,
        movement_type,
        quantity,
        note,
        created_by
      ) values (
        p_company_id,
        load_row.product_id,
        p_dsr_id,
        'Generated Load Form Sale',
        -v_sale_quantity,
        v_bill_no || ' • Generated from Secondary Order load form',
        auth.uid()
      );

      v_sales_count := v_sales_count + 1;
      v_total_quantity := v_total_quantity + v_sale_quantity;
      v_total_amount := v_total_amount + v_sale_amount;
    end if;

    update public.load_entries
    set
      selling_price = v_price,
      gross_amount = v_gross,
      return_amount = v_return_amount,
      discount_amount = v_discount,
      net_amount = v_net,
      generated_at = now(),
      generated_by = auth.uid(),
      updated_at = now()
    where id = load_row.id
      and company_id = p_company_id;
  end loop;

  return jsonb_build_object(
    'sales_count', v_sales_count,
    'total_quantity', v_total_quantity,
    'total_amount', round(v_total_amount, 2)
  );
end;
$$;

revoke all on function public.generate_load_form_sales(uuid, uuid, date)
  from public;
grant execute on function public.generate_load_form_sales(uuid, uuid, date)
  to authenticated;

commit;

notify pgrst, 'reload schema';

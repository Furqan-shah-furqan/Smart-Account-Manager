-- Fix Order Booking when public.sales.sale_type is a PostgreSQL enum.
-- Safe to run after the existing DMS migrations.

begin;

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

  if nullif(trim(p_bill_no), '') is null then
    raise exception 'Bill number is required';
  end if;
  if p_quantity <= 0 then
    raise exception 'Quantity must be greater than 0';
  end if;
  if p_price <= 0 then
    raise exception 'Price must be greater than 0';
  end if;
  if lower(p_sale_type) not in ('cash', 'credit') then
    raise exception 'Invalid sale type';
  end if;
  if not exists (
    select 1
    from public.dsrs
    where id = p_dsr_id
      and company_id = p_company_id
  ) then
    raise exception 'Invalid DSR';
  end if;

  select warehouse_stock, purchase_price
  into v_stock, v_cost
  from public.products
  where id = p_product_id
    and company_id = p_company_id
  for update;

  if not found then
    raise exception 'Invalid product';
  end if;
  if v_stock < p_quantity then
    raise exception 'Not enough distributor stock';
  end if;

  update public.products
  set
    warehouse_stock = warehouse_stock - p_quantity,
    updated_at = now()
  where id = p_product_id
    and company_id = p_company_id;

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
    created_by,
    updated_at
  ) values (
    p_company_id,
    current_date,
    trim(p_bill_no),
    p_dsr_id,
    null,
    p_product_id,
    p_quantity,
    round(p_price, 2),
    lower(p_sale_type)::public.sale_type,
    round(v_cost, 2),
    auth.uid(),
    now()
  ) returning id into v_sale_id;

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
    p_product_id,
    p_dsr_id,
    case
      when lower(p_sale_type) = 'cash' then 'Cash Sale'
      else 'Credit Sale'
    end,
    -p_quantity,
    trim(p_bill_no) || ' • Deducted from warehouse stock',
    auth.uid()
  );

  return v_sale_id;
end;
$$;

revoke all on function public.book_sale_atomic(
  uuid,
  text,
  uuid,
  uuid,
  integer,
  numeric,
  text
) from public;

grant execute on function public.book_sale_atomic(
  uuid,
  text,
  uuid,
  uuid,
  integer,
  numeric,
  text
) to authenticated;

commit;

notify pgrst, 'reload schema';

-- Finalize a Load Form Settlement from the print preview.
-- This wrapper preserves the existing sale/stock/report generation logic and
-- additionally saves the counted physical cash for the selected DSR/date.

begin;

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

  if p_dsr_id is null then
    raise exception 'Select DSR first';
  end if;

  if p_date is null then
    raise exception 'Select load form date first';
  end if;

  -- The existing atomic function creates the connected Cash Sales, deducts
  -- stock once, marks load rows as generated, and refreshes all report data.
  v_result := public.generate_load_form_sales(
    p_company_id,
    p_dsr_id,
    p_date
  );

  -- Physical Cash is one daily settlement total, not a value repeated for
  -- every product row. Clear old repeated values and keep it on one load row.
  update public.load_entries
  set
    physical_cash = 0,
    updated_at = now()
  where company_id = p_company_id
    and dsr_id = p_dsr_id
    and date = p_date;

  select id
  into v_cash_row_id
  from public.load_entries
  where company_id = p_company_id
    and dsr_id = p_dsr_id
    and date = p_date
  order by created_at, id
  limit 1;

  if v_cash_row_id is not null then
    update public.load_entries
    set
      physical_cash = v_physical_cash,
      updated_at = now()
    where id = v_cash_row_id
      and company_id = p_company_id;
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

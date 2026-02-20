create or replace function public.fn_dev_purge_all()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- TRUNCATE is the safest/faster way to wipe dev data.
  -- Keep unit + RBAC + app_user tables untouched.
  truncate table
    public.purchase_receipt_line,
    public.purchase_receipt,
    public.production_batch,
    public.stock_movement,
    public.ingredient_stock,
    public.ingredient_supplier_offer,
    public.supplier_offer_price,
    public.supplier_offer,
    public.supplier,
    public.recipe_media,
    public.recipe_step,
    public.recipe_component,
    public.recipe,
    public.ingredient
  restart identity;

  -- If any of these tables have no identity columns, RESTART IDENTITY is still fine.
end;
$$;

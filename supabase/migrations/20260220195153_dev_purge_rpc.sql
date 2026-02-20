create or replace function public.fn_dev_purge_all()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- delete in FK-safe order (update if you add more FK tables)
  delete from public.purchase_receipt_line;
  delete from public.purchase_receipt;

  delete from public.production_batch;

  delete from public.stock_movement;
  delete from public.ingredient_stock;

  delete from public.ingredient_supplier_offer;

  delete from public.supplier_offer_price;
  delete from public.supplier_offer;
  delete from public.supplier;

  delete from public.recipe_media;
  delete from public.recipe_step;
  delete from public.recipe_component;

  delete from public.recipe;
  delete from public.ingredient;

  -- keep: unit, app_user, role, permission, role_permission, user_role, and Supabase auth schema
end;
$$;


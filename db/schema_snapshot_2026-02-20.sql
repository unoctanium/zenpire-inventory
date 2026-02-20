


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."fn_dev_purge_all"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
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


ALTER FUNCTION "public"."fn_dev_purge_all"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_ensure_ingredient_stock"("p_ingredient_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_unit_id uuid;
begin
  if exists (select 1 from ingredient_stock where ingredient_id = p_ingredient_id) then
    return;
  end if;

  select default_unit_id into v_unit_id from ingredient where id = p_ingredient_id;
  if v_unit_id is null then
    raise exception 'Ingredient % not found', p_ingredient_id;
  end if;

  insert into ingredient_stock(ingredient_id, on_hand_quantity, planned_quantity, unit_id)
  values (p_ingredient_id, 0, 0, v_unit_id);
end;
$$;


ALTER FUNCTION "public"."fn_ensure_ingredient_stock"("p_ingredient_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_get_current_offer_price"("p_offer_id" "uuid", "p_at_date" "date") RETURNS TABLE("currency" "text", "price_per_pack" numeric, "valid_from" "date")
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
  select
    sop.currency,
    sop.price_per_pack,
    sop.valid_from
  from supplier_offer_price sop
  where sop.supplier_offer_id = p_offer_id
    and sop.valid_from <= p_at_date
    and (sop.valid_to is null or sop.valid_to >= p_at_date)
  order by sop.valid_from desc
  limit 1;
$$;


ALTER FUNCTION "public"."fn_get_current_offer_price"("p_offer_id" "uuid", "p_at_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_post_adjustment"("p_payload" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_movement_id uuid;
  v_ingredient_id uuid;
  v_qty numeric;
  v_unit_id uuid;
  v_occurred_at timestamptz;
  v_unit_cost numeric;
  v_currency text;
  v_note text;
  v_created_by uuid;
  v_stock_unit uuid;
begin
  v_ingredient_id := (p_payload->>'ingredient_id')::uuid;
  v_qty := (p_payload->>'quantity')::numeric;
  v_unit_id := (p_payload->>'unit_id')::uuid;
  v_occurred_at := (p_payload->>'occurred_at')::timestamptz;
  v_unit_cost := nullif(p_payload->>'unit_cost_snapshot','')::numeric;
  v_currency := coalesce(nullif(p_payload->>'currency',''), 'EUR');
  v_note := p_payload->>'note';
  v_created_by := (p_payload->>'created_by_user_id')::uuid;

  if v_ingredient_id is null or v_created_by is null or v_qty is null or v_qty = 0 then
    raise exception 'ingredient_id, quantity (non-zero), created_by_user_id required';
  end if;

  if v_occurred_at is null then
    v_occurred_at := now();
  end if;

  perform fn_ensure_ingredient_stock(v_ingredient_id);

  select unit_id into v_stock_unit from ingredient_stock where ingredient_id = v_ingredient_id;

  if v_unit_id is null then
    v_unit_id := v_stock_unit;
  end if;

  if v_unit_id <> v_stock_unit then
    raise exception 'Unit mismatch: adjustment unit % must equal ingredient stock unit % (MVP)', v_unit_id, v_stock_unit;
  end if;

  insert into stock_movement(
    ingredient_id, movement_type, quantity, unit_id, occurred_at,
    unit_cost_snapshot, currency, note, created_by_user_id
  )
  values (
    v_ingredient_id, 'adjust', v_qty, v_unit_id, v_occurred_at,
    v_unit_cost, v_currency, v_note, v_created_by
  )
  returning id into v_movement_id;

  update ingredient_stock
    set on_hand_quantity = on_hand_quantity + v_qty,
        updated_at = now()
  where ingredient_id = v_ingredient_id;

  return v_movement_id;
end;
$$;


ALTER FUNCTION "public"."fn_post_adjustment"("p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_post_production_batch"("p_payload" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_batch_id uuid;
  v_recipe_id uuid;
  v_qty numeric;
  v_unit_id uuid;
  v_produced_at timestamptz;
  v_created_by uuid;
  v_note text;

  v_recipe_output_qty numeric;
  v_recipe_output_unit uuid;

  v_output_ingredient_id uuid;

  v_scale numeric;

  v_comp record;
  v_comp_delta numeric;
  v_ing_unit uuid;

begin
  v_recipe_id := (p_payload->>'recipe_id')::uuid;
  v_qty := (p_payload->>'produced_quantity')::numeric;
  v_unit_id := (p_payload->>'unit_id')::uuid;
  v_produced_at := (p_payload->>'produced_at')::timestamptz;
  v_created_by := (p_payload->>'created_by_user_id')::uuid;
  v_note := p_payload->>'note';

  if v_recipe_id is null or v_created_by is null or v_qty is null or v_qty <= 0 then
    raise exception 'recipe_id, produced_quantity (>0), created_by_user_id required';
  end if;

  if v_produced_at is null then
    v_produced_at := now();
  end if;

  select r.output_quantity, r.output_unit_id
    into v_recipe_output_qty, v_recipe_output_unit
  from recipe r
  where r.id = v_recipe_id;

  if v_recipe_output_unit is null then
    raise exception 'Recipe % not found', v_recipe_id;
  end if;

  if v_unit_id is null then
    v_unit_id := v_recipe_output_unit;
  end if;

  if v_unit_id <> v_recipe_output_unit then
    raise exception 'Unit mismatch: provided unit_id % must equal recipe output unit % (MVP)',
      v_unit_id, v_recipe_output_unit;
  end if;

  -- Exactly one produced ingredient for this recipe
  select i.id into v_output_ingredient_id
  from ingredient i
  where i.kind = 'produced'
    and i.produced_by_recipe_id = v_recipe_id;

  if v_output_ingredient_id is null then
    raise exception 'No produced ingredient linked to recipe %', v_recipe_id;
  end if;

  perform fn_ensure_ingredient_stock(v_output_ingredient_id);

  insert into production_batch(recipe_id, produced_quantity, unit_id, produced_at, created_by_user_id, note, status)
  values (v_recipe_id, v_qty, v_unit_id, v_produced_at, v_created_by, v_note, 'posted')
  returning id into v_batch_id;

  -- scale components relative to recipe output quantity
  if v_recipe_output_qty <= 0 then
    raise exception 'Recipe output_quantity must be > 0 for recipe %', v_recipe_id;
  end if;

  v_scale := v_qty / v_recipe_output_qty;

  -- Produce IN: increase output ingredient stock
  select unit_id into v_ing_unit from ingredient_stock where ingredient_id = v_output_ingredient_id;
  if v_ing_unit <> v_unit_id then
    raise exception 'Produced ingredient stock unit % must equal recipe output unit % (MVP)', v_ing_unit, v_unit_id;
  end if;

  insert into stock_movement(
    ingredient_id, movement_type, quantity, unit_id, occurred_at,
    reference_type, reference_id, note, created_by_user_id
  )
  values (
    v_output_ingredient_id, 'produce_in', v_qty, v_unit_id, v_produced_at,
    'production_batch', v_batch_id, v_note, v_created_by
  );

  update ingredient_stock
    set on_hand_quantity = on_hand_quantity + v_qty,
        updated_at = now()
  where ingredient_id = v_output_ingredient_id;

  -- Produce OUT: consume components
  for v_comp in
    select rc.ingredient_id, rc.quantity, rc.unit_id
    from recipe_component rc
    where rc.recipe_id = v_recipe_id
  loop
    perform fn_ensure_ingredient_stock(v_comp.ingredient_id);

    select unit_id into v_ing_unit from ingredient_stock where ingredient_id = v_comp.ingredient_id;

    -- MVP: component unit must match ingredient stock unit
    if v_comp.unit_id <> v_ing_unit then
      raise exception 'Component unit mismatch for ingredient % (component unit %, stock unit %) (MVP)',
        v_comp.ingredient_id, v_comp.unit_id, v_ing_unit;
    end if;

    v_comp_delta := (v_comp.quantity * v_scale); -- amount to consume (positive)
    -- record as negative movement
    insert into stock_movement(
      ingredient_id, movement_type, quantity, unit_id, occurred_at,
      reference_type, reference_id, note, created_by_user_id
    )
    values (
      v_comp.ingredient_id, 'produce_out', -v_comp_delta, v_ing_unit, v_produced_at,
      'production_batch', v_batch_id, v_note, v_created_by
    );

    update ingredient_stock
      set on_hand_quantity = on_hand_quantity - v_comp_delta,
          updated_at = now()
    where ingredient_id = v_comp.ingredient_id;
  end loop;

  return v_batch_id;
end;
$$;


ALTER FUNCTION "public"."fn_post_production_batch"("p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_post_purchase_receipt"("p_payload" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_receipt_id uuid;
  v_supplier_id uuid;
  v_received_at timestamptz;
  v_invoice_no text;
  v_note text;
  v_created_by uuid;

  v_line jsonb;
  v_ingredient_id uuid;
  v_offer_id uuid;
  v_packs numeric;
  v_price_override numeric;
  v_currency_override text;

  v_pack_qty numeric;
  v_pack_unit uuid;
  v_ing_unit uuid;

  v_price numeric;
  v_currency text;

  v_delta_qty numeric;
  v_unit_cost numeric;

  v_movement_id uuid;
  v_at_date date;
begin
  v_supplier_id := (p_payload->>'supplier_id')::uuid;
  v_received_at := (p_payload->>'received_at')::timestamptz;
  v_invoice_no := p_payload->>'invoice_no';
  v_note := p_payload->>'note';
  v_created_by := (p_payload->>'created_by_user_id')::uuid;

  if v_supplier_id is null or v_created_by is null then
    raise exception 'supplier_id and created_by_user_id required';
  end if;

  if v_received_at is null then
    v_received_at := now();
  end if;

  insert into purchase_receipt(supplier_id, received_at, invoice_no, note, created_by_user_id)
  values (v_supplier_id, v_received_at, v_invoice_no, v_note, v_created_by)
  returning id into v_receipt_id;

  v_at_date := (v_received_at at time zone 'UTC')::date;

  for v_line in select * from jsonb_array_elements(coalesce(p_payload->'lines','[]'::jsonb))
  loop
    v_ingredient_id := (v_line->>'ingredient_id')::uuid;
    v_offer_id := (v_line->>'supplier_offer_id')::uuid;
    v_packs := (v_line->>'packs_received')::numeric;
    v_price_override := nullif(v_line->>'price_per_pack','')::numeric;
    v_currency_override := nullif(v_line->>'currency','');

    if v_ingredient_id is null or v_offer_id is null or v_packs is null or v_packs <= 0 then
      raise exception 'Invalid receipt line: %', v_line;
    end if;

    perform fn_ensure_ingredient_stock(v_ingredient_id);

    -- Offer pack snapshots
    select so.pack_quantity, so.pack_unit_id
      into v_pack_qty, v_pack_unit
    from supplier_offer so
    where so.id = v_offer_id;

    if v_pack_qty is null then
      raise exception 'Supplier offer % not found', v_offer_id;
    end if;

    select unit_id into v_ing_unit from ingredient_stock where ingredient_id = v_ingredient_id;

    -- MVP: require same unit between offer pack_unit and ingredient stock unit
    if v_pack_unit <> v_ing_unit then
      raise exception 'Unit mismatch: offer pack_unit % vs ingredient_stock unit % (MVP requires same unit)',
        v_pack_unit, v_ing_unit;
    end if;

    -- Determine price snapshot
    if v_price_override is not null then
      v_price := v_price_override;
      v_currency := coalesce(v_currency_override,'EUR');
    else
      select p.currency, p.price_per_pack
        into v_currency, v_price
      from fn_get_current_offer_price(v_offer_id, v_at_date) p;

      if v_price is null then
        raise exception 'No valid price for offer % at %', v_offer_id, v_at_date;
      end if;
    end if;

    v_delta_qty := v_packs * v_pack_qty;           -- in ingredient unit
    v_unit_cost := v_price / v_pack_qty;           -- normalized per ingredient unit

    insert into stock_movement(
      ingredient_id, movement_type, quantity, unit_id, occurred_at,
      unit_cost_snapshot, currency, reference_type, reference_id, note, created_by_user_id
    )
    values (
      v_ingredient_id, 'purchase', v_delta_qty, v_ing_unit, v_received_at,
      v_unit_cost, v_currency, 'purchase_receipt', v_receipt_id, v_note, v_created_by
    )
    returning id into v_movement_id;

    insert into purchase_receipt_line(
      purchase_receipt_id, ingredient_id, supplier_offer_id,
      packs_received, pack_quantity_snapshot, pack_unit_snapshot_id,
      price_per_pack_snapshot, currency, stock_movement_id, note
    )
    values (
      v_receipt_id, v_ingredient_id, v_offer_id,
      v_packs, v_pack_qty, v_pack_unit,
      v_price, v_currency, v_movement_id, v_note
    );

    update ingredient_stock
      set on_hand_quantity = on_hand_quantity + v_delta_qty,
          updated_at = now()
    where ingredient_id = v_ingredient_id;
  end loop;

  return v_receipt_id;
end;
$$;


ALTER FUNCTION "public"."fn_post_purchase_receipt"("p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_post_waste"("p_payload" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_movement_id uuid;
  v_ingredient_id uuid;
  v_qty numeric;
  v_unit_id uuid;
  v_occurred_at timestamptz;
  v_unit_cost numeric;
  v_currency text;
  v_note text;
  v_created_by uuid;
  v_stock_unit uuid;
begin
  v_ingredient_id := (p_payload->>'ingredient_id')::uuid;
  v_qty := (p_payload->>'quantity')::numeric;
  v_unit_id := (p_payload->>'unit_id')::uuid;
  v_occurred_at := (p_payload->>'occurred_at')::timestamptz;
  v_unit_cost := (p_payload->>'unit_cost_snapshot')::numeric;
  v_currency := coalesce(nullif(p_payload->>'currency',''), 'EUR');
  v_note := p_payload->>'note';
  v_created_by := (p_payload->>'created_by_user_id')::uuid;

  if v_ingredient_id is null or v_created_by is null or v_qty is null or v_qty <= 0 then
    raise exception 'ingredient_id, quantity (>0), created_by_user_id required';
  end if;

  if v_unit_cost is null then
    raise exception 'unit_cost_snapshot required for waste';
  end if;

  if v_occurred_at is null then
    v_occurred_at := now();
  end if;

  perform fn_ensure_ingredient_stock(v_ingredient_id);

  select unit_id into v_stock_unit from ingredient_stock where ingredient_id = v_ingredient_id;

  if v_unit_id is null then
    v_unit_id := v_stock_unit;
  end if;

  if v_unit_id <> v_stock_unit then
    raise exception 'Unit mismatch: waste unit % must equal ingredient stock unit % (MVP)', v_unit_id, v_stock_unit;
  end if;

  insert into stock_movement(
    ingredient_id, movement_type, quantity, unit_id, occurred_at,
    unit_cost_snapshot, currency, note, created_by_user_id
  )
  values (
    v_ingredient_id, 'waste', -v_qty, v_unit_id, v_occurred_at,
    v_unit_cost, v_currency, v_note, v_created_by
  )
  returning id into v_movement_id;

  update ingredient_stock
    set on_hand_quantity = on_hand_quantity - v_qty,
        updated_at = now()
  where ingredient_id = v_ingredient_id;

  return v_movement_id;
end;
$$;


ALTER FUNCTION "public"."fn_post_waste"("p_payload" "jsonb") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."app_user" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "auth_user_id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "display_name" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."app_user" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ingredient" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "default_unit_id" "uuid" NOT NULL,
    "kind" "text" NOT NULL,
    "produced_by_recipe_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "standard_unit_cost" numeric(18,6),
    "standard_cost_currency" "text" DEFAULT 'EUR'::"text" NOT NULL,
    "standard_cost_updated_at" timestamp with time zone,
    CONSTRAINT "ck_ingredient_kind" CHECK (((("kind" = 'purchased'::"text") AND ("produced_by_recipe_id" IS NULL)) OR (("kind" = 'produced'::"text") AND ("produced_by_recipe_id" IS NOT NULL)))),
    CONSTRAINT "ingredient_kind_check" CHECK (("kind" = ANY (ARRAY['purchased'::"text", 'produced'::"text"])))
);


ALTER TABLE "public"."ingredient" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ingredient_stock" (
    "ingredient_id" "uuid" NOT NULL,
    "on_hand_quantity" numeric(18,6) DEFAULT 0 NOT NULL,
    "planned_quantity" numeric(18,6) DEFAULT 0 NOT NULL,
    "unit_id" "uuid" NOT NULL,
    "green_min_delta" numeric(18,6) DEFAULT 0 NOT NULL,
    "yellow_min_delta" numeric(18,6) DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ingredient_stock" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ingredient_supplier_offer" (
    "ingredient_id" "uuid" NOT NULL,
    "supplier_offer_id" "uuid" NOT NULL,
    "priority" integer,
    "is_preferred" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."ingredient_supplier_offer" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."permission" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."permission" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."production_batch" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "produced_quantity" numeric(18,6) NOT NULL,
    "unit_id" "uuid" NOT NULL,
    "produced_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by_user_id" "uuid" NOT NULL,
    "note" "text",
    "status" "text" DEFAULT 'posted'::"text" NOT NULL,
    CONSTRAINT "production_batch_produced_quantity_check" CHECK (("produced_quantity" > (0)::numeric)),
    CONSTRAINT "production_batch_status_check" CHECK (("status" = ANY (ARRAY['posted'::"text", 'voided'::"text"])))
);


ALTER TABLE "public"."production_batch" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."purchase_receipt" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "supplier_id" "uuid" NOT NULL,
    "received_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "invoice_no" "text",
    "note" "text",
    "created_by_user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."purchase_receipt" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."purchase_receipt_line" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_receipt_id" "uuid" NOT NULL,
    "ingredient_id" "uuid" NOT NULL,
    "supplier_offer_id" "uuid" NOT NULL,
    "packs_received" numeric(18,6) NOT NULL,
    "pack_quantity_snapshot" numeric(18,6) NOT NULL,
    "pack_unit_snapshot_id" "uuid" NOT NULL,
    "price_per_pack_snapshot" numeric(18,6) NOT NULL,
    "currency" "text" DEFAULT 'EUR'::"text" NOT NULL,
    "stock_movement_id" "uuid" NOT NULL,
    "note" "text",
    CONSTRAINT "purchase_receipt_line_pack_quantity_snapshot_check" CHECK (("pack_quantity_snapshot" > (0)::numeric)),
    CONSTRAINT "purchase_receipt_line_packs_received_check" CHECK (("packs_received" > (0)::numeric)),
    CONSTRAINT "purchase_receipt_line_price_per_pack_snapshot_check" CHECK (("price_per_pack_snapshot" >= (0)::numeric))
);


ALTER TABLE "public"."purchase_receipt_line" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "output_quantity" numeric(18,6) DEFAULT 1 NOT NULL,
    "output_unit_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."recipe" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe_component" (
    "recipe_id" "uuid" NOT NULL,
    "ingredient_id" "uuid" NOT NULL,
    "quantity" numeric(18,6) NOT NULL,
    "unit_id" "uuid" NOT NULL,
    CONSTRAINT "recipe_component_quantity_check" CHECK (("quantity" > (0)::numeric))
);


ALTER TABLE "public"."recipe_component" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe_media" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "storage_path" "text" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."recipe_media" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe_step" (
    "recipe_id" "uuid" NOT NULL,
    "step_no" integer NOT NULL,
    "instruction_text" "text" NOT NULL,
    CONSTRAINT "recipe_step_step_no_check" CHECK (("step_no" > 0))
);


ALTER TABLE "public"."recipe_step" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."role" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_permission" (
    "role_id" "uuid" NOT NULL,
    "permission_id" "uuid" NOT NULL
);


ALTER TABLE "public"."role_permission" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stock_movement" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ingredient_id" "uuid" NOT NULL,
    "movement_type" "text" NOT NULL,
    "quantity" numeric(18,6) NOT NULL,
    "unit_id" "uuid" NOT NULL,
    "occurred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "unit_cost_snapshot" numeric(18,6),
    "currency" "text",
    "reference_type" "text",
    "reference_id" "uuid",
    "note" "text",
    "created_by_user_id" "uuid" NOT NULL,
    CONSTRAINT "ck_waste_cost_required" CHECK ((("movement_type" <> 'waste'::"text") OR ("unit_cost_snapshot" IS NOT NULL))),
    CONSTRAINT "stock_movement_movement_type_check" CHECK (("movement_type" = ANY (ARRAY['purchase'::"text", 'produce_in'::"text", 'produce_out'::"text", 'waste'::"text", 'adjust'::"text", 'consume'::"text"])))
);


ALTER TABLE "public"."stock_movement" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."supplier" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "contact_email" "text",
    "contact_phone" "text",
    "note" "text"
);


ALTER TABLE "public"."supplier" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."supplier_offer" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "supplier_id" "uuid" NOT NULL,
    "offer_name" "text" NOT NULL,
    "supplier_article_number" "text",
    "pack_quantity" numeric(18,6) NOT NULL,
    "pack_unit_id" "uuid" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "active_from" "date",
    "active_to" "date",
    "notes" "text",
    CONSTRAINT "supplier_offer_pack_quantity_check" CHECK (("pack_quantity" > (0)::numeric))
);


ALTER TABLE "public"."supplier_offer" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."supplier_offer_price" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "supplier_offer_id" "uuid" NOT NULL,
    "valid_from" "date" NOT NULL,
    "valid_to" "date",
    "currency" "text" DEFAULT 'EUR'::"text" NOT NULL,
    "price_per_pack" numeric(18,6) NOT NULL,
    CONSTRAINT "ck_price_validity" CHECK ((("valid_to" IS NULL) OR ("valid_to" >= "valid_from"))),
    CONSTRAINT "supplier_offer_price_price_per_pack_check" CHECK (("price_per_pack" >= (0)::numeric))
);


ALTER TABLE "public"."supplier_offer_price" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."unit" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "unit_type" "text" NOT NULL,
    CONSTRAINT "unit_unit_type_check" CHECK (("unit_type" = ANY (ARRAY['mass'::"text", 'volume'::"text", 'count'::"text"])))
);


ALTER TABLE "public"."unit" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_role" (
    "user_id" "uuid" NOT NULL,
    "role_id" "uuid" NOT NULL
);


ALTER TABLE "public"."user_role" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_latest_purchase_cost" WITH ("security_invoker"='true') AS
 SELECT DISTINCT ON ("ingredient_id") "ingredient_id",
    "unit_cost_snapshot" AS "latest_unit_cost",
    "currency",
    "occurred_at" AS "last_purchase_at"
   FROM "public"."stock_movement" "sm"
  WHERE (("movement_type" = 'purchase'::"text") AND ("unit_cost_snapshot" IS NOT NULL))
  ORDER BY "ingredient_id", "occurred_at" DESC;


ALTER VIEW "public"."v_latest_purchase_cost" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_recipe_standard_cost" AS
 SELECT "r"."id" AS "recipe_id",
    "r"."name" AS "recipe_name",
    COALESCE("sum"(("rc"."quantity" * COALESCE("i"."standard_unit_cost", (0)::numeric))), (0)::numeric) AS "standard_cost",
    'EUR'::"text" AS "currency"
   FROM (("public"."recipe" "r"
     LEFT JOIN "public"."recipe_component" "rc" ON (("rc"."recipe_id" = "r"."id")))
     LEFT JOIN "public"."ingredient" "i" ON (("i"."id" = "rc"."ingredient_id")))
  GROUP BY "r"."id", "r"."name";


ALTER VIEW "public"."v_recipe_standard_cost" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_stock_delta" WITH ("security_invoker"='true') AS
 SELECT "i"."id" AS "ingredient_id",
    "i"."name" AS "ingredient_name",
    "u"."code" AS "unit_code",
    "s"."planned_quantity",
    "s"."on_hand_quantity",
    ("s"."planned_quantity" - "s"."on_hand_quantity") AS "delta",
        CASE
            WHEN (("s"."planned_quantity" - "s"."on_hand_quantity") <= "s"."green_min_delta") THEN 'green'::"text"
            WHEN (("s"."planned_quantity" - "s"."on_hand_quantity") <= "s"."yellow_min_delta") THEN 'yellow'::"text"
            ELSE 'red'::"text"
        END AS "status",
    "s"."updated_at" AS "planned_updated_at"
   FROM (("public"."ingredient_stock" "s"
     JOIN "public"."ingredient" "i" ON (("i"."id" = "s"."ingredient_id")))
     JOIN "public"."unit" "u" ON (("u"."id" = "s"."unit_id")));


ALTER VIEW "public"."v_stock_delta" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_stock_snapshot" WITH ("security_invoker"='true') AS
 SELECT "i"."id" AS "ingredient_id",
    "i"."name" AS "ingredient_name",
    "u"."code" AS "unit_code",
    "s"."on_hand_quantity",
    COALESCE("c"."latest_unit_cost", (0)::numeric) AS "estimated_unit_cost",
    COALESCE("c"."currency", 'EUR'::"text") AS "currency",
    ("s"."on_hand_quantity" * COALESCE("c"."latest_unit_cost", (0)::numeric)) AS "stock_value",
    "c"."last_purchase_at"
   FROM ((("public"."ingredient_stock" "s"
     JOIN "public"."ingredient" "i" ON (("i"."id" = "s"."ingredient_id")))
     JOIN "public"."unit" "u" ON (("u"."id" = "s"."unit_id")))
     LEFT JOIN "public"."v_latest_purchase_cost" "c" ON (("c"."ingredient_id" = "s"."ingredient_id")));


ALTER VIEW "public"."v_stock_snapshot" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_user_permissions" WITH ("security_invoker"='true') AS
 SELECT "au"."id" AS "app_user_id",
    "au"."auth_user_id",
    "p"."code" AS "permission_code"
   FROM ((("public"."app_user" "au"
     JOIN "public"."user_role" "ur" ON (("ur"."user_id" = "au"."id")))
     JOIN "public"."role_permission" "rp" ON (("rp"."role_id" = "ur"."role_id")))
     JOIN "public"."permission" "p" ON (("p"."id" = "rp"."permission_id")));


ALTER VIEW "public"."v_user_permissions" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_waste_daily" WITH ("security_invoker"='true') AS
 SELECT "date_trunc"('day'::"text", "sm"."occurred_at") AS "day",
    "i"."id" AS "ingredient_id",
    "i"."name" AS "ingredient_name",
    "u"."code" AS "unit_code",
    "sum"("abs"("sm"."quantity")) AS "waste_qty",
    COALESCE("sm"."currency", 'EUR'::"text") AS "currency",
    "sum"(("abs"("sm"."quantity") * "sm"."unit_cost_snapshot")) AS "waste_value"
   FROM (("public"."stock_movement" "sm"
     JOIN "public"."ingredient" "i" ON (("i"."id" = "sm"."ingredient_id")))
     JOIN "public"."unit" "u" ON (("u"."id" = "sm"."unit_id")))
  WHERE ("sm"."movement_type" = 'waste'::"text")
  GROUP BY ("date_trunc"('day'::"text", "sm"."occurred_at")), "i"."id", "i"."name", "u"."code", COALESCE("sm"."currency", 'EUR'::"text");


ALTER VIEW "public"."v_waste_daily" OWNER TO "postgres";


ALTER TABLE ONLY "public"."app_user"
    ADD CONSTRAINT "app_user_auth_user_id_key" UNIQUE ("auth_user_id");



ALTER TABLE ONLY "public"."app_user"
    ADD CONSTRAINT "app_user_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ingredient"
    ADD CONSTRAINT "ingredient_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."ingredient"
    ADD CONSTRAINT "ingredient_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ingredient_stock"
    ADD CONSTRAINT "ingredient_stock_pkey" PRIMARY KEY ("ingredient_id");



ALTER TABLE ONLY "public"."ingredient_supplier_offer"
    ADD CONSTRAINT "ingredient_supplier_offer_pkey" PRIMARY KEY ("ingredient_id", "supplier_offer_id");



ALTER TABLE ONLY "public"."permission"
    ADD CONSTRAINT "permission_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."permission"
    ADD CONSTRAINT "permission_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."production_batch"
    ADD CONSTRAINT "production_batch_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."purchase_receipt_line"
    ADD CONSTRAINT "purchase_receipt_line_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."purchase_receipt"
    ADD CONSTRAINT "purchase_receipt_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_component"
    ADD CONSTRAINT "recipe_component_pkey" PRIMARY KEY ("recipe_id", "ingredient_id");



ALTER TABLE ONLY "public"."recipe_media"
    ADD CONSTRAINT "recipe_media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe"
    ADD CONSTRAINT "recipe_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_step"
    ADD CONSTRAINT "recipe_step_pkey" PRIMARY KEY ("recipe_id", "step_no");



ALTER TABLE ONLY "public"."role"
    ADD CONSTRAINT "role_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."role_permission"
    ADD CONSTRAINT "role_permission_pkey" PRIMARY KEY ("role_id", "permission_id");



ALTER TABLE ONLY "public"."role"
    ADD CONSTRAINT "role_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_movement"
    ADD CONSTRAINT "stock_movement_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."supplier"
    ADD CONSTRAINT "supplier_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."supplier_offer"
    ADD CONSTRAINT "supplier_offer_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."supplier_offer_price"
    ADD CONSTRAINT "supplier_offer_price_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."supplier"
    ADD CONSTRAINT "supplier_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."unit"
    ADD CONSTRAINT "unit_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."unit"
    ADD CONSTRAINT "unit_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_role"
    ADD CONSTRAINT "user_role_pkey" PRIMARY KEY ("user_id", "role_id");



CREATE INDEX "ix_ing_offer_ing" ON "public"."ingredient_supplier_offer" USING "btree" ("ingredient_id");



CREATE INDEX "ix_ing_offer_offer" ON "public"."ingredient_supplier_offer" USING "btree" ("supplier_offer_id");



CREATE INDEX "ix_offer_price_offer_from" ON "public"."supplier_offer_price" USING "btree" ("supplier_offer_id", "valid_from" DESC);



CREATE INDEX "ix_production_batch_time" ON "public"."production_batch" USING "btree" ("produced_at" DESC);



CREATE INDEX "ix_purchase_line_receipt" ON "public"."purchase_receipt_line" USING "btree" ("purchase_receipt_id");



CREATE INDEX "ix_purchase_receipt_supplier_time" ON "public"."purchase_receipt" USING "btree" ("supplier_id", "received_at" DESC);



CREATE INDEX "ix_recipe_media_recipe" ON "public"."recipe_media" USING "btree" ("recipe_id", "sort_order");



CREATE INDEX "ix_stock_movement_ing_time" ON "public"."stock_movement" USING "btree" ("ingredient_id", "occurred_at" DESC);



CREATE INDEX "ix_stock_movement_type_time" ON "public"."stock_movement" USING "btree" ("movement_type", "occurred_at" DESC);



CREATE INDEX "ix_supplier_offer_active" ON "public"."supplier_offer" USING "btree" ("is_active", "active_to");



CREATE INDEX "ix_supplier_offer_supplier" ON "public"."supplier_offer" USING "btree" ("supplier_id");



ALTER TABLE ONLY "public"."ingredient"
    ADD CONSTRAINT "ingredient_default_unit_id_fkey" FOREIGN KEY ("default_unit_id") REFERENCES "public"."unit"("id");



ALTER TABLE ONLY "public"."ingredient"
    ADD CONSTRAINT "ingredient_produced_by_recipe_id_fkey" FOREIGN KEY ("produced_by_recipe_id") REFERENCES "public"."recipe"("id");



ALTER TABLE ONLY "public"."ingredient_stock"
    ADD CONSTRAINT "ingredient_stock_ingredient_id_fkey" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredient"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ingredient_stock"
    ADD CONSTRAINT "ingredient_stock_unit_id_fkey" FOREIGN KEY ("unit_id") REFERENCES "public"."unit"("id");



ALTER TABLE ONLY "public"."ingredient_supplier_offer"
    ADD CONSTRAINT "ingredient_supplier_offer_ingredient_id_fkey" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredient"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ingredient_supplier_offer"
    ADD CONSTRAINT "ingredient_supplier_offer_supplier_offer_id_fkey" FOREIGN KEY ("supplier_offer_id") REFERENCES "public"."supplier_offer"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."production_batch"
    ADD CONSTRAINT "production_batch_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."app_user"("id");



ALTER TABLE ONLY "public"."production_batch"
    ADD CONSTRAINT "production_batch_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipe"("id");



ALTER TABLE ONLY "public"."production_batch"
    ADD CONSTRAINT "production_batch_unit_id_fkey" FOREIGN KEY ("unit_id") REFERENCES "public"."unit"("id");



ALTER TABLE ONLY "public"."purchase_receipt"
    ADD CONSTRAINT "purchase_receipt_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."app_user"("id");



ALTER TABLE ONLY "public"."purchase_receipt_line"
    ADD CONSTRAINT "purchase_receipt_line_ingredient_id_fkey" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredient"("id");



ALTER TABLE ONLY "public"."purchase_receipt_line"
    ADD CONSTRAINT "purchase_receipt_line_pack_unit_snapshot_id_fkey" FOREIGN KEY ("pack_unit_snapshot_id") REFERENCES "public"."unit"("id");



ALTER TABLE ONLY "public"."purchase_receipt_line"
    ADD CONSTRAINT "purchase_receipt_line_purchase_receipt_id_fkey" FOREIGN KEY ("purchase_receipt_id") REFERENCES "public"."purchase_receipt"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchase_receipt_line"
    ADD CONSTRAINT "purchase_receipt_line_stock_movement_id_fkey" FOREIGN KEY ("stock_movement_id") REFERENCES "public"."stock_movement"("id");



ALTER TABLE ONLY "public"."purchase_receipt_line"
    ADD CONSTRAINT "purchase_receipt_line_supplier_offer_id_fkey" FOREIGN KEY ("supplier_offer_id") REFERENCES "public"."supplier_offer"("id");



ALTER TABLE ONLY "public"."purchase_receipt"
    ADD CONSTRAINT "purchase_receipt_supplier_id_fkey" FOREIGN KEY ("supplier_id") REFERENCES "public"."supplier"("id");



ALTER TABLE ONLY "public"."recipe_component"
    ADD CONSTRAINT "recipe_component_ingredient_id_fkey" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredient"("id");



ALTER TABLE ONLY "public"."recipe_component"
    ADD CONSTRAINT "recipe_component_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipe"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_component"
    ADD CONSTRAINT "recipe_component_unit_id_fkey" FOREIGN KEY ("unit_id") REFERENCES "public"."unit"("id");



ALTER TABLE ONLY "public"."recipe_media"
    ADD CONSTRAINT "recipe_media_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipe"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe"
    ADD CONSTRAINT "recipe_output_unit_id_fkey" FOREIGN KEY ("output_unit_id") REFERENCES "public"."unit"("id");



ALTER TABLE ONLY "public"."recipe_step"
    ADD CONSTRAINT "recipe_step_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipe"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permission"
    ADD CONSTRAINT "role_permission_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."permission"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permission"
    ADD CONSTRAINT "role_permission_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."role"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_movement"
    ADD CONSTRAINT "stock_movement_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."app_user"("id");



ALTER TABLE ONLY "public"."stock_movement"
    ADD CONSTRAINT "stock_movement_ingredient_id_fkey" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredient"("id");



ALTER TABLE ONLY "public"."stock_movement"
    ADD CONSTRAINT "stock_movement_unit_id_fkey" FOREIGN KEY ("unit_id") REFERENCES "public"."unit"("id");



ALTER TABLE ONLY "public"."supplier_offer"
    ADD CONSTRAINT "supplier_offer_pack_unit_id_fkey" FOREIGN KEY ("pack_unit_id") REFERENCES "public"."unit"("id");



ALTER TABLE ONLY "public"."supplier_offer_price"
    ADD CONSTRAINT "supplier_offer_price_supplier_offer_id_fkey" FOREIGN KEY ("supplier_offer_id") REFERENCES "public"."supplier_offer"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."supplier_offer"
    ADD CONSTRAINT "supplier_offer_supplier_id_fkey" FOREIGN KEY ("supplier_id") REFERENCES "public"."supplier"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_role"
    ADD CONSTRAINT "user_role_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."role"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_role"
    ADD CONSTRAINT "user_role_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."app_user"("id") ON DELETE CASCADE;



ALTER TABLE "public"."app_user" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ingredient" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ingredient_stock" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ingredient_supplier_offer" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."permission" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."production_batch" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."purchase_receipt" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."purchase_receipt_line" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_component" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_media" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_step" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."role" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."role_permission" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stock_movement" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."supplier" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."supplier_offer" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."supplier_offer_price" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."unit" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_role" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_dev_purge_all"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_dev_purge_all"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_dev_purge_all"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_ensure_ingredient_stock"("p_ingredient_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."fn_ensure_ingredient_stock"("p_ingredient_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_ensure_ingredient_stock"("p_ingredient_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_get_current_offer_price"("p_offer_id" "uuid", "p_at_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."fn_get_current_offer_price"("p_offer_id" "uuid", "p_at_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_get_current_offer_price"("p_offer_id" "uuid", "p_at_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_post_adjustment"("p_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."fn_post_adjustment"("p_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_post_adjustment"("p_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_post_production_batch"("p_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."fn_post_production_batch"("p_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_post_production_batch"("p_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_post_purchase_receipt"("p_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."fn_post_purchase_receipt"("p_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_post_purchase_receipt"("p_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_post_waste"("p_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."fn_post_waste"("p_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_post_waste"("p_payload" "jsonb") TO "service_role";



GRANT ALL ON TABLE "public"."app_user" TO "anon";
GRANT ALL ON TABLE "public"."app_user" TO "authenticated";
GRANT ALL ON TABLE "public"."app_user" TO "service_role";



GRANT ALL ON TABLE "public"."ingredient" TO "anon";
GRANT ALL ON TABLE "public"."ingredient" TO "authenticated";
GRANT ALL ON TABLE "public"."ingredient" TO "service_role";



GRANT ALL ON TABLE "public"."ingredient_stock" TO "anon";
GRANT ALL ON TABLE "public"."ingredient_stock" TO "authenticated";
GRANT ALL ON TABLE "public"."ingredient_stock" TO "service_role";



GRANT ALL ON TABLE "public"."ingredient_supplier_offer" TO "anon";
GRANT ALL ON TABLE "public"."ingredient_supplier_offer" TO "authenticated";
GRANT ALL ON TABLE "public"."ingredient_supplier_offer" TO "service_role";



GRANT ALL ON TABLE "public"."permission" TO "anon";
GRANT ALL ON TABLE "public"."permission" TO "authenticated";
GRANT ALL ON TABLE "public"."permission" TO "service_role";



GRANT ALL ON TABLE "public"."production_batch" TO "anon";
GRANT ALL ON TABLE "public"."production_batch" TO "authenticated";
GRANT ALL ON TABLE "public"."production_batch" TO "service_role";



GRANT ALL ON TABLE "public"."purchase_receipt" TO "anon";
GRANT ALL ON TABLE "public"."purchase_receipt" TO "authenticated";
GRANT ALL ON TABLE "public"."purchase_receipt" TO "service_role";



GRANT ALL ON TABLE "public"."purchase_receipt_line" TO "anon";
GRANT ALL ON TABLE "public"."purchase_receipt_line" TO "authenticated";
GRANT ALL ON TABLE "public"."purchase_receipt_line" TO "service_role";



GRANT ALL ON TABLE "public"."recipe" TO "anon";
GRANT ALL ON TABLE "public"."recipe" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_component" TO "anon";
GRANT ALL ON TABLE "public"."recipe_component" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_component" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_media" TO "anon";
GRANT ALL ON TABLE "public"."recipe_media" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_media" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_step" TO "anon";
GRANT ALL ON TABLE "public"."recipe_step" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_step" TO "service_role";



GRANT ALL ON TABLE "public"."role" TO "anon";
GRANT ALL ON TABLE "public"."role" TO "authenticated";
GRANT ALL ON TABLE "public"."role" TO "service_role";



GRANT ALL ON TABLE "public"."role_permission" TO "anon";
GRANT ALL ON TABLE "public"."role_permission" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permission" TO "service_role";



GRANT ALL ON TABLE "public"."stock_movement" TO "anon";
GRANT ALL ON TABLE "public"."stock_movement" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_movement" TO "service_role";



GRANT ALL ON TABLE "public"."supplier" TO "anon";
GRANT ALL ON TABLE "public"."supplier" TO "authenticated";
GRANT ALL ON TABLE "public"."supplier" TO "service_role";



GRANT ALL ON TABLE "public"."supplier_offer" TO "anon";
GRANT ALL ON TABLE "public"."supplier_offer" TO "authenticated";
GRANT ALL ON TABLE "public"."supplier_offer" TO "service_role";



GRANT ALL ON TABLE "public"."supplier_offer_price" TO "anon";
GRANT ALL ON TABLE "public"."supplier_offer_price" TO "authenticated";
GRANT ALL ON TABLE "public"."supplier_offer_price" TO "service_role";



GRANT ALL ON TABLE "public"."unit" TO "anon";
GRANT ALL ON TABLE "public"."unit" TO "authenticated";
GRANT ALL ON TABLE "public"."unit" TO "service_role";



GRANT ALL ON TABLE "public"."user_role" TO "anon";
GRANT ALL ON TABLE "public"."user_role" TO "authenticated";
GRANT ALL ON TABLE "public"."user_role" TO "service_role";



GRANT ALL ON TABLE "public"."v_latest_purchase_cost" TO "anon";
GRANT ALL ON TABLE "public"."v_latest_purchase_cost" TO "authenticated";
GRANT ALL ON TABLE "public"."v_latest_purchase_cost" TO "service_role";



GRANT ALL ON TABLE "public"."v_recipe_standard_cost" TO "anon";
GRANT ALL ON TABLE "public"."v_recipe_standard_cost" TO "authenticated";
GRANT ALL ON TABLE "public"."v_recipe_standard_cost" TO "service_role";



GRANT ALL ON TABLE "public"."v_stock_delta" TO "anon";
GRANT ALL ON TABLE "public"."v_stock_delta" TO "authenticated";
GRANT ALL ON TABLE "public"."v_stock_delta" TO "service_role";



GRANT ALL ON TABLE "public"."v_stock_snapshot" TO "anon";
GRANT ALL ON TABLE "public"."v_stock_snapshot" TO "authenticated";
GRANT ALL ON TABLE "public"."v_stock_snapshot" TO "service_role";



GRANT ALL ON TABLE "public"."v_user_permissions" TO "anon";
GRANT ALL ON TABLE "public"."v_user_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."v_user_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."v_waste_daily" TO "anon";
GRANT ALL ON TABLE "public"."v_waste_daily" TO "authenticated";
GRANT ALL ON TABLE "public"."v_waste_daily" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";








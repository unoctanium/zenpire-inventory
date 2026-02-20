drop extension if exists "pg_net";


  create table "public"."app_user" (
    "id" uuid not null default gen_random_uuid(),
    "auth_user_id" uuid not null,
    "email" text not null,
    "display_name" text,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."app_user" enable row level security;


  create table "public"."ingredient" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "default_unit_id" uuid not null,
    "kind" text not null,
    "produced_by_recipe_id" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "standard_unit_cost" numeric(18,6),
    "standard_cost_currency" text not null default 'EUR'::text,
    "standard_cost_updated_at" timestamp with time zone
      );


alter table "public"."ingredient" enable row level security;


  create table "public"."ingredient_stock" (
    "ingredient_id" uuid not null,
    "on_hand_quantity" numeric(18,6) not null default 0,
    "planned_quantity" numeric(18,6) not null default 0,
    "unit_id" uuid not null,
    "green_min_delta" numeric(18,6) not null default 0,
    "yellow_min_delta" numeric(18,6) not null default 0,
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."ingredient_stock" enable row level security;


  create table "public"."ingredient_supplier_offer" (
    "ingredient_id" uuid not null,
    "supplier_offer_id" uuid not null,
    "priority" integer,
    "is_preferred" boolean not null default false
      );


alter table "public"."ingredient_supplier_offer" enable row level security;


  create table "public"."permission" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "description" text
      );


alter table "public"."permission" enable row level security;


  create table "public"."production_batch" (
    "id" uuid not null default gen_random_uuid(),
    "recipe_id" uuid not null,
    "produced_quantity" numeric(18,6) not null,
    "unit_id" uuid not null,
    "produced_at" timestamp with time zone not null default now(),
    "created_by_user_id" uuid not null,
    "note" text,
    "status" text not null default 'posted'::text
      );


alter table "public"."production_batch" enable row level security;


  create table "public"."purchase_receipt" (
    "id" uuid not null default gen_random_uuid(),
    "supplier_id" uuid not null,
    "received_at" timestamp with time zone not null default now(),
    "invoice_no" text,
    "note" text,
    "created_by_user_id" uuid not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."purchase_receipt" enable row level security;


  create table "public"."purchase_receipt_line" (
    "id" uuid not null default gen_random_uuid(),
    "purchase_receipt_id" uuid not null,
    "ingredient_id" uuid not null,
    "supplier_offer_id" uuid not null,
    "packs_received" numeric(18,6) not null,
    "pack_quantity_snapshot" numeric(18,6) not null,
    "pack_unit_snapshot_id" uuid not null,
    "price_per_pack_snapshot" numeric(18,6) not null,
    "currency" text not null default 'EUR'::text,
    "stock_movement_id" uuid not null,
    "note" text
      );


alter table "public"."purchase_receipt_line" enable row level security;


  create table "public"."recipe" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "output_quantity" numeric(18,6) not null default 1,
    "output_unit_id" uuid not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."recipe" enable row level security;


  create table "public"."recipe_component" (
    "recipe_id" uuid not null,
    "ingredient_id" uuid not null,
    "quantity" numeric(18,6) not null,
    "unit_id" uuid not null
      );


alter table "public"."recipe_component" enable row level security;


  create table "public"."recipe_media" (
    "id" uuid not null default gen_random_uuid(),
    "recipe_id" uuid not null,
    "storage_path" text not null,
    "sort_order" integer not null default 0
      );


alter table "public"."recipe_media" enable row level security;


  create table "public"."recipe_step" (
    "recipe_id" uuid not null,
    "step_no" integer not null,
    "instruction_text" text not null
      );


alter table "public"."recipe_step" enable row level security;


  create table "public"."role" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "name" text not null
      );


alter table "public"."role" enable row level security;


  create table "public"."role_permission" (
    "role_id" uuid not null,
    "permission_id" uuid not null
      );


alter table "public"."role_permission" enable row level security;


  create table "public"."stock_movement" (
    "id" uuid not null default gen_random_uuid(),
    "ingredient_id" uuid not null,
    "movement_type" text not null,
    "quantity" numeric(18,6) not null,
    "unit_id" uuid not null,
    "occurred_at" timestamp with time zone not null default now(),
    "unit_cost_snapshot" numeric(18,6),
    "currency" text,
    "reference_type" text,
    "reference_id" uuid,
    "note" text,
    "created_by_user_id" uuid not null
      );


alter table "public"."stock_movement" enable row level security;


  create table "public"."supplier" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "contact_email" text,
    "contact_phone" text,
    "note" text
      );


alter table "public"."supplier" enable row level security;


  create table "public"."supplier_offer" (
    "id" uuid not null default gen_random_uuid(),
    "supplier_id" uuid not null,
    "offer_name" text not null,
    "supplier_article_number" text,
    "pack_quantity" numeric(18,6) not null,
    "pack_unit_id" uuid not null,
    "is_active" boolean not null default true,
    "active_from" date,
    "active_to" date,
    "notes" text
      );


alter table "public"."supplier_offer" enable row level security;


  create table "public"."supplier_offer_price" (
    "id" uuid not null default gen_random_uuid(),
    "supplier_offer_id" uuid not null,
    "valid_from" date not null,
    "valid_to" date,
    "currency" text not null default 'EUR'::text,
    "price_per_pack" numeric(18,6) not null
      );


alter table "public"."supplier_offer_price" enable row level security;


  create table "public"."unit" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "name" text not null,
    "unit_type" text not null
      );


alter table "public"."unit" enable row level security;


  create table "public"."user_role" (
    "user_id" uuid not null,
    "role_id" uuid not null
      );


alter table "public"."user_role" enable row level security;

CREATE UNIQUE INDEX app_user_auth_user_id_key ON public.app_user USING btree (auth_user_id);

CREATE UNIQUE INDEX app_user_pkey ON public.app_user USING btree (id);

CREATE UNIQUE INDEX ingredient_name_key ON public.ingredient USING btree (name);

CREATE UNIQUE INDEX ingredient_pkey ON public.ingredient USING btree (id);

CREATE UNIQUE INDEX ingredient_stock_pkey ON public.ingredient_stock USING btree (ingredient_id);

CREATE UNIQUE INDEX ingredient_supplier_offer_pkey ON public.ingredient_supplier_offer USING btree (ingredient_id, supplier_offer_id);

CREATE INDEX ix_ing_offer_ing ON public.ingredient_supplier_offer USING btree (ingredient_id);

CREATE INDEX ix_ing_offer_offer ON public.ingredient_supplier_offer USING btree (supplier_offer_id);

CREATE INDEX ix_offer_price_offer_from ON public.supplier_offer_price USING btree (supplier_offer_id, valid_from DESC);

CREATE INDEX ix_production_batch_time ON public.production_batch USING btree (produced_at DESC);

CREATE INDEX ix_purchase_line_receipt ON public.purchase_receipt_line USING btree (purchase_receipt_id);

CREATE INDEX ix_purchase_receipt_supplier_time ON public.purchase_receipt USING btree (supplier_id, received_at DESC);

CREATE INDEX ix_recipe_media_recipe ON public.recipe_media USING btree (recipe_id, sort_order);

CREATE INDEX ix_stock_movement_ing_time ON public.stock_movement USING btree (ingredient_id, occurred_at DESC);

CREATE INDEX ix_stock_movement_type_time ON public.stock_movement USING btree (movement_type, occurred_at DESC);

CREATE INDEX ix_supplier_offer_active ON public.supplier_offer USING btree (is_active, active_to);

CREATE INDEX ix_supplier_offer_supplier ON public.supplier_offer USING btree (supplier_id);

CREATE UNIQUE INDEX permission_code_key ON public.permission USING btree (code);

CREATE UNIQUE INDEX permission_pkey ON public.permission USING btree (id);

CREATE UNIQUE INDEX production_batch_pkey ON public.production_batch USING btree (id);

CREATE UNIQUE INDEX purchase_receipt_line_pkey ON public.purchase_receipt_line USING btree (id);

CREATE UNIQUE INDEX purchase_receipt_pkey ON public.purchase_receipt USING btree (id);

CREATE UNIQUE INDEX recipe_component_pkey ON public.recipe_component USING btree (recipe_id, ingredient_id);

CREATE UNIQUE INDEX recipe_media_pkey ON public.recipe_media USING btree (id);

CREATE UNIQUE INDEX recipe_pkey ON public.recipe USING btree (id);

CREATE UNIQUE INDEX recipe_step_pkey ON public.recipe_step USING btree (recipe_id, step_no);

CREATE UNIQUE INDEX role_code_key ON public.role USING btree (code);

CREATE UNIQUE INDEX role_permission_pkey ON public.role_permission USING btree (role_id, permission_id);

CREATE UNIQUE INDEX role_pkey ON public.role USING btree (id);

CREATE UNIQUE INDEX stock_movement_pkey ON public.stock_movement USING btree (id);

CREATE UNIQUE INDEX supplier_name_key ON public.supplier USING btree (name);

CREATE UNIQUE INDEX supplier_offer_pkey ON public.supplier_offer USING btree (id);

CREATE UNIQUE INDEX supplier_offer_price_pkey ON public.supplier_offer_price USING btree (id);

CREATE UNIQUE INDEX supplier_pkey ON public.supplier USING btree (id);

CREATE UNIQUE INDEX unit_code_key ON public.unit USING btree (code);

CREATE UNIQUE INDEX unit_pkey ON public.unit USING btree (id);

CREATE UNIQUE INDEX user_role_pkey ON public.user_role USING btree (user_id, role_id);

alter table "public"."app_user" add constraint "app_user_pkey" PRIMARY KEY using index "app_user_pkey";

alter table "public"."ingredient" add constraint "ingredient_pkey" PRIMARY KEY using index "ingredient_pkey";

alter table "public"."ingredient_stock" add constraint "ingredient_stock_pkey" PRIMARY KEY using index "ingredient_stock_pkey";

alter table "public"."ingredient_supplier_offer" add constraint "ingredient_supplier_offer_pkey" PRIMARY KEY using index "ingredient_supplier_offer_pkey";

alter table "public"."permission" add constraint "permission_pkey" PRIMARY KEY using index "permission_pkey";

alter table "public"."production_batch" add constraint "production_batch_pkey" PRIMARY KEY using index "production_batch_pkey";

alter table "public"."purchase_receipt" add constraint "purchase_receipt_pkey" PRIMARY KEY using index "purchase_receipt_pkey";

alter table "public"."purchase_receipt_line" add constraint "purchase_receipt_line_pkey" PRIMARY KEY using index "purchase_receipt_line_pkey";

alter table "public"."recipe" add constraint "recipe_pkey" PRIMARY KEY using index "recipe_pkey";

alter table "public"."recipe_component" add constraint "recipe_component_pkey" PRIMARY KEY using index "recipe_component_pkey";

alter table "public"."recipe_media" add constraint "recipe_media_pkey" PRIMARY KEY using index "recipe_media_pkey";

alter table "public"."recipe_step" add constraint "recipe_step_pkey" PRIMARY KEY using index "recipe_step_pkey";

alter table "public"."role" add constraint "role_pkey" PRIMARY KEY using index "role_pkey";

alter table "public"."role_permission" add constraint "role_permission_pkey" PRIMARY KEY using index "role_permission_pkey";

alter table "public"."stock_movement" add constraint "stock_movement_pkey" PRIMARY KEY using index "stock_movement_pkey";

alter table "public"."supplier" add constraint "supplier_pkey" PRIMARY KEY using index "supplier_pkey";

alter table "public"."supplier_offer" add constraint "supplier_offer_pkey" PRIMARY KEY using index "supplier_offer_pkey";

alter table "public"."supplier_offer_price" add constraint "supplier_offer_price_pkey" PRIMARY KEY using index "supplier_offer_price_pkey";

alter table "public"."unit" add constraint "unit_pkey" PRIMARY KEY using index "unit_pkey";

alter table "public"."user_role" add constraint "user_role_pkey" PRIMARY KEY using index "user_role_pkey";

alter table "public"."app_user" add constraint "app_user_auth_user_id_key" UNIQUE using index "app_user_auth_user_id_key";

alter table "public"."ingredient" add constraint "ck_ingredient_kind" CHECK ((((kind = 'purchased'::text) AND (produced_by_recipe_id IS NULL)) OR ((kind = 'produced'::text) AND (produced_by_recipe_id IS NOT NULL)))) not valid;

alter table "public"."ingredient" validate constraint "ck_ingredient_kind";

alter table "public"."ingredient" add constraint "ingredient_default_unit_id_fkey" FOREIGN KEY (default_unit_id) REFERENCES public.unit(id) not valid;

alter table "public"."ingredient" validate constraint "ingredient_default_unit_id_fkey";

alter table "public"."ingredient" add constraint "ingredient_kind_check" CHECK ((kind = ANY (ARRAY['purchased'::text, 'produced'::text]))) not valid;

alter table "public"."ingredient" validate constraint "ingredient_kind_check";

alter table "public"."ingredient" add constraint "ingredient_name_key" UNIQUE using index "ingredient_name_key";

alter table "public"."ingredient" add constraint "ingredient_produced_by_recipe_id_fkey" FOREIGN KEY (produced_by_recipe_id) REFERENCES public.recipe(id) not valid;

alter table "public"."ingredient" validate constraint "ingredient_produced_by_recipe_id_fkey";

alter table "public"."ingredient_stock" add constraint "ingredient_stock_ingredient_id_fkey" FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id) ON DELETE CASCADE not valid;

alter table "public"."ingredient_stock" validate constraint "ingredient_stock_ingredient_id_fkey";

alter table "public"."ingredient_stock" add constraint "ingredient_stock_unit_id_fkey" FOREIGN KEY (unit_id) REFERENCES public.unit(id) not valid;

alter table "public"."ingredient_stock" validate constraint "ingredient_stock_unit_id_fkey";

alter table "public"."ingredient_supplier_offer" add constraint "ingredient_supplier_offer_ingredient_id_fkey" FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id) ON DELETE CASCADE not valid;

alter table "public"."ingredient_supplier_offer" validate constraint "ingredient_supplier_offer_ingredient_id_fkey";

alter table "public"."ingredient_supplier_offer" add constraint "ingredient_supplier_offer_supplier_offer_id_fkey" FOREIGN KEY (supplier_offer_id) REFERENCES public.supplier_offer(id) ON DELETE CASCADE not valid;

alter table "public"."ingredient_supplier_offer" validate constraint "ingredient_supplier_offer_supplier_offer_id_fkey";

alter table "public"."permission" add constraint "permission_code_key" UNIQUE using index "permission_code_key";

alter table "public"."production_batch" add constraint "production_batch_created_by_user_id_fkey" FOREIGN KEY (created_by_user_id) REFERENCES public.app_user(id) not valid;

alter table "public"."production_batch" validate constraint "production_batch_created_by_user_id_fkey";

alter table "public"."production_batch" add constraint "production_batch_produced_quantity_check" CHECK ((produced_quantity > (0)::numeric)) not valid;

alter table "public"."production_batch" validate constraint "production_batch_produced_quantity_check";

alter table "public"."production_batch" add constraint "production_batch_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES public.recipe(id) not valid;

alter table "public"."production_batch" validate constraint "production_batch_recipe_id_fkey";

alter table "public"."production_batch" add constraint "production_batch_status_check" CHECK ((status = ANY (ARRAY['posted'::text, 'voided'::text]))) not valid;

alter table "public"."production_batch" validate constraint "production_batch_status_check";

alter table "public"."production_batch" add constraint "production_batch_unit_id_fkey" FOREIGN KEY (unit_id) REFERENCES public.unit(id) not valid;

alter table "public"."production_batch" validate constraint "production_batch_unit_id_fkey";

alter table "public"."purchase_receipt" add constraint "purchase_receipt_created_by_user_id_fkey" FOREIGN KEY (created_by_user_id) REFERENCES public.app_user(id) not valid;

alter table "public"."purchase_receipt" validate constraint "purchase_receipt_created_by_user_id_fkey";

alter table "public"."purchase_receipt" add constraint "purchase_receipt_supplier_id_fkey" FOREIGN KEY (supplier_id) REFERENCES public.supplier(id) not valid;

alter table "public"."purchase_receipt" validate constraint "purchase_receipt_supplier_id_fkey";

alter table "public"."purchase_receipt_line" add constraint "purchase_receipt_line_ingredient_id_fkey" FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id) not valid;

alter table "public"."purchase_receipt_line" validate constraint "purchase_receipt_line_ingredient_id_fkey";

alter table "public"."purchase_receipt_line" add constraint "purchase_receipt_line_pack_quantity_snapshot_check" CHECK ((pack_quantity_snapshot > (0)::numeric)) not valid;

alter table "public"."purchase_receipt_line" validate constraint "purchase_receipt_line_pack_quantity_snapshot_check";

alter table "public"."purchase_receipt_line" add constraint "purchase_receipt_line_pack_unit_snapshot_id_fkey" FOREIGN KEY (pack_unit_snapshot_id) REFERENCES public.unit(id) not valid;

alter table "public"."purchase_receipt_line" validate constraint "purchase_receipt_line_pack_unit_snapshot_id_fkey";

alter table "public"."purchase_receipt_line" add constraint "purchase_receipt_line_packs_received_check" CHECK ((packs_received > (0)::numeric)) not valid;

alter table "public"."purchase_receipt_line" validate constraint "purchase_receipt_line_packs_received_check";

alter table "public"."purchase_receipt_line" add constraint "purchase_receipt_line_price_per_pack_snapshot_check" CHECK ((price_per_pack_snapshot >= (0)::numeric)) not valid;

alter table "public"."purchase_receipt_line" validate constraint "purchase_receipt_line_price_per_pack_snapshot_check";

alter table "public"."purchase_receipt_line" add constraint "purchase_receipt_line_purchase_receipt_id_fkey" FOREIGN KEY (purchase_receipt_id) REFERENCES public.purchase_receipt(id) ON DELETE CASCADE not valid;

alter table "public"."purchase_receipt_line" validate constraint "purchase_receipt_line_purchase_receipt_id_fkey";

alter table "public"."purchase_receipt_line" add constraint "purchase_receipt_line_stock_movement_id_fkey" FOREIGN KEY (stock_movement_id) REFERENCES public.stock_movement(id) not valid;

alter table "public"."purchase_receipt_line" validate constraint "purchase_receipt_line_stock_movement_id_fkey";

alter table "public"."purchase_receipt_line" add constraint "purchase_receipt_line_supplier_offer_id_fkey" FOREIGN KEY (supplier_offer_id) REFERENCES public.supplier_offer(id) not valid;

alter table "public"."purchase_receipt_line" validate constraint "purchase_receipt_line_supplier_offer_id_fkey";

alter table "public"."recipe" add constraint "recipe_output_unit_id_fkey" FOREIGN KEY (output_unit_id) REFERENCES public.unit(id) not valid;

alter table "public"."recipe" validate constraint "recipe_output_unit_id_fkey";

alter table "public"."recipe_component" add constraint "recipe_component_ingredient_id_fkey" FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id) not valid;

alter table "public"."recipe_component" validate constraint "recipe_component_ingredient_id_fkey";

alter table "public"."recipe_component" add constraint "recipe_component_quantity_check" CHECK ((quantity > (0)::numeric)) not valid;

alter table "public"."recipe_component" validate constraint "recipe_component_quantity_check";

alter table "public"."recipe_component" add constraint "recipe_component_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES public.recipe(id) ON DELETE CASCADE not valid;

alter table "public"."recipe_component" validate constraint "recipe_component_recipe_id_fkey";

alter table "public"."recipe_component" add constraint "recipe_component_unit_id_fkey" FOREIGN KEY (unit_id) REFERENCES public.unit(id) not valid;

alter table "public"."recipe_component" validate constraint "recipe_component_unit_id_fkey";

alter table "public"."recipe_media" add constraint "recipe_media_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES public.recipe(id) ON DELETE CASCADE not valid;

alter table "public"."recipe_media" validate constraint "recipe_media_recipe_id_fkey";

alter table "public"."recipe_step" add constraint "recipe_step_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES public.recipe(id) ON DELETE CASCADE not valid;

alter table "public"."recipe_step" validate constraint "recipe_step_recipe_id_fkey";

alter table "public"."recipe_step" add constraint "recipe_step_step_no_check" CHECK ((step_no > 0)) not valid;

alter table "public"."recipe_step" validate constraint "recipe_step_step_no_check";

alter table "public"."role" add constraint "role_code_key" UNIQUE using index "role_code_key";

alter table "public"."role_permission" add constraint "role_permission_permission_id_fkey" FOREIGN KEY (permission_id) REFERENCES public.permission(id) ON DELETE CASCADE not valid;

alter table "public"."role_permission" validate constraint "role_permission_permission_id_fkey";

alter table "public"."role_permission" add constraint "role_permission_role_id_fkey" FOREIGN KEY (role_id) REFERENCES public.role(id) ON DELETE CASCADE not valid;

alter table "public"."role_permission" validate constraint "role_permission_role_id_fkey";

alter table "public"."stock_movement" add constraint "ck_waste_cost_required" CHECK (((movement_type <> 'waste'::text) OR (unit_cost_snapshot IS NOT NULL))) not valid;

alter table "public"."stock_movement" validate constraint "ck_waste_cost_required";

alter table "public"."stock_movement" add constraint "stock_movement_created_by_user_id_fkey" FOREIGN KEY (created_by_user_id) REFERENCES public.app_user(id) not valid;

alter table "public"."stock_movement" validate constraint "stock_movement_created_by_user_id_fkey";

alter table "public"."stock_movement" add constraint "stock_movement_ingredient_id_fkey" FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id) not valid;

alter table "public"."stock_movement" validate constraint "stock_movement_ingredient_id_fkey";

alter table "public"."stock_movement" add constraint "stock_movement_movement_type_check" CHECK ((movement_type = ANY (ARRAY['purchase'::text, 'produce_in'::text, 'produce_out'::text, 'waste'::text, 'adjust'::text, 'consume'::text]))) not valid;

alter table "public"."stock_movement" validate constraint "stock_movement_movement_type_check";

alter table "public"."stock_movement" add constraint "stock_movement_unit_id_fkey" FOREIGN KEY (unit_id) REFERENCES public.unit(id) not valid;

alter table "public"."stock_movement" validate constraint "stock_movement_unit_id_fkey";

alter table "public"."supplier" add constraint "supplier_name_key" UNIQUE using index "supplier_name_key";

alter table "public"."supplier_offer" add constraint "supplier_offer_pack_quantity_check" CHECK ((pack_quantity > (0)::numeric)) not valid;

alter table "public"."supplier_offer" validate constraint "supplier_offer_pack_quantity_check";

alter table "public"."supplier_offer" add constraint "supplier_offer_pack_unit_id_fkey" FOREIGN KEY (pack_unit_id) REFERENCES public.unit(id) not valid;

alter table "public"."supplier_offer" validate constraint "supplier_offer_pack_unit_id_fkey";

alter table "public"."supplier_offer" add constraint "supplier_offer_supplier_id_fkey" FOREIGN KEY (supplier_id) REFERENCES public.supplier(id) ON DELETE CASCADE not valid;

alter table "public"."supplier_offer" validate constraint "supplier_offer_supplier_id_fkey";

alter table "public"."supplier_offer_price" add constraint "ck_price_validity" CHECK (((valid_to IS NULL) OR (valid_to >= valid_from))) not valid;

alter table "public"."supplier_offer_price" validate constraint "ck_price_validity";

alter table "public"."supplier_offer_price" add constraint "supplier_offer_price_price_per_pack_check" CHECK ((price_per_pack >= (0)::numeric)) not valid;

alter table "public"."supplier_offer_price" validate constraint "supplier_offer_price_price_per_pack_check";

alter table "public"."supplier_offer_price" add constraint "supplier_offer_price_supplier_offer_id_fkey" FOREIGN KEY (supplier_offer_id) REFERENCES public.supplier_offer(id) ON DELETE CASCADE not valid;

alter table "public"."supplier_offer_price" validate constraint "supplier_offer_price_supplier_offer_id_fkey";

alter table "public"."unit" add constraint "unit_code_key" UNIQUE using index "unit_code_key";

alter table "public"."unit" add constraint "unit_unit_type_check" CHECK ((unit_type = ANY (ARRAY['mass'::text, 'volume'::text, 'count'::text]))) not valid;

alter table "public"."unit" validate constraint "unit_unit_type_check";

alter table "public"."user_role" add constraint "user_role_role_id_fkey" FOREIGN KEY (role_id) REFERENCES public.role(id) ON DELETE CASCADE not valid;

alter table "public"."user_role" validate constraint "user_role_role_id_fkey";

alter table "public"."user_role" add constraint "user_role_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE not valid;

alter table "public"."user_role" validate constraint "user_role_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.fn_ensure_ingredient_stock(p_ingredient_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.fn_get_current_offer_price(p_offer_id uuid, p_at_date date)
 RETURNS TABLE(currency text, price_per_pack numeric, valid_from date)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.fn_post_adjustment(p_payload jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.fn_post_production_batch(p_payload jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.fn_post_purchase_receipt(p_payload jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.fn_post_waste(p_payload jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$
;

create or replace view "public"."v_latest_purchase_cost" as  SELECT DISTINCT ON (ingredient_id) ingredient_id,
    unit_cost_snapshot AS latest_unit_cost,
    currency,
    occurred_at AS last_purchase_at
   FROM public.stock_movement sm
  WHERE ((movement_type = 'purchase'::text) AND (unit_cost_snapshot IS NOT NULL))
  ORDER BY ingredient_id, occurred_at DESC;


create or replace view "public"."v_recipe_standard_cost" as  SELECT r.id AS recipe_id,
    r.name AS recipe_name,
    COALESCE(sum((rc.quantity * COALESCE(i.standard_unit_cost, (0)::numeric))), (0)::numeric) AS standard_cost,
    'EUR'::text AS currency
   FROM ((public.recipe r
     LEFT JOIN public.recipe_component rc ON ((rc.recipe_id = r.id)))
     LEFT JOIN public.ingredient i ON ((i.id = rc.ingredient_id)))
  GROUP BY r.id, r.name;


create or replace view "public"."v_stock_delta" as  SELECT i.id AS ingredient_id,
    i.name AS ingredient_name,
    u.code AS unit_code,
    s.planned_quantity,
    s.on_hand_quantity,
    (s.planned_quantity - s.on_hand_quantity) AS delta,
        CASE
            WHEN ((s.planned_quantity - s.on_hand_quantity) <= s.green_min_delta) THEN 'green'::text
            WHEN ((s.planned_quantity - s.on_hand_quantity) <= s.yellow_min_delta) THEN 'yellow'::text
            ELSE 'red'::text
        END AS status,
    s.updated_at AS planned_updated_at
   FROM ((public.ingredient_stock s
     JOIN public.ingredient i ON ((i.id = s.ingredient_id)))
     JOIN public.unit u ON ((u.id = s.unit_id)));


create or replace view "public"."v_stock_snapshot" as  SELECT i.id AS ingredient_id,
    i.name AS ingredient_name,
    u.code AS unit_code,
    s.on_hand_quantity,
    COALESCE(c.latest_unit_cost, (0)::numeric) AS estimated_unit_cost,
    COALESCE(c.currency, 'EUR'::text) AS currency,
    (s.on_hand_quantity * COALESCE(c.latest_unit_cost, (0)::numeric)) AS stock_value,
    c.last_purchase_at
   FROM (((public.ingredient_stock s
     JOIN public.ingredient i ON ((i.id = s.ingredient_id)))
     JOIN public.unit u ON ((u.id = s.unit_id)))
     LEFT JOIN public.v_latest_purchase_cost c ON ((c.ingredient_id = s.ingredient_id)));


create or replace view "public"."v_user_permissions" as  SELECT au.id AS app_user_id,
    au.auth_user_id,
    p.code AS permission_code
   FROM (((public.app_user au
     JOIN public.user_role ur ON ((ur.user_id = au.id)))
     JOIN public.role_permission rp ON ((rp.role_id = ur.role_id)))
     JOIN public.permission p ON ((p.id = rp.permission_id)));


create or replace view "public"."v_waste_daily" as  SELECT date_trunc('day'::text, sm.occurred_at) AS day,
    i.id AS ingredient_id,
    i.name AS ingredient_name,
    u.code AS unit_code,
    sum(abs(sm.quantity)) AS waste_qty,
    COALESCE(sm.currency, 'EUR'::text) AS currency,
    sum((abs(sm.quantity) * sm.unit_cost_snapshot)) AS waste_value
   FROM ((public.stock_movement sm
     JOIN public.ingredient i ON ((i.id = sm.ingredient_id)))
     JOIN public.unit u ON ((u.id = sm.unit_id)))
  WHERE (sm.movement_type = 'waste'::text)
  GROUP BY (date_trunc('day'::text, sm.occurred_at)), i.id, i.name, u.code, COALESCE(sm.currency, 'EUR'::text);


grant delete on table "public"."app_user" to "anon";

grant insert on table "public"."app_user" to "anon";

grant references on table "public"."app_user" to "anon";

grant select on table "public"."app_user" to "anon";

grant trigger on table "public"."app_user" to "anon";

grant truncate on table "public"."app_user" to "anon";

grant update on table "public"."app_user" to "anon";

grant delete on table "public"."app_user" to "authenticated";

grant insert on table "public"."app_user" to "authenticated";

grant references on table "public"."app_user" to "authenticated";

grant select on table "public"."app_user" to "authenticated";

grant trigger on table "public"."app_user" to "authenticated";

grant truncate on table "public"."app_user" to "authenticated";

grant update on table "public"."app_user" to "authenticated";

grant delete on table "public"."app_user" to "service_role";

grant insert on table "public"."app_user" to "service_role";

grant references on table "public"."app_user" to "service_role";

grant select on table "public"."app_user" to "service_role";

grant trigger on table "public"."app_user" to "service_role";

grant truncate on table "public"."app_user" to "service_role";

grant update on table "public"."app_user" to "service_role";

grant delete on table "public"."ingredient" to "anon";

grant insert on table "public"."ingredient" to "anon";

grant references on table "public"."ingredient" to "anon";

grant select on table "public"."ingredient" to "anon";

grant trigger on table "public"."ingredient" to "anon";

grant truncate on table "public"."ingredient" to "anon";

grant update on table "public"."ingredient" to "anon";

grant delete on table "public"."ingredient" to "authenticated";

grant insert on table "public"."ingredient" to "authenticated";

grant references on table "public"."ingredient" to "authenticated";

grant select on table "public"."ingredient" to "authenticated";

grant trigger on table "public"."ingredient" to "authenticated";

grant truncate on table "public"."ingredient" to "authenticated";

grant update on table "public"."ingredient" to "authenticated";

grant delete on table "public"."ingredient" to "service_role";

grant insert on table "public"."ingredient" to "service_role";

grant references on table "public"."ingredient" to "service_role";

grant select on table "public"."ingredient" to "service_role";

grant trigger on table "public"."ingredient" to "service_role";

grant truncate on table "public"."ingredient" to "service_role";

grant update on table "public"."ingredient" to "service_role";

grant delete on table "public"."ingredient_stock" to "anon";

grant insert on table "public"."ingredient_stock" to "anon";

grant references on table "public"."ingredient_stock" to "anon";

grant select on table "public"."ingredient_stock" to "anon";

grant trigger on table "public"."ingredient_stock" to "anon";

grant truncate on table "public"."ingredient_stock" to "anon";

grant update on table "public"."ingredient_stock" to "anon";

grant delete on table "public"."ingredient_stock" to "authenticated";

grant insert on table "public"."ingredient_stock" to "authenticated";

grant references on table "public"."ingredient_stock" to "authenticated";

grant select on table "public"."ingredient_stock" to "authenticated";

grant trigger on table "public"."ingredient_stock" to "authenticated";

grant truncate on table "public"."ingredient_stock" to "authenticated";

grant update on table "public"."ingredient_stock" to "authenticated";

grant delete on table "public"."ingredient_stock" to "service_role";

grant insert on table "public"."ingredient_stock" to "service_role";

grant references on table "public"."ingredient_stock" to "service_role";

grant select on table "public"."ingredient_stock" to "service_role";

grant trigger on table "public"."ingredient_stock" to "service_role";

grant truncate on table "public"."ingredient_stock" to "service_role";

grant update on table "public"."ingredient_stock" to "service_role";

grant delete on table "public"."ingredient_supplier_offer" to "anon";

grant insert on table "public"."ingredient_supplier_offer" to "anon";

grant references on table "public"."ingredient_supplier_offer" to "anon";

grant select on table "public"."ingredient_supplier_offer" to "anon";

grant trigger on table "public"."ingredient_supplier_offer" to "anon";

grant truncate on table "public"."ingredient_supplier_offer" to "anon";

grant update on table "public"."ingredient_supplier_offer" to "anon";

grant delete on table "public"."ingredient_supplier_offer" to "authenticated";

grant insert on table "public"."ingredient_supplier_offer" to "authenticated";

grant references on table "public"."ingredient_supplier_offer" to "authenticated";

grant select on table "public"."ingredient_supplier_offer" to "authenticated";

grant trigger on table "public"."ingredient_supplier_offer" to "authenticated";

grant truncate on table "public"."ingredient_supplier_offer" to "authenticated";

grant update on table "public"."ingredient_supplier_offer" to "authenticated";

grant delete on table "public"."ingredient_supplier_offer" to "service_role";

grant insert on table "public"."ingredient_supplier_offer" to "service_role";

grant references on table "public"."ingredient_supplier_offer" to "service_role";

grant select on table "public"."ingredient_supplier_offer" to "service_role";

grant trigger on table "public"."ingredient_supplier_offer" to "service_role";

grant truncate on table "public"."ingredient_supplier_offer" to "service_role";

grant update on table "public"."ingredient_supplier_offer" to "service_role";

grant delete on table "public"."permission" to "anon";

grant insert on table "public"."permission" to "anon";

grant references on table "public"."permission" to "anon";

grant select on table "public"."permission" to "anon";

grant trigger on table "public"."permission" to "anon";

grant truncate on table "public"."permission" to "anon";

grant update on table "public"."permission" to "anon";

grant delete on table "public"."permission" to "authenticated";

grant insert on table "public"."permission" to "authenticated";

grant references on table "public"."permission" to "authenticated";

grant select on table "public"."permission" to "authenticated";

grant trigger on table "public"."permission" to "authenticated";

grant truncate on table "public"."permission" to "authenticated";

grant update on table "public"."permission" to "authenticated";

grant delete on table "public"."permission" to "service_role";

grant insert on table "public"."permission" to "service_role";

grant references on table "public"."permission" to "service_role";

grant select on table "public"."permission" to "service_role";

grant trigger on table "public"."permission" to "service_role";

grant truncate on table "public"."permission" to "service_role";

grant update on table "public"."permission" to "service_role";

grant delete on table "public"."production_batch" to "anon";

grant insert on table "public"."production_batch" to "anon";

grant references on table "public"."production_batch" to "anon";

grant select on table "public"."production_batch" to "anon";

grant trigger on table "public"."production_batch" to "anon";

grant truncate on table "public"."production_batch" to "anon";

grant update on table "public"."production_batch" to "anon";

grant delete on table "public"."production_batch" to "authenticated";

grant insert on table "public"."production_batch" to "authenticated";

grant references on table "public"."production_batch" to "authenticated";

grant select on table "public"."production_batch" to "authenticated";

grant trigger on table "public"."production_batch" to "authenticated";

grant truncate on table "public"."production_batch" to "authenticated";

grant update on table "public"."production_batch" to "authenticated";

grant delete on table "public"."production_batch" to "service_role";

grant insert on table "public"."production_batch" to "service_role";

grant references on table "public"."production_batch" to "service_role";

grant select on table "public"."production_batch" to "service_role";

grant trigger on table "public"."production_batch" to "service_role";

grant truncate on table "public"."production_batch" to "service_role";

grant update on table "public"."production_batch" to "service_role";

grant delete on table "public"."purchase_receipt" to "anon";

grant insert on table "public"."purchase_receipt" to "anon";

grant references on table "public"."purchase_receipt" to "anon";

grant select on table "public"."purchase_receipt" to "anon";

grant trigger on table "public"."purchase_receipt" to "anon";

grant truncate on table "public"."purchase_receipt" to "anon";

grant update on table "public"."purchase_receipt" to "anon";

grant delete on table "public"."purchase_receipt" to "authenticated";

grant insert on table "public"."purchase_receipt" to "authenticated";

grant references on table "public"."purchase_receipt" to "authenticated";

grant select on table "public"."purchase_receipt" to "authenticated";

grant trigger on table "public"."purchase_receipt" to "authenticated";

grant truncate on table "public"."purchase_receipt" to "authenticated";

grant update on table "public"."purchase_receipt" to "authenticated";

grant delete on table "public"."purchase_receipt" to "service_role";

grant insert on table "public"."purchase_receipt" to "service_role";

grant references on table "public"."purchase_receipt" to "service_role";

grant select on table "public"."purchase_receipt" to "service_role";

grant trigger on table "public"."purchase_receipt" to "service_role";

grant truncate on table "public"."purchase_receipt" to "service_role";

grant update on table "public"."purchase_receipt" to "service_role";

grant delete on table "public"."purchase_receipt_line" to "anon";

grant insert on table "public"."purchase_receipt_line" to "anon";

grant references on table "public"."purchase_receipt_line" to "anon";

grant select on table "public"."purchase_receipt_line" to "anon";

grant trigger on table "public"."purchase_receipt_line" to "anon";

grant truncate on table "public"."purchase_receipt_line" to "anon";

grant update on table "public"."purchase_receipt_line" to "anon";

grant delete on table "public"."purchase_receipt_line" to "authenticated";

grant insert on table "public"."purchase_receipt_line" to "authenticated";

grant references on table "public"."purchase_receipt_line" to "authenticated";

grant select on table "public"."purchase_receipt_line" to "authenticated";

grant trigger on table "public"."purchase_receipt_line" to "authenticated";

grant truncate on table "public"."purchase_receipt_line" to "authenticated";

grant update on table "public"."purchase_receipt_line" to "authenticated";

grant delete on table "public"."purchase_receipt_line" to "service_role";

grant insert on table "public"."purchase_receipt_line" to "service_role";

grant references on table "public"."purchase_receipt_line" to "service_role";

grant select on table "public"."purchase_receipt_line" to "service_role";

grant trigger on table "public"."purchase_receipt_line" to "service_role";

grant truncate on table "public"."purchase_receipt_line" to "service_role";

grant update on table "public"."purchase_receipt_line" to "service_role";

grant delete on table "public"."recipe" to "anon";

grant insert on table "public"."recipe" to "anon";

grant references on table "public"."recipe" to "anon";

grant select on table "public"."recipe" to "anon";

grant trigger on table "public"."recipe" to "anon";

grant truncate on table "public"."recipe" to "anon";

grant update on table "public"."recipe" to "anon";

grant delete on table "public"."recipe" to "authenticated";

grant insert on table "public"."recipe" to "authenticated";

grant references on table "public"."recipe" to "authenticated";

grant select on table "public"."recipe" to "authenticated";

grant trigger on table "public"."recipe" to "authenticated";

grant truncate on table "public"."recipe" to "authenticated";

grant update on table "public"."recipe" to "authenticated";

grant delete on table "public"."recipe" to "service_role";

grant insert on table "public"."recipe" to "service_role";

grant references on table "public"."recipe" to "service_role";

grant select on table "public"."recipe" to "service_role";

grant trigger on table "public"."recipe" to "service_role";

grant truncate on table "public"."recipe" to "service_role";

grant update on table "public"."recipe" to "service_role";

grant delete on table "public"."recipe_component" to "anon";

grant insert on table "public"."recipe_component" to "anon";

grant references on table "public"."recipe_component" to "anon";

grant select on table "public"."recipe_component" to "anon";

grant trigger on table "public"."recipe_component" to "anon";

grant truncate on table "public"."recipe_component" to "anon";

grant update on table "public"."recipe_component" to "anon";

grant delete on table "public"."recipe_component" to "authenticated";

grant insert on table "public"."recipe_component" to "authenticated";

grant references on table "public"."recipe_component" to "authenticated";

grant select on table "public"."recipe_component" to "authenticated";

grant trigger on table "public"."recipe_component" to "authenticated";

grant truncate on table "public"."recipe_component" to "authenticated";

grant update on table "public"."recipe_component" to "authenticated";

grant delete on table "public"."recipe_component" to "service_role";

grant insert on table "public"."recipe_component" to "service_role";

grant references on table "public"."recipe_component" to "service_role";

grant select on table "public"."recipe_component" to "service_role";

grant trigger on table "public"."recipe_component" to "service_role";

grant truncate on table "public"."recipe_component" to "service_role";

grant update on table "public"."recipe_component" to "service_role";

grant delete on table "public"."recipe_media" to "anon";

grant insert on table "public"."recipe_media" to "anon";

grant references on table "public"."recipe_media" to "anon";

grant select on table "public"."recipe_media" to "anon";

grant trigger on table "public"."recipe_media" to "anon";

grant truncate on table "public"."recipe_media" to "anon";

grant update on table "public"."recipe_media" to "anon";

grant delete on table "public"."recipe_media" to "authenticated";

grant insert on table "public"."recipe_media" to "authenticated";

grant references on table "public"."recipe_media" to "authenticated";

grant select on table "public"."recipe_media" to "authenticated";

grant trigger on table "public"."recipe_media" to "authenticated";

grant truncate on table "public"."recipe_media" to "authenticated";

grant update on table "public"."recipe_media" to "authenticated";

grant delete on table "public"."recipe_media" to "service_role";

grant insert on table "public"."recipe_media" to "service_role";

grant references on table "public"."recipe_media" to "service_role";

grant select on table "public"."recipe_media" to "service_role";

grant trigger on table "public"."recipe_media" to "service_role";

grant truncate on table "public"."recipe_media" to "service_role";

grant update on table "public"."recipe_media" to "service_role";

grant delete on table "public"."recipe_step" to "anon";

grant insert on table "public"."recipe_step" to "anon";

grant references on table "public"."recipe_step" to "anon";

grant select on table "public"."recipe_step" to "anon";

grant trigger on table "public"."recipe_step" to "anon";

grant truncate on table "public"."recipe_step" to "anon";

grant update on table "public"."recipe_step" to "anon";

grant delete on table "public"."recipe_step" to "authenticated";

grant insert on table "public"."recipe_step" to "authenticated";

grant references on table "public"."recipe_step" to "authenticated";

grant select on table "public"."recipe_step" to "authenticated";

grant trigger on table "public"."recipe_step" to "authenticated";

grant truncate on table "public"."recipe_step" to "authenticated";

grant update on table "public"."recipe_step" to "authenticated";

grant delete on table "public"."recipe_step" to "service_role";

grant insert on table "public"."recipe_step" to "service_role";

grant references on table "public"."recipe_step" to "service_role";

grant select on table "public"."recipe_step" to "service_role";

grant trigger on table "public"."recipe_step" to "service_role";

grant truncate on table "public"."recipe_step" to "service_role";

grant update on table "public"."recipe_step" to "service_role";

grant delete on table "public"."role" to "anon";

grant insert on table "public"."role" to "anon";

grant references on table "public"."role" to "anon";

grant select on table "public"."role" to "anon";

grant trigger on table "public"."role" to "anon";

grant truncate on table "public"."role" to "anon";

grant update on table "public"."role" to "anon";

grant delete on table "public"."role" to "authenticated";

grant insert on table "public"."role" to "authenticated";

grant references on table "public"."role" to "authenticated";

grant select on table "public"."role" to "authenticated";

grant trigger on table "public"."role" to "authenticated";

grant truncate on table "public"."role" to "authenticated";

grant update on table "public"."role" to "authenticated";

grant delete on table "public"."role" to "service_role";

grant insert on table "public"."role" to "service_role";

grant references on table "public"."role" to "service_role";

grant select on table "public"."role" to "service_role";

grant trigger on table "public"."role" to "service_role";

grant truncate on table "public"."role" to "service_role";

grant update on table "public"."role" to "service_role";

grant delete on table "public"."role_permission" to "anon";

grant insert on table "public"."role_permission" to "anon";

grant references on table "public"."role_permission" to "anon";

grant select on table "public"."role_permission" to "anon";

grant trigger on table "public"."role_permission" to "anon";

grant truncate on table "public"."role_permission" to "anon";

grant update on table "public"."role_permission" to "anon";

grant delete on table "public"."role_permission" to "authenticated";

grant insert on table "public"."role_permission" to "authenticated";

grant references on table "public"."role_permission" to "authenticated";

grant select on table "public"."role_permission" to "authenticated";

grant trigger on table "public"."role_permission" to "authenticated";

grant truncate on table "public"."role_permission" to "authenticated";

grant update on table "public"."role_permission" to "authenticated";

grant delete on table "public"."role_permission" to "service_role";

grant insert on table "public"."role_permission" to "service_role";

grant references on table "public"."role_permission" to "service_role";

grant select on table "public"."role_permission" to "service_role";

grant trigger on table "public"."role_permission" to "service_role";

grant truncate on table "public"."role_permission" to "service_role";

grant update on table "public"."role_permission" to "service_role";

grant delete on table "public"."stock_movement" to "anon";

grant insert on table "public"."stock_movement" to "anon";

grant references on table "public"."stock_movement" to "anon";

grant select on table "public"."stock_movement" to "anon";

grant trigger on table "public"."stock_movement" to "anon";

grant truncate on table "public"."stock_movement" to "anon";

grant update on table "public"."stock_movement" to "anon";

grant delete on table "public"."stock_movement" to "authenticated";

grant insert on table "public"."stock_movement" to "authenticated";

grant references on table "public"."stock_movement" to "authenticated";

grant select on table "public"."stock_movement" to "authenticated";

grant trigger on table "public"."stock_movement" to "authenticated";

grant truncate on table "public"."stock_movement" to "authenticated";

grant update on table "public"."stock_movement" to "authenticated";

grant delete on table "public"."stock_movement" to "service_role";

grant insert on table "public"."stock_movement" to "service_role";

grant references on table "public"."stock_movement" to "service_role";

grant select on table "public"."stock_movement" to "service_role";

grant trigger on table "public"."stock_movement" to "service_role";

grant truncate on table "public"."stock_movement" to "service_role";

grant update on table "public"."stock_movement" to "service_role";

grant delete on table "public"."supplier" to "anon";

grant insert on table "public"."supplier" to "anon";

grant references on table "public"."supplier" to "anon";

grant select on table "public"."supplier" to "anon";

grant trigger on table "public"."supplier" to "anon";

grant truncate on table "public"."supplier" to "anon";

grant update on table "public"."supplier" to "anon";

grant delete on table "public"."supplier" to "authenticated";

grant insert on table "public"."supplier" to "authenticated";

grant references on table "public"."supplier" to "authenticated";

grant select on table "public"."supplier" to "authenticated";

grant trigger on table "public"."supplier" to "authenticated";

grant truncate on table "public"."supplier" to "authenticated";

grant update on table "public"."supplier" to "authenticated";

grant delete on table "public"."supplier" to "service_role";

grant insert on table "public"."supplier" to "service_role";

grant references on table "public"."supplier" to "service_role";

grant select on table "public"."supplier" to "service_role";

grant trigger on table "public"."supplier" to "service_role";

grant truncate on table "public"."supplier" to "service_role";

grant update on table "public"."supplier" to "service_role";

grant delete on table "public"."supplier_offer" to "anon";

grant insert on table "public"."supplier_offer" to "anon";

grant references on table "public"."supplier_offer" to "anon";

grant select on table "public"."supplier_offer" to "anon";

grant trigger on table "public"."supplier_offer" to "anon";

grant truncate on table "public"."supplier_offer" to "anon";

grant update on table "public"."supplier_offer" to "anon";

grant delete on table "public"."supplier_offer" to "authenticated";

grant insert on table "public"."supplier_offer" to "authenticated";

grant references on table "public"."supplier_offer" to "authenticated";

grant select on table "public"."supplier_offer" to "authenticated";

grant trigger on table "public"."supplier_offer" to "authenticated";

grant truncate on table "public"."supplier_offer" to "authenticated";

grant update on table "public"."supplier_offer" to "authenticated";

grant delete on table "public"."supplier_offer" to "service_role";

grant insert on table "public"."supplier_offer" to "service_role";

grant references on table "public"."supplier_offer" to "service_role";

grant select on table "public"."supplier_offer" to "service_role";

grant trigger on table "public"."supplier_offer" to "service_role";

grant truncate on table "public"."supplier_offer" to "service_role";

grant update on table "public"."supplier_offer" to "service_role";

grant delete on table "public"."supplier_offer_price" to "anon";

grant insert on table "public"."supplier_offer_price" to "anon";

grant references on table "public"."supplier_offer_price" to "anon";

grant select on table "public"."supplier_offer_price" to "anon";

grant trigger on table "public"."supplier_offer_price" to "anon";

grant truncate on table "public"."supplier_offer_price" to "anon";

grant update on table "public"."supplier_offer_price" to "anon";

grant delete on table "public"."supplier_offer_price" to "authenticated";

grant insert on table "public"."supplier_offer_price" to "authenticated";

grant references on table "public"."supplier_offer_price" to "authenticated";

grant select on table "public"."supplier_offer_price" to "authenticated";

grant trigger on table "public"."supplier_offer_price" to "authenticated";

grant truncate on table "public"."supplier_offer_price" to "authenticated";

grant update on table "public"."supplier_offer_price" to "authenticated";

grant delete on table "public"."supplier_offer_price" to "service_role";

grant insert on table "public"."supplier_offer_price" to "service_role";

grant references on table "public"."supplier_offer_price" to "service_role";

grant select on table "public"."supplier_offer_price" to "service_role";

grant trigger on table "public"."supplier_offer_price" to "service_role";

grant truncate on table "public"."supplier_offer_price" to "service_role";

grant update on table "public"."supplier_offer_price" to "service_role";

grant delete on table "public"."unit" to "anon";

grant insert on table "public"."unit" to "anon";

grant references on table "public"."unit" to "anon";

grant select on table "public"."unit" to "anon";

grant trigger on table "public"."unit" to "anon";

grant truncate on table "public"."unit" to "anon";

grant update on table "public"."unit" to "anon";

grant delete on table "public"."unit" to "authenticated";

grant insert on table "public"."unit" to "authenticated";

grant references on table "public"."unit" to "authenticated";

grant select on table "public"."unit" to "authenticated";

grant trigger on table "public"."unit" to "authenticated";

grant truncate on table "public"."unit" to "authenticated";

grant update on table "public"."unit" to "authenticated";

grant delete on table "public"."unit" to "service_role";

grant insert on table "public"."unit" to "service_role";

grant references on table "public"."unit" to "service_role";

grant select on table "public"."unit" to "service_role";

grant trigger on table "public"."unit" to "service_role";

grant truncate on table "public"."unit" to "service_role";

grant update on table "public"."unit" to "service_role";

grant delete on table "public"."user_role" to "anon";

grant insert on table "public"."user_role" to "anon";

grant references on table "public"."user_role" to "anon";

grant select on table "public"."user_role" to "anon";

grant trigger on table "public"."user_role" to "anon";

grant truncate on table "public"."user_role" to "anon";

grant update on table "public"."user_role" to "anon";

grant delete on table "public"."user_role" to "authenticated";

grant insert on table "public"."user_role" to "authenticated";

grant references on table "public"."user_role" to "authenticated";

grant select on table "public"."user_role" to "authenticated";

grant trigger on table "public"."user_role" to "authenticated";

grant truncate on table "public"."user_role" to "authenticated";

grant update on table "public"."user_role" to "authenticated";

grant delete on table "public"."user_role" to "service_role";

grant insert on table "public"."user_role" to "service_role";

grant references on table "public"."user_role" to "service_role";

grant select on table "public"."user_role" to "service_role";

grant trigger on table "public"."user_role" to "service_role";

grant truncate on table "public"."user_role" to "service_role";

grant update on table "public"."user_role" to "service_role";



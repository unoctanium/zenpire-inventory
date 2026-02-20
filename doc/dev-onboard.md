Zenpire Inventory MVP — Developer Handout

It’s written to onboard a developer quickly and explain how we work in this repo.

1) Repository Structure (Nuxt 4)

Canonical file tree we use:

app.vue
nuxt.config.ts
.env.example
pages/
  index.vue                # GET /
  login.vue                # GET /login
  dev/
    tools.vue              # Dev-only buttons: purge/seed
    adjust.vue             # Dev-only stock adjust smoke test
layouts/
  default.vue              # Global layout wrapper (header/footer/etc.)
server/
  api/                     # HTTP endpoints (BFF layer)
    me.get.ts              # GET /api/me (session + RBAC)
    dev/
      purge.post.ts        # POST /api/dev/purge (DEV_MODE gated)
      seed.post.ts         # POST /api/dev/seed  (DEV_MODE gated)
    stock/
      adjust.post.ts       # POST /api/stock/adjust -> DB RPC
  utils/
    supabase.ts            # Supabase client creation (service + publishable)
    require-admin-dev.ts   # DEV_MODE gate + RBAC gate helper
supabase/
  config.toml
  migrations/              # Versioned DB migrations (Supabase CLI)
db/
  schema_snapshot_*.sql    # Optional portability snapshot (not pushed as migration)
docs/
  ...

Routing rules
	•	UI routes come from pages/** (file → route mapping).
	•	API routes come from server/api/** (file → endpoint mapping).
	•	Shared server code goes into server/utils/**.
	•	Layouts go into layouts/**.
	•	app.vue is the global wrapper and should stay minimal.

⸻

2) Data Model Overview (Tables + Relations)

This MVP models:
	•	recipes and their components (ingredients or sub-recipes)
	•	ingredients with stock tracking
	•	supplier offers with time-based pricing
	•	stock movements for audit + reports

Core entities
	•	recipe
	•	has many recipe_step, recipe_media
	•	has many components in recipe_component
	•	ingredient
	•	has stock row in ingredient_stock (on hand, planned, thresholds)
	•	may be purchasable or produced (depending on kind and produced_by_recipe_id if present)
	•	supplier
	•	has many supplier_offer
	•	supplier_offer
	•	belongs to supplier
	•	has time-based prices in supplier_offer_price
	•	linked to ingredient(s) via ingredient_supplier_offer (many-to-many)
	•	supplier_offer_price
	•	prices are versioned by date range (valid_from, valid_to)
	•	price_per_pack is the price for one pack (packs can represent bundles)
	•	stock_movement
	•	immutable ledger of inventory movements (purchase/production/waste/adjust)
	•	drives reporting and stock valuation snapshots

Key relations (high level)
	•	recipe ↔ ingredient: via recipe_component (component can reference ingredient or sub-recipe)
	•	ingredient ↔ supplier_offer: via ingredient_supplier_offer (many-to-many)
	•	supplier_offer → supplier_offer_price: one-to-many (time/versioned prices)
	•	ingredient → ingredient_stock: one-to-one (current quantities and thresholds)
	•	ingredient → stock_movement: one-to-many (history/ledger)

⸻

3) SQL-first Domain Model (Why we do this)

We intentionally put “truth” and invariants into Postgres:
	•	constraints (FKs, uniques, checks)
	•	report views (stock snapshot, deltas, etc.)
	•	atomic operations as RPC functions

Benefits:
	•	consistent business logic across any future UI/client
	•	fewer race conditions (stock updates happen in DB transactions)
	•	portable to any Postgres provider (Supabase is replaceable)

⸻

4) RPC-based Logic (Atomic, DB-centered)

Inventory-changing operations are implemented as database functions (RPC), e.g.:
	•	fn_post_adjustment(...)
	•	(later) fn_post_purchase_receipt(...), fn_post_production_batch(...), etc.

Properties:
	•	atomic: one transaction per operation
	•	auditable: writes to stock_movement ledger
	•	consistent: prevents partial updates or client-side drift

The Nuxt server calls RPCs; the browser does not call RPCs directly.

⸻

5) Nuxt Server Layer (Thin Orchestration / BFF)

The Nuxt server API layer:
	•	authenticates the request (Supabase session cookie)
	•	resolves app_user
	•	enforces RBAC (via v_user_permissions)
	•	calls DB RPCs or executes bounded reads/writes

Rule of thumb:
	•	complex write logic belongs in DB RPCs
	•	server routes orchestrate and validate inputs; they do not “compute stock”

⸻

6) Controlled Seed + Purge (Dev-only)

We have dev endpoints to get deterministic test data and to reset the database safely.

DEV_MODE gate
	•	controlled via DEV_MODE=1 in .env
	•	endpoints reject requests if DEV_MODE is disabled

Endpoints
	•	POST /api/dev/purge
	•	calls DB RPC fn_dev_purge_all()
	•	clears all business data (ingredients/recipes/suppliers/offers/stock ledger)
	•	keeps baseline/reference tables such as unit and RBAC tables
	•	POST /api/dev/seed
	•	inserts a deterministic dataset (suppliers, ingredients, offers, prices)
	•	posts initial stock via fn_post_adjustment (so seed is consistent with domain rules)
	•	handles bundles by setting pack_quantity to the full bundle contents

Dev UI helpers
	•	/dev/tools provides buttons for purge/seed
	•	/dev/adjust provides a manual adjust smoke test

⸻

7) Versioned Migrations (Supabase CLI)

We use Supabase CLI as the migration authority.

Key commands:
	•	npx supabase migration new <name> → create migration file
	•	edit the generated SQL file
	•	npx supabase db push → apply to remote DB
	•	npx supabase migration list → verify local/remote alignment

Rules:
	•	Do not apply schema changes via Supabase SQL editor after this point
	•	every schema change must be a migration committed to git

About “remote_schema” migrations:
	•	because initial schema work started in the dashboard, the CLI created a large *_remote_schema.sql migration to sync local state.
	•	this is acceptable and now acts as our baseline migration in the chain.

⸻

8) Git-backed Reproducibility (How we keep dev stable)

Principles:
	•	the DB schema is reproducible via migrations in supabase/migrations
	•	dev DB content is reproducible via:
	•	/api/dev/purge
	•	/api/dev/seed

This gives any developer:
	•	the same schema
	•	the same seed data
	•	the same baseline behavior across machines

⸻

9) Current RBAC (MVP)

We currently gate dev/purge/seed operations using an “admin proxy permission”:
	•	stock.adjust.post

This is temporary and pragmatic for MVP.
Later we can add explicit permissions like:
	•	dev.seed.post
	•	dev.purge.post

⸻

10) Next Work: Minimal Admin UI (Option A)

We will implement small CRUD UIs for:
	•	Ingredients
	•	Suppliers
	•	Offers
	•	Stock snapshot view

Architecture rules still apply:
	•	UI calls Nuxt server endpoints
	•	server enforces RBAC
	•	writes go through DB/RPC whenever they affect stock / ledger

⸻

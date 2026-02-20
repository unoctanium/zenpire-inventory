// server/api/dev/seed.post.ts
import { requireAdminDev } from '~/server/utils/require-admin-dev'

type U = { id: string; code: string }

export default defineEventHandler(async (event) => {
  const { admin, appUserId } = await requireAdminDev(event)

  // -----------------------
  // Units
  // -----------------------
  const { data: units, error: uErr } = await admin.from('unit').select('id, code')
  if (uErr) throw createError({ statusCode: 500, statusMessage: uErr.message })

  const unitId = new Map<string, string>((units as U[]).map((u) => [u.code, u.id]))
  const g = unitId.get('g')
  const ml = unitId.get('ml')
  const pcs = unitId.get('pcs')
  if (!g || !ml || !pcs) throw createError({ statusCode: 500, statusMessage: 'Missing units g/ml/pcs' })

  // -----------------------
  // Suppliers
  // -----------------------
  const supplierDefs = [
    { name: 'Supplier A', contact_email: 'a@example.com', contact_phone: null, note: 'Dev seed supplier' },
    { name: 'Supplier B', contact_email: 'b@example.com', contact_phone: null, note: 'Dev seed supplier' },
  ]

  const supplierIds: Record<string, string> = {}

  for (const s of supplierDefs) {
    const { data: ex } = await admin.from('supplier').select('id').eq('name', s.name).maybeSingle()

    if (ex?.id) {
      supplierIds[s.name] = ex.id
      await admin.from('supplier')
        .update({ contact_email: s.contact_email, contact_phone: s.contact_phone, note: s.note })
        .eq('id', ex.id)
      continue
    }

    const { data: created } = await admin.from('supplier').insert(s).select('id').single()
    supplierIds[s.name] = created!.id
  }

  // -----------------------
  // Ingredients
  // -----------------------
  const ingredientDefs = [
    { name: 'Rice', default_unit_id: g, kind: 'purchased' },
    { name: 'Vinegar', default_unit_id: ml, kind: 'purchased' },
    { name: 'Nori Leaf', default_unit_id: pcs, kind: 'purchased' },
  ]

  const ingredientIds: Record<string, string> = {}

  for (const i of ingredientDefs) {
    const { data: ex } = await admin.from('ingredient').select('id').eq('name', i.name).maybeSingle()
    if (ex?.id) {
      ingredientIds[i.name] = ex.id
      continue
    }
    const { data: created } = await admin.from('ingredient').insert(i).select('id').single()
    ingredientIds[i.name] = created!.id
  }

  // -----------------------
  // Stock Targets
  // -----------------------
  const targets = [
    { name: 'Rice', planned: 5000, green: 500, yellow: 1500, unit: g },
    { name: 'Vinegar', planned: 6000, green: 600, yellow: 2000, unit: ml },
    { name: 'Nori Leaf', planned: 240, green: 24, yellow: 80, unit: pcs },
  ]

  for (const t of targets) {
    const ingredient_id = ingredientIds[t.name]
    const { data: ex } = await admin.from('ingredient_stock').select('ingredient_id').eq('ingredient_id', ingredient_id).maybeSingle()

    if (!ex) {
      await admin.from('ingredient_stock').insert({
        ingredient_id,
        on_hand_quantity: 0,
        planned_quantity: t.planned,
        unit_id: t.unit,
        green_min_delta: t.green,
        yellow_min_delta: t.yellow,
      })
    } else {
      await admin.from('ingredient_stock')
        .update({
          planned_quantity: t.planned,
          unit_id: t.unit,
          green_min_delta: t.green,
          yellow_min_delta: t.yellow,
        })
        .eq('ingredient_id', ingredient_id)
    }
  }

  // -----------------------
  // Offers
  // -----------------------
  const offers = [
    {
      supplier: 'Supplier A',
      supplier_article_number: 'RICE-1KG',
      offer_name: 'Rice 1kg',
      pack_quantity: 1000,
      pack_unit_id: g,
      price_per_pack: 2.5,
      ingredient: 'Rice'
    },
    {
      supplier: 'Supplier B',
      supplier_article_number: 'RICE-5KG',
      offer_name: 'Rice 5kg',
      pack_quantity: 5000,
      pack_unit_id: g,
      price_per_pack: 11.0,
      ingredient: 'Rice'
    },
    {
      supplier: 'Supplier A',
      supplier_article_number: 'VINEGAR-6x1L',
      offer_name: 'Vinegar bundle 6×1L',
      pack_quantity: 6000,
      pack_unit_id: ml,
      price_per_pack: 10.0,
      ingredient: 'Vinegar'
    },
    {
      supplier: 'Supplier B',
      supplier_article_number: 'NORI-6x20',
      offer_name: 'Nori bundle 6×(20 sheets)',
      pack_quantity: 120,
      pack_unit_id: pcs,
      price_per_pack: 12.0,
      ingredient: 'Nori Leaf'
    },
  ]

  const today = new Date().toISOString().slice(0, 10)

  for (const o of offers) {
    const supplier_id = supplierIds[o.supplier]
    const ingredient_id = ingredientIds[o.ingredient]

    const { data: ex } = await admin
      .from('supplier_offer')
      .select('id')
      .eq('supplier_id', supplier_id)
      .eq('supplier_article_number', o.supplier_article_number)
      .maybeSingle()

    let offer_id: string

    if (ex?.id) {
      offer_id = ex.id
      await admin.from('supplier_offer')
        .update({
          offer_name: o.offer_name,
          supplier_article_number: o.supplier_article_number,
          pack_quantity: o.pack_quantity,
          pack_unit_id: o.pack_unit_id,
          is_active: true,
          active_from: today,
          active_to: null,
          notes: null,
        })
        .eq('id', offer_id)
    } else {
      const { data: created } = await admin.from('supplier_offer')
        .insert({
          supplier_id,
          offer_name: o.offer_name,
          supplier_article_number: o.supplier_article_number,
          pack_quantity: o.pack_quantity,
          pack_unit_id: o.pack_unit_id,
          is_active: true,
          active_from: today,
          active_to: null,
          notes: null,
        })
        .select('id')
        .single()

      offer_id = created!.id
    }

    await admin.from('ingredient_supplier_offer')
      .upsert({ ingredient_id, supplier_offer_id: offer_id, is_preferred: false })

    await admin.from('supplier_offer_price').upsert({
      supplier_offer_id: offer_id,
      valid_from: today,
      valid_to: null,
      currency: 'EUR',
      price_per_pack: o.price_per_pack,
    })
  }

  // -----------------------
  // Initial Stock
  // -----------------------
  const adjustments = [
    { ingredient: 'Rice', qty: 2000, unit: g },
    { ingredient: 'Vinegar', qty: 1000, unit: ml },
    { ingredient: 'Nori Leaf', qty: 40, unit: pcs },
  ]

  for (const a of adjustments) {
    await admin.rpc('fn_post_adjustment', {
      p_payload: {
        ingredient_id: ingredientIds[a.ingredient],
        quantity: a.qty,
        unit_id: a.unit,
        occurred_at: null,
        unit_cost_snapshot: null,
        currency: 'EUR',
        note: 'dev seed initial stock',
        created_by_user_id: appUserId,
      },
    })
  }

  return { ok: true }
})
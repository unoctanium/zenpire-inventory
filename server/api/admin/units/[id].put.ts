import { readBody } from 'h3'
import { requirePermission } from '~/server/utils/require-permission'
import { supabaseAdmin } from '~/server/utils/supabase'

export default defineEventHandler(async (event) => {
  await requirePermission(event, 'unit.manage')

  const id = getRouterParam(event, 'id')
  if (!id) throw createError({ statusCode: 400, statusMessage: 'Missing id' })

  const body = await readBody(event)
  const code = String(body?.code ?? '').trim()
  const name = String(body?.name ?? '').trim()
  const unit_type = String(body?.unit_type ?? '').trim()

  if (!code || !name || !unit_type) {
    throw createError({ statusCode: 400, statusMessage: 'Missing code/name/unit_type' })
  }

  const admin = supabaseAdmin()

  const { data, error } = await admin
    .from('unit')
    .update({ code, name, unit_type })
    .eq('id', id)
    .select('id, code, name, unit_type, created_at')
    .single()

  if (error) throw createError({ statusCode: 400, statusMessage: error.message })
  return { ok: true, unit: data }
})
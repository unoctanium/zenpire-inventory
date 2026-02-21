import { requirePermission } from '~/server/utils/require-permission'
import { supabaseAdmin } from '~/server/utils/supabase'

export default defineEventHandler(async (event) => {
  await requirePermission(event, 'unit.manage')

  const id = getRouterParam(event, 'id')
  if (!id) throw createError({ statusCode: 400, statusMessage: 'Missing id' })

  const admin = supabaseAdmin()

  const { error } = await admin.from('unit').delete().eq('id', id)
  if (error) throw createError({ statusCode: 400, statusMessage: error.message })

  return { ok: true }
})
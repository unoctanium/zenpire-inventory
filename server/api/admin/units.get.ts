import { requireUser } from '~/server/utils/require-user'
import { supabaseAdmin } from '~/server/utils/supabase'

export default defineEventHandler(async (event) => {
  // read access: any authenticated user (or require a view permission if you prefer)
  await requireUser(event)

  const admin = supabaseAdmin()

  const { data, error } = await admin
    .from('unit')
    .select('id, code, name, unit_type, created_at')
    .order('unit_type', { ascending: true })
    .order('code', { ascending: true })

  if (error) throw createError({ statusCode: 500, statusMessage: error.message })
  return { ok: true, units: data ?? [] }
})
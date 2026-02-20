import { getCookie } from 'h3'
import { supabaseAdmin, supabasePublishable } from './supabase'

export async function requireAdminDev(event: any) {
  const config = useRuntimeConfig()
  if (!config.devMode) throw createError({ statusCode: 403, statusMessage: 'DEV_MODE disabled' })

  const access = getCookie(event, 'sb-access-token')
  if (!access) throw createError({ statusCode: 401, statusMessage: 'UNAUTHENTICATED' })

  const sb = supabasePublishable()
  const { data: userData, error: userErr } = await sb.auth.getUser(access)
  if (userErr || !userData.user) throw createError({ statusCode: 401, statusMessage: 'UNAUTHENTICATED' })

  const admin = supabaseAdmin()

  const { data: perms, error: permErr } = await admin
    .from('v_user_permissions')
    .select('permission_code')
    .eq('auth_user_id', userData.user.id)
  if (permErr) throw createError({ statusCode: 500, statusMessage: permErr.message })

  // MVP gate: treat this as “admin”
  const has = new Set((perms ?? []).map((p: any) => p.permission_code))
  if (!has.has('stock.adjust.post')) throw createError({ statusCode: 403, statusMessage: 'FORBIDDEN' })

  const { data: au, error: auErr } = await admin
    .from('app_user')
    .select('id')
    .eq('auth_user_id', userData.user.id)
    .single()
  if (auErr) throw createError({ statusCode: 500, statusMessage: auErr.message })

  return { admin, appUserId: au.id as string }
}
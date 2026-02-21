import { readBody, sendRedirect, createError } from 'h3'
import { supabaseServer } from '~/server/utils/supabase'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const email = String(body?.email ?? '').trim()
  const password = String(body?.password ?? '').trim()

  if (!email || !password) {
    throw createError({ statusCode: 400, statusMessage: 'Missing email or password' })
  }

  const supabase = supabaseServer(event)

  const { error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) {
    // redirect back with message
    const config = useRuntimeConfig()
    const base = config.public.siteUrl || ''
    return sendRedirect(event, `${base}/login?err=${encodeURIComponent(error.message)}`, 303)
  }

  const config = useRuntimeConfig()
  const base = config.public.siteUrl || ''
  return sendRedirect(event, `${base}/`, 303)
})
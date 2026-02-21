import { sendRedirect } from 'h3'
import { supabaseServer } from '~/server/utils/supabase'

export default defineEventHandler(async (event) => {
  const supabase = supabaseServer(event)
  await supabase.auth.signOut()

  const config = useRuntimeConfig()
  const base = config.public.siteUrl || ''
  return sendRedirect(event, `${base}/login`, 303)
})
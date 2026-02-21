import { createClient } from '@supabase/supabase-js'
import { createServerClient } from '@supabase/ssr'
import type { H3Event } from 'h3'
import { getRequestHeader, parseCookies, setCookie } from 'h3'

export function supabaseAdmin() {
  const config = useRuntimeConfig()
  return createClient(config.public.supabaseUrl, config.supabaseServiceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
}

export function supabasePublishable() {
  const config = useRuntimeConfig()
  return createClient(config.public.supabaseUrl, config.public.supabasePublishableKey)
}


export function supabaseServer(event: H3Event) {
  const config = useRuntimeConfig()

  return createServerClient(
    config.public.supabaseUrl,
    config.public.supabasePublishableKey,
    {
      cookies: {
        getAll() {
          const all = parseCookies(event) // { name: value }
          return Object.entries(all).map(([name, value]) => ({ name, value }))
        },
        setAll(cookiesToSet) {
          for (const { name, value, options } of cookiesToSet) {
            setCookie(event, name, value, { path: '/', ...options })
          }
        },
      },
    }
  )
}
import { createClient } from '@supabase/supabase-js'
import { createServerClient } from '@supabase/ssr'
import type { H3Event } from 'h3'
import { getRequestHeader, setCookie } from 'h3'

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

// ✅ Cookie-bound server client (correct for sign-in/sign-out + SSR auth)
export function supabaseServer(event: H3Event) {
  const config = useRuntimeConfig()

  return createServerClient(
    config.public.supabaseUrl,
    config.public.supabasePublishableKey,
    {
      cookies: {
        getAll() {
          const cookieHeader = getRequestHeader(event, 'cookie') || ''
          // Parse cookies manually (no extra deps)
          return cookieHeader
            .split(';')
            .map(v => v.trim())
            .filter(Boolean)
            .map(v => {
              const idx = v.indexOf('=')
              const name = idx >= 0 ? v.slice(0, idx) : v
              const value = idx >= 0 ? decodeURIComponent(v.slice(idx + 1)) : ''
              return { name, value }
            })
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            // Ensure path default so delete overwrites correctly
            setCookie(event, name, value, { path: '/', ...options })
          })
        },
      },
    }
  )
}
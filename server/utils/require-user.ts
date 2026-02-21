import { createError } from 'h3'
import type { H3Event } from 'h3'
import { supabaseServer } from '~/server/utils/supabase'

export async function requireUser(event: H3Event) {
  const supabase = supabaseServer(event)

  const { data, error } = await supabase.auth.getUser()

  if (error || !data?.user) {
    throw createError({
      statusCode: 401,
      statusMessage: 'UNAUTHENTICATED',
    })
  }

  return data.user
}
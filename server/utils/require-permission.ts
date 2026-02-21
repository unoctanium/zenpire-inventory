import { createError } from 'h3'
import { requireUser } from './require-user'
import { supabaseAdmin } from './supabase'

export async function requirePermission(event: any, permission: string) {
	const user = await requireUser(event)
	const admin = supabaseAdmin()

	const { data, error } = await admin
		.from('v_user_permissions')
		.select('permission')
		.eq('user_id', user.id)
		.eq('permission', permission)
		.maybeSingle()

	if (error) {
		throw createError({
			statusCode: 500,
			statusMessage: error.message
		})
	}

	if (!data) {
		throw createError({
			statusCode: 403,
			statusMessage: 'Missing permission'
		})
	}

	return user
}
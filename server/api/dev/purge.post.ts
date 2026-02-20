import { requireAdminDev } from '~/server/utils/require-admin-dev'

export default defineEventHandler(async (event) => {
  const { admin } = await requireAdminDev(event)

  const { error } = await admin.rpc('fn_dev_purge_all')
  if (error) throw createError({ statusCode: 400, statusMessage: error.message })

  return { ok: true }
})

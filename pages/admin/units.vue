<script setup lang="ts">
type UnitType = 'mass' | 'volume' | 'count'

type UnitRow = {
  id: string
  code: string
  name: string
  unit_type: UnitType
}

type UiRow =
  | (UnitRow & { _mode: 'view' | 'edit'; _draft?: Pick<UnitRow, 'code' | 'name' | 'unit_type'> })
  | {
      id: '__new__'
      code: ''
      name: ''
      unit_type: UnitType
      _mode: 'edit'
      _draft: Pick<UnitRow, 'code' | 'name' | 'unit_type'>
    }

const toast = useToast()

const unitTypeOptions: { label: string; value: UnitType }[] = [
  { label: 'mass', value: 'mass' },
  { label: 'volume', value: 'volume' },
  { label: 'count', value: 'count' },
]

const { data, pending, refresh, error } = await useFetch<{ ok: boolean; units: UnitRow[] }>('/api/admin/units', {
  credentials: 'include',
})

const rows = ref<UiRow[]>([])

watchEffect(() => {
  const apiUnits = data.value?.units ?? []
  const hasNew = rows.value.some((r) => r.id === '__new__')
  const mapped: UiRow[] = apiUnits.map((u) => ({ ...u, _mode: 'view' }))
  rows.value = hasNew ? [{ ...(rows.value.find((r) => r.id === '__new__') as any) }, ...mapped] : mapped
})

function showError(title: string, e: any) {
  toast.add({
    title,
    description: e?.data?.message ?? e?.data?.statusMessage ?? e?.message ?? String(e),
    color: 'red',
  })
}

function isDraftValid(d: Pick<UnitRow, 'code' | 'name' | 'unit_type'>) {
  return d.code.trim().length > 0 && d.name.trim().length > 0 && !!d.unit_type
}

function startAdd() {
  if (rows.value.some((r) => r.id === '__new__')) return
  rows.value.unshift({
    id: '__new__',
    code: '',
    name: '',
    unit_type: 'mass',
    _mode: 'edit',
    _draft: { code: '', name: '', unit_type: 'mass' },
  })
}

function startEdit(row: UiRow) {
  if (row.id === '__new__') return
  row._mode = 'edit'
  row._draft = { code: row.code, name: row.name, unit_type: row.unit_type }
}

function discard(row: UiRow) {
  if (row.id === '__new__') {
    rows.value = rows.value.filter((r) => r.id !== '__new__')
    return
  }
  row._mode = 'view'
  row._draft = undefined
}

async function commit(row: UiRow) {
  const draft = row._draft
  if (!draft) return

  if (!isDraftValid(draft)) {
    toast.add({ title: 'Missing fields', description: 'Code and Name are required.', color: 'red' })
    return
  }

  try {
    if (row.id === '__new__') {
      await $fetch('/api/admin/units', {
        method: 'POST',
        credentials: 'include',
        body: {
          code: draft.code.trim(),
          name: draft.name.trim(),
          unit_type: draft.unit_type,
        },
      })
      toast.add({ title: 'Unit created' })
      rows.value = rows.value.filter((r) => r.id !== '__new__')
      await refresh()
      return
    }

    await $fetch(`/api/admin/units/${row.id}`, {
      method: 'PUT',
      credentials: 'include',
      body: {
        code: draft.code.trim(),
        name: draft.name.trim(),
        unit_type: draft.unit_type,
      },
    })

    toast.add({ title: 'Unit updated' })
    row._mode = 'view'
    row._draft = undefined
    await refresh()
  } catch (e: any) {
    showError('Save failed', e)
  }
}

/** Delete via Nuxt UI modal (no window.confirm; works in Firefox Klar) */
const isDeleteOpen = ref(false)
const deletingRow = ref<UiRow | null>(null)

function requestDelete(row: UiRow) {
  deletingRow.value = row
  isDeleteOpen.value = true
}

async function confirmDelete() {
  const row = deletingRow.value
  if (!row) return

  // If deleting the new draft row, just discard it.
  if (row.id === '__new__') {
    rows.value = rows.value.filter((r) => r.id !== '__new__')
    isDeleteOpen.value = false
    deletingRow.value = null
    return
  }

  try {
    await $fetch(`/api/admin/units/${row.id}`, {
      method: 'DELETE',
      credentials: 'include',
    })
    toast.add({ title: 'Unit deleted' })
    isDeleteOpen.value = false
    deletingRow.value = null
    await refresh()
  } catch (e: any) {
    showError('Delete failed', e)
  }
}
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between gap-3">
      <div>
        <h1 class="text-xl font-semibold">Units</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400">Admin-only CRUD (permission: unit.manage)</p>
      </div>

      <UButton icon="i-heroicons-plus" @click="startAdd">Add unit</UButton>
    </div>

    <div
      v-if="error"
      class="rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:border-red-900/40 dark:bg-red-900/20 dark:text-red-200"
    >
      Failed to load units: {{ error?.message }}
    </div>

    <div class="overflow-auto rounded-lg border border-gray-200 dark:border-gray-800">
      <table class="min-w-[720px] w-full table-fixed border-separate border-spacing-0 text-sm">
        <colgroup>
          <col style="width: 140px" />
          <col style="width: 360px" />
          <col style="width: 160px" />
          <col style="width: 140px" />
        </colgroup>

        <thead class="sticky top-0 z-20 bg-white dark:bg-gray-950">
          <tr>
            <th
              class="sticky left-0 z-30 px-3 py-2 text-left font-medium text-gray-700 dark:text-gray-200
                     border-b border-gray-200 dark:border-gray-800
                     border-r border-gray-200 dark:border-gray-800
                     bg-white dark:bg-gray-950"
            >
              Code
            </th>

            <th
              class="px-3 py-2 text-left font-medium text-gray-700 dark:text-gray-200
                     border-b border-gray-200 dark:border-gray-800"
            >
              Name
            </th>

            <th
              class="px-3 py-2 text-left font-medium text-gray-700 dark:text-gray-200
                     border-b border-gray-200 dark:border-gray-800"
            >
              Type
            </th>

            <th
              class="sticky right-0 z-30 px-3 py-2 text-right font-medium text-gray-700 dark:text-gray-200
                     border-b border-gray-200 dark:border-gray-800
                     border-l border-gray-200 dark:border-gray-800
                     bg-white dark:bg-gray-950"
            >
              Actions
            </th>
          </tr>
        </thead>

        <tbody>
          <tr v-if="pending">
            <td colspan="4" class="px-3 py-3 text-gray-500 dark:text-gray-400">Loading…</td>
          </tr>

          <tr v-else-if="rows.length === 0">
            <td colspan="4" class="px-3 py-3 text-gray-500 dark:text-gray-400">No data</td>
          </tr>

          <tr v-for="row in rows" :key="row.id" class="border-b border-gray-100 dark:border-gray-900/60">
            <!-- CODE (sticky + continuous right border) -->
            <td
              class="sticky left-0 z-10 px-3 py-2 align-middle
                     bg-white dark:bg-gray-950
                     border-r border-gray-200 dark:border-gray-800"
            >
              <template v-if="row._mode === 'edit'">
                <input
                  v-model="row._draft!.code"
                  class="w-full rounded-md border border-gray-300 bg-white px-2 py-1 text-gray-900
                         focus:outline-none focus:ring-2 focus:ring-gray-300
                         dark:border-gray-700 dark:bg-gray-900 dark:text-gray-100 dark:focus:ring-gray-700"
                  placeholder="e.g. g"
                  inputmode="text"
                  autocapitalize="none"
                  autocomplete="off"
                />
              </template>
              <template v-else>
                <span class="font-medium text-gray-900 dark:text-gray-100">{{ row.code }}</span>
              </template>
            </td>

            <!-- NAME -->
            <td class="px-3 py-2 align-middle">
              <template v-if="row._mode === 'edit'">
                <input
                  v-model="row._draft!.name"
                  class="w-full rounded-md border border-gray-300 bg-white px-2 py-1 text-gray-900
                         focus:outline-none focus:ring-2 focus:ring-gray-300
                         dark:border-gray-700 dark:bg-gray-900 dark:text-gray-100 dark:focus:ring-gray-700"
                  placeholder="e.g. Gram"
                  inputmode="text"
                  autocomplete="off"
                />
              </template>
              <template v-else>
                <span class="text-gray-800 dark:text-gray-200">{{ row.name }}</span>
              </template>
            </td>

            <!-- TYPE -->
            <td class="px-3 py-2 align-middle">
              <template v-if="row._mode === 'edit'">
                <select
                  v-model="row._draft!.unit_type"
                  class="w-full rounded-md border border-gray-300 bg-white px-2 py-1 text-gray-900
                         focus:outline-none focus:ring-2 focus:ring-gray-300
                         dark:border-gray-700 dark:bg-gray-900 dark:text-gray-100 dark:focus:ring-gray-700"
                >
                  <option v-for="o in unitTypeOptions" :key="o.value" :value="o.value">
                    {{ o.label }}
                  </option>
                </select>
              </template>
              <template v-else>
                <span class="text-gray-800 dark:text-gray-200">{{ row.unit_type }}</span>
              </template>
            </td>

            <!-- ACTIONS (sticky + continuous left border) -->
            <td
              class="sticky right-0 z-10 px-3 py-2 align-middle text-right
                     bg-white dark:bg-gray-950
                     border-l border-gray-200 dark:border-gray-800"
            >
              <div class="flex items-center justify-end gap-2">
                <template v-if="row._mode === 'view'">
                  <UButton
                    size="xs"
                    variant="soft"
                    icon="i-heroicons-pencil"
                    square
                    aria-label="Edit"
                    @click="startEdit(row)"
                  />
                </template>

                <template v-else>
                  <UButton
                    size="xs"
                    variant="soft"
                    icon="i-heroicons-check"
                    square
                    aria-label="Save"
                    @click="commit(row)"
                  />
                  <UButton
                    size="xs"
                    variant="soft"
                    color="gray"
                    icon="i-heroicons-x-mark"
                    square
                    aria-label="Discard"
                    @click="discard(row)"
                  />
                </template>

                <UButton
                  size="xs"
                  color="red"
                  variant="soft"
                  icon="i-heroicons-trash"
                  square
                  aria-label="Delete"
                  @click="requestDelete(row)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <p class="text-xs text-gray-500 dark:text-gray-400">
      Note: Delete is enforced server-side (403 outside DEV_MODE). UI shows the button (MVP).
    </p>

    <!-- Delete modal (overlay only) -->
    <UModal v-model:open="isDeleteOpen" title="Delete unit">
      <template #body>
        <p v-if="deletingRow?.id === '__new__'">Discard the new (unsaved) row?</p>
        <p v-else>Delete <strong>{{ (deletingRow as any)?.code }}</strong> ({{ (deletingRow as any)?.name }})?</p>
      </template>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton color="gray" variant="soft" @click="isDeleteOpen = false">Cancel</UButton>
          <UButton color="red" @click="confirmDelete">Delete</UButton>
        </div>
      </template>
    </UModal>
  </div>
</template>
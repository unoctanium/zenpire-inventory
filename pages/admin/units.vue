<script setup lang="ts">
type UnitRow = { id: string; code: string; name: string; unit_type: string }
type UnitDraft = { code: string; name: string; unit_type: string }

const toast = useToast()

const { data: me } = await useFetch('/api/me', { retry: false, server: false })

const canManage = computed(() => ((me.value as any)?.permissions ?? []).includes('unit.manage'))

const { data: res, pending, error, refresh } =
  await useFetch<{ ok: boolean; units: UnitRow[] }>('/api/admin/units', {
    retry: false,
    server: false,
  })

const units = computed(() => res.value?.units ?? [])

const unitTypeItems = [
  { label: 'mass', value: 'mass' },
  { label: 'volume', value: 'volume' },
  { label: 'count', value: 'count' },
]

// single-row edit model
const editingId = ref<string | null>(null) // existing id or '__new__'
const draft = reactive<UnitDraft>({ code: '', name: '', unit_type: 'mass' })

const originalRow = computed<UnitRow | null>(() => {
  if (!editingId.value || editingId.value === '__new__') return null
  return units.value.find(u => u.id === editingId.value) ?? null
})

const isEditingNew = computed(() => editingId.value === '__new__')
const isEditingExisting = computed(() => !!editingId.value && editingId.value !== '__new__')

const draftCode = computed(() => draft.code.trim())
const draftName = computed(() => draft.name.trim())

const canCommit = computed(() => {
  if (!editingId.value) return false
  return draftCode.value.length > 0 && draftName.value.length > 0
})

const isDirty = computed(() => {
  if (!editingId.value) return false
  if (editingId.value === '__new__') {
    return draftCode.value.length > 0 || draftName.value.length > 0 || draft.unit_type !== 'mass'
  }
  const o = originalRow.value
  if (!o) return false
  return draft.code !== o.code || draft.name !== o.name || draft.unit_type !== o.unit_type
})

function resetDraft() {
  draft.code = ''
  draft.name = ''
  draft.unit_type = 'mass'
}

function startEditRow(row: UnitRow) {
  if (!canManage.value) return
  if (editingId.value && isDirty.value) {
    const ok = window.confirm('Discard current changes?')
    if (!ok) return
  }
  editingId.value = row.id
  draft.code = row.code
  draft.name = row.name
  draft.unit_type = row.unit_type
}

function startCreate() {
  if (!canManage.value) return
  if (editingId.value && isDirty.value) {
    const ok = window.confirm('Discard current changes?')
    if (!ok) return
  }
  editingId.value = '__new__'
  resetDraft()
}

async function commit() {
  if (!canManage.value || !editingId.value) return

  // proactive validation (required fields)
  if (!canCommit.value) {
    toast.add({
      title: 'Missing required fields',
      description: 'Please enter both code and name.',
      color: 'red',
    })
    return
  }

  try {
    if (editingId.value === '__new__') {
      await $fetch('/api/admin/units', { method: 'POST', body: { ...draft } })
    } else {
      await $fetch(`/api/admin/units/${editingId.value}`, { method: 'PUT', body: { ...draft } })
    }

    editingId.value = null
    resetDraft()
    await refresh()
  } catch (e: any) {
    toast.add({
      title: 'Save failed',
      description: e?.data?.message ?? e?.message ?? String(e),
      color: 'red',
    })
  }
}

function discard() {
  if (!editingId.value) return
  editingId.value = null
  resetDraft()
}

async function deleteRow(row: UnitRow) {
  if (!canManage.value) return

  const ok = window.confirm(`Delete unit "${row.code}"?`)
  if (!ok) return

  try {
    await $fetch(`/api/admin/units/${row.id}`, { method: 'DELETE' })
    await refresh()
  } catch (e: any) {
    toast.add({
      title: 'Delete failed',
      description: e?.data?.message ?? e?.message ?? String(e),
      color: 'red',
    })
  }
}

// Styling helpers (for separators + sticky columns)
const sepR = 'border-r border-zinc-200 dark:border-zinc-800'
const sepL = 'border-l border-zinc-200 dark:border-zinc-800'
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between gap-3">
      <div>
        <h1 class="text-2xl font-semibold">Units</h1>
        <p class="text-sm text-zinc-500 dark:text-zinc-400">
          Inline row editor. Permission: <code>unit.manage</code>.
        </p>
      </div>

      <div class="flex gap-2">
        <UButton size="sm" variant="soft" @click="refresh">Refresh</UButton>
        <UButton v-if="canManage" size="sm" icon="i-heroicons-plus" @click="startCreate">
          Add unit
        </UButton>
      </div>
    </div>

    <UAlert
      v-if="error"
      color="red"
      variant="soft"
      title="Units API error"
      :description="String(error)"
    />

    <div class="rounded-xl border border-zinc-200 dark:border-zinc-800 overflow-auto bg-white dark:bg-zinc-950">
      <table class="min-w-[720px] w-full text-sm border-separate border-spacing-0">
        <thead class="sticky top-0 z-20 bg-white dark:bg-zinc-950">
          <tr>
            <th
              class="sticky left-0 z-30 bg-white dark:bg-zinc-950 text-left font-medium px-3 py-2
                     border-b border-zinc-200 dark:border-zinc-800 w-[140px]"
              :class="sepR"
            >
              Code
            </th>
            <th class="text-left font-medium px-3 py-2 border-b border-zinc-200 dark:border-zinc-800 w-[260px]">
              Name
            </th>
            <th class="text-left font-medium px-3 py-2 border-b border-zinc-200 dark:border-zinc-800 w-[160px]">
              Type
            </th>
            <th
              class="sticky right-0 z-30 bg-white dark:bg-zinc-950 text-right font-medium px-3 py-2
                     border-b border-zinc-200 dark:border-zinc-800 w-[140px]"
              :class="sepL"
            />
          </tr>
        </thead>

        <tbody>
          <!-- Draft row -->
          <tr v-if="isEditingNew" class="bg-zinc-50 dark:bg-zinc-900/20">
            <td
              class="sticky left-0 z-10 bg-zinc-50 dark:bg-zinc-900/20 px-3 py-2
                     border-b border-zinc-100 dark:border-zinc-900"
              :class="sepR"
            >
              <UInput v-model="draft.code" class="text-base" placeholder="e.g. g" />
            </td>

            <td class="px-3 py-2 border-b border-zinc-100 dark:border-zinc-900">
              <UInput v-model="draft.name" class="text-base" placeholder="e.g. Gram" />
            </td>

            <td class="px-3 py-2 border-b border-zinc-100 dark:border-zinc-900">
              <USelect v-model="draft.unit_type" :items="unitTypeItems" />
            </td>

            <td
              class="sticky right-0 z-10 bg-zinc-50 dark:bg-zinc-900/20 px-3 py-2
                     border-b border-zinc-100 dark:border-zinc-900"
              :class="sepL"
            >
              <div class="flex justify-end gap-2">
                <UButton size="xs" icon="i-heroicons-check" :disabled="!canCommit" @click="commit" />
                <UButton size="xs" variant="ghost" icon="i-heroicons-x-mark" @click="discard" />
              </div>
            </td>
          </tr>

          <!-- Existing rows -->
          <tr v-for="row in units" :key="row.id">
            <td
              class="sticky left-0 z-10 bg-white dark:bg-zinc-950 px-3 py-2
                     border-b border-zinc-100 dark:border-zinc-900"
              :class="sepR"
            >
              <template v-if="editingId === row.id">
                <UInput v-model="draft.code" class="text-base" />
              </template>
              <template v-else>
                <span class="font-medium">{{ row.code }}</span>
              </template>
            </td>

            <td class="px-3 py-2 border-b border-zinc-100 dark:border-zinc-900">
              <template v-if="editingId === row.id">
                <UInput v-model="draft.name" class="text-base" />
              </template>
              <template v-else>
                {{ row.name }}
              </template>
            </td>

            <td class="px-3 py-2 border-b border-zinc-100 dark:border-zinc-900">
              <template v-if="editingId === row.id">
                <USelect v-model="draft.unit_type" :items="unitTypeItems" />
              </template>
              <template v-else>
                {{ row.unit_type }}
              </template>
            </td>

            <td
              class="sticky right-0 z-10 bg-white dark:bg-zinc-950 px-3 py-2
                     border-b border-zinc-100 dark:border-zinc-900"
              :class="sepL"
            >
              <div class="flex justify-end gap-2">
                <template v-if="editingId === row.id">
                  <UButton size="xs" icon="i-heroicons-check" :disabled="!canCommit" @click="commit" />
                  <UButton size="xs" variant="ghost" icon="i-heroicons-x-mark" @click="discard" />
                  <UButton
                    size="xs"
                    color="red"
                    variant="ghost"
                    icon="i-heroicons-trash"
                    @click="deleteRow(row)"
                  />
                </template>

                <template v-else>
                  <UButton
                    size="xs"
                    variant="ghost"
                    icon="i-heroicons-pencil-square"
                    :disabled="!canManage"
                    @click="startEditRow(row)"
                  />
                  <UButton
                    size="xs"
                    color="red"
                    variant="ghost"
                    icon="i-heroicons-trash"
                    :disabled="!canManage"
                    @click="deleteRow(row)"
                  />
                </template>
              </div>
            </td>
          </tr>

          <tr v-if="!pending && units.length === 0 && !isEditingNew">
            <td colspan="4" class="px-3 py-4 text-zinc-500 dark:text-zinc-400">No units yet.</td>
          </tr>

          <tr v-if="pending">
            <td colspan="4" class="px-3 py-4 text-zinc-500 dark:text-zinc-400">Loading…</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
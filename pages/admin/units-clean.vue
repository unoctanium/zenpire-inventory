<script setup lang="ts">
type UnitRow = {
  id: string
  code: string
  name: string
  unit_type: string
}

const { data: res, pending, error, refresh } =
  await useFetch<{ ok: boolean; units: UnitRow[] }>('/api/admin/units', {
    retry: false,
    server: false,
  })

const units = computed(() => res.value?.units ?? [])

// -------- Create form
const createForm = reactive({
  code: '',
  name: '',
  unit_type: 'mass',
})

// -------- Edit form
const selectedId = ref<string>('')
const selectedUnit = computed(() => units.value.find(u => u.id === selectedId.value) ?? null)

const editForm = reactive({
  code: '',
  name: '',
  unit_type: 'mass',
})

// Keep editForm in sync when selection changes
watch(selectedUnit, (u) => {
  if (!u) return
  editForm.code = u.code
  editForm.name = u.name
  editForm.unit_type = u.unit_type
}, { immediate: true })

async function createUnit() {
  await $fetch('/api/admin/units', { method: 'POST', body: { ...createForm } })
  createForm.code = ''
  createForm.name = ''
  createForm.unit_type = 'mass'
  await refresh()
}

async function updateUnit() {
  if (!selectedId.value) return
  await $fetch(`/api/admin/units/${selectedId.value}`, { method: 'PUT', body: { ...editForm } })
  await refresh()
}

async function deleteUnit() {
  if (!selectedId.value) return
  await $fetch(`/api/admin/units/${selectedId.value}`, { method: 'DELETE' })
  selectedId.value = ''
  await refresh()
}

const unitTypeItems = [
  { label: 'mass', value: 'mass' },
  { label: 'volume', value: 'volume' },
  { label: 'count', value: 'count' },
]
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-semibold">Units (clean CRUD test)</h1>
      <UButton size="sm" variant="soft" @click="refresh">Refresh</UButton>
    </div>

    <UAlert
      v-if="error"
      color="red"
      variant="soft"
      title="API error"
      :description="String(error)"
    />

    <UCard>
      <template #header>Raw JSON</template>
      <pre class="text-xs whitespace-pre-wrap">{{ units }}</pre>
    </UCard>

    <UCard>
      <template #header>Table</template>

      <div v-if="pending">Loading…</div>
      <table v-else class="w-full text-sm border-collapse">
        <thead>
          <tr class="border-b border-zinc-200 dark:border-zinc-800">
            <th class="text-left py-2">Code</th>
            <th class="text-left py-2">Name</th>
            <th class="text-left py-2">Type</th>
            <th class="text-left py-2">ID</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="u in units"
            :key="u.id"
            class="border-b border-zinc-100 dark:border-zinc-900"
          >
            <td class="py-2">{{ u.code }}</td>
            <td class="py-2">{{ u.name }}</td>
            <td class="py-2">{{ u.unit_type }}</td>
            <td class="py-2 font-mono text-xs">{{ u.id }}</td>
          </tr>

          <tr v-if="units.length === 0">
            <td colspan="4" class="py-3 text-zinc-500">No data</td>
          </tr>
        </tbody>
      </table>
    </UCard>

    <UCard>
      <template #header>Create</template>

      <div class="grid gap-3 max-w-md">
        <label class="text-sm">Code</label>
        <UInput v-model="createForm.code" class="text-base" placeholder="e.g. g" />

        <label class="text-sm">Name</label>
        <UInput v-model="createForm.name" class="text-base" placeholder="e.g. Gram" />

        <label class="text-sm">Type</label>
        <USelect v-model="createForm.unit_type" :items="unitTypeItems" />

        <UButton @click="createUnit">Create</UButton>
      </div>
    </UCard>

    <UCard>
      <template #header>Edit / Delete</template>

      <div class="grid gap-3 max-w-md">
        <label class="text-sm">Select unit</label>
        <select v-model="selectedId" class="border rounded px-2 py-2 bg-transparent">
          <option value="">-- select --</option>
          <option v-for="u in units" :key="u.id" :value="u.id">
            {{ u.code }} — {{ u.name }} ({{ u.unit_type }})
          </option>
        </select>

        <div v-if="!selectedUnit" class="text-sm text-zinc-500">
          Select a unit to edit/delete.
        </div>

        <template v-else>
          <label class="text-sm">Code</label>
          <UInput v-model="editForm.code" class="text-base" />

          <label class="text-sm">Name</label>
          <UInput v-model="editForm.name" class="text-base" />

          <label class="text-sm">Type</label>
          <USelect v-model="editForm.unit_type" :items="unitTypeItems" />

          <div class="flex gap-2">
            <UButton @click="updateUnit">Update</UButton>
            <UButton color="red" variant="soft" @click="deleteUnit">Delete</UButton>
          </div>

          <p class="text-xs text-zinc-500">
            Delete will return 403 outside DEV_MODE (expected).
          </p>
        </template>
      </div>
    </UCard>
  </div>
</template>
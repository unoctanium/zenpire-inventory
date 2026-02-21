<script setup lang="ts">
type UnitRow = {
  id: string
  code: string
  name: string
  unit_type: string
  created_at?: string
}

const toast = useToast()

const { data, pending, refresh } = await useFetch<{ ok: boolean; units: UnitRow[] }>('/api/admin/units')
const units = computed(() => data.value?.units ?? [])

const isCreateOpen = ref(false)
const isEditOpen = ref(false)
const isDeleteOpen = ref(false)

const editing = ref<UnitRow | null>(null)
const deleting = ref<UnitRow | null>(null)

const form = reactive({
  code: '',
  name: '',
  unit_type: 'mass',
})

const unitTypeOptions = [
  { label: 'mass', value: 'mass' },
  { label: 'volume', value: 'volume' },
  { label: 'count', value: 'count' },
]

function openCreate() {
  form.code = ''
  form.name = ''
  form.unit_type = 'mass'
  isCreateOpen.value = true
}

function openEdit(u: UnitRow) {
  editing.value = u
  form.code = u.code
  form.name = u.name
  form.unit_type = u.unit_type
  isEditOpen.value = true
}

function openDelete(u: UnitRow) {
  deleting.value = u
  isDeleteOpen.value = true
}

async function createUnit() {
  try {
    await $fetch('/api/admin/units', { method: 'POST', body: { ...form } })
    toast.add({ title: 'Unit created' })
    isCreateOpen.value = false
    await refresh()
  } catch (e: any) {
    toast.add({ title: 'Create failed', description: e?.data?.message ?? e?.message ?? String(e), color: 'red' })
  }
}

async function updateUnit() {
  if (!editing.value) return
  try {
    await $fetch(`/api/admin/units/${editing.value.id}`, { method: 'PUT', body: { ...form } })
    toast.add({ title: 'Unit updated' })
    isEditOpen.value = false
    editing.value = null
    await refresh()
  } catch (e: any) {
    toast.add({ title: 'Update failed', description: e?.data?.message ?? e?.message ?? String(e), color: 'red' })
  }
}

async function deleteUnit() {
  if (!deleting.value) return
  try {
    await $fetch(`/api/admin/units/${deleting.value.id}`, { method: 'DELETE' })
    toast.add({ title: 'Unit deleted' })
    isDeleteOpen.value = false
    deleting.value = null
    await refresh()
  } catch (e: any) {
    toast.add({ title: 'Delete failed', description: e?.data?.message ?? e?.message ?? String(e), color: 'red' })
  }
}

const columns = [
  { key: 'code', label: 'Code' },
  { key: 'name', label: 'Name' },
  { key: 'unit_type', label: 'Type' },
  { key: 'actions', label: '' },
]
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-semibold">Units</h1>
        <p class="text-gray-500">Admin-only CRUD (permission: unit.manage)</p>
      </div>
      <UButton icon="i-heroicons-plus" @click="openCreate">New unit</UButton>
    </div>

    <UCard>
      <UTable :columns="columns" :rows="units" :loading="pending">
        <template #actions-data="{ row }">
          <div class="flex justify-end gap-2">
            <UButton size="xs" variant="soft" @click="openEdit(row)">Edit</UButton>
            <UButton size="xs" color="red" variant="soft" @click="openDelete(row)">Delete</UButton>
          </div>
        </template>
      </UTable>
    </UCard>

    <!-- Create Modal -->
    <UModal v-model="isCreateOpen">
      <UCard>
        <template #header>Create unit</template>

        <div class="space-y-3">
          <UFormGroup label="Code">
            <UInput v-model="form.code" placeholder="e.g. g" />
          </UFormGroup>

          <UFormGroup label="Name">
            <UInput v-model="form.name" placeholder="e.g. Gram" />
          </UFormGroup>

          <UFormGroup label="Type">
            <USelect v-model="form.unit_type" :options="unitTypeOptions" />
          </UFormGroup>
        </div>

        <template #footer>
          <div class="flex justify-end gap-2">
            <UButton color="gray" variant="soft" @click="isCreateOpen = false">Cancel</UButton>
            <UButton @click="createUnit">Create</UButton>
          </div>
        </template>
      </UCard>
    </UModal>

    <!-- Edit Modal -->
    <UModal v-model="isEditOpen">
      <UCard>
        <template #header>Edit unit</template>

        <div class="space-y-3">
          <UFormGroup label="Code">
            <UInput v-model="form.code" />
          </UFormGroup>

          <UFormGroup label="Name">
            <UInput v-model="form.name" />
          </UFormGroup>

          <UFormGroup label="Type">
            <USelect v-model="form.unit_type" :options="unitTypeOptions" />
          </UFormGroup>
        </div>

        <template #footer>
          <div class="flex justify-end gap-2">
            <UButton color="gray" variant="soft" @click="isEditOpen = false">Cancel</UButton>
            <UButton @click="updateUnit">Save</UButton>
          </div>
        </template>
      </UCard>
    </UModal>

    <!-- Delete Modal -->
    <UModal v-model="isDeleteOpen">
      <UCard>
        <template #header>Delete unit</template>

        <p>Delete <strong>{{ deleting?.code }}</strong> ({{ deleting?.name }})?</p>

        <template #footer>
          <div class="flex justify-end gap-2">
            <UButton color="gray" variant="soft" @click="isDeleteOpen = false">Cancel</UButton>
            <UButton color="red" @click="deleteUnit">Delete</UButton>
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>
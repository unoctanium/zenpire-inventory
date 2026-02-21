<script setup lang="ts">
const { data, pending, refresh } = await useFetch('/api/me')
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-start justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold">Dashboard</h1>
        <p class="text-gray-500">MVP admin for units, recipes, ingredients, and RBAC.</p>
      </div>

      <UButton color="gray" variant="soft" :loading="pending" @click="refresh">
        Refresh session
      </UButton>
    </div>

    <UCard>
      <template #header>Session</template>

      <div v-if="pending" class="text-gray-500">Loading…</div>

      <div v-else class="space-y-2">
        <div class="flex flex-wrap gap-2 items-center">
          <span class="text-gray-500">Email:</span>
          <span class="font-medium">{{ (data as any)?.email ?? '-' }}</span>
        </div>

        <div class="flex flex-wrap gap-2 items-center">
          <span class="text-gray-500">App user:</span>
          <code class="text-xs">{{ (data as any)?.app_user_id ?? '-' }}</code>
        </div>

        <div class="space-y-2">
          <div class="text-gray-500">Permissions:</div>
          <div class="flex flex-wrap gap-2">
            <UBadge
              v-for="p in ((data as any)?.permissions ?? [])"
              :key="p"
              color="gray"
              variant="soft"
            >
              {{ p }}
            </UBadge>
            <span v-if="!((data as any)?.permissions?.length)" class="text-gray-400">None</span>
          </div>
        </div>
      </div>
    </UCard>

    <UCard>
      <template #header>Quick links</template>

      <div class="flex flex-wrap gap-2">
        <UButton to="/admin/units">Units</UButton>
        <UButton to="/admin/ingredients" color="gray" variant="soft">Ingredients (next)</UButton>
        <UButton to="/admin/recipes" color="gray" variant="soft">Recipes (next)</UButton>
        <UButton to="/admin/rbac" color="gray" variant="soft">RBAC (next)</UButton>
        <UButton to="/dev/tools" color="gray" variant="soft">Dev Tools</UButton>
      </div>
    </UCard>
  </div>
</template>
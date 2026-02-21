<script setup lang="ts">
const route = useRoute()

const nav = [
  { label: 'Home', to: '/' },
  { label: 'Units', to: '/admin/units' },
  { label: 'Ingredients', to: '/admin/ingredients' },
  { label: 'Recipes', to: '/admin/recipes' },
  { label: 'RBAC', to: '/admin/rbac' },
  { label: 'Dev Tools', to: '/dev/tools' },
]
</script>

<template>
  <div class="min-h-screen">
    <header class="border-b bg-white/80 backdrop-blur">
      <div class="mx-auto max-w-6xl px-4 py-3 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="font-semibold">Zenpire Inventory</div>
          <UBadge color="gray" variant="soft" size="xs">MVP</UBadge>
        </div>

        <div class="flex items-center gap-2">
          <UButton to="/logout" color="gray" variant="soft" size="sm">
            Logout
          </UButton>
        </div>
      </div>

      <div class="mx-auto max-w-6xl px-4 pb-3">
        <div class="flex flex-wrap gap-2">
          <UButton
            v-for="item in nav"
            :key="item.to"
            :to="item.to"
            size="xs"
            :variant="route.path === item.to ? 'solid' : 'soft'"
            color="gray"
          >
            {{ item.label }}
          </UButton>
        </div>
      </div>
    </header>

    <main class="mx-auto max-w-6xl px-4 py-6">
      <slot />
    </main>
  </div>
</template>
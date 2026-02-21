<script setup lang="ts">
const route = useRoute()
const toast = useToast()

// Client-side fetch so cookies/session are definitely included
const { data: me, refresh: refreshMe } = await useFetch('/api/me', {
  retry: false,
  server: false,
  credentials: 'include',
})

const isAuthed = computed(() => Boolean((me.value as any)?.ok))
const email = computed(() => String((me.value as any)?.email ?? ''))

const nav = [
  { label: 'Home', to: '/' },
  { label: 'Units', to: '/admin/units' },
  // placeholders for later:
  { label: 'Ingredients', to: '/admin/ingredients' },
  { label: 'Recipes', to: '/admin/recipes' },
  { label: 'RBAC', to: '/admin/rbac' },
  { label: 'Dev Tools', to: '/dev/tools' },
]

const visibleNav = computed(() => (isAuthed.value ? nav : [{ label: 'Home', to: '/' }]))

function initialsFromEmail(e: string) {
  if (!e) return '?'
  const local = e.split('@')[0] || e
  const parts = local.split(/[.\-_]/).filter(Boolean)
  const a = parts[0]?.[0] ?? local[0]
  const b = parts[1]?.[0] ?? local[1]
  return (a + (b ?? '')).toUpperCase()
}

const initials = computed(() => initialsFromEmail(email.value))

// Optional: re-check session when route changes (login/logout redirects)
watch(
  () => route.fullPath,
  async () => {
    await refreshMe()
  }
)
</script>

<template>
  <UApp>
    <div class="min-h-dvh bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-100">
      <header
        class="border-b border-zinc-200 bg-white/90 backdrop-blur dark:border-zinc-800 dark:bg-zinc-950/85"
      >
        <div class="mx-auto max-w-6xl px-4 py-3 flex items-center justify-between gap-3">
          <div class="flex items-center gap-3">
            <div class="font-semibold tracking-tight">Zenpire Inventory</div>
            <UBadge color="gray" variant="soft" size="xs">MVP</UBadge>
          </div>

          <div class="flex items-center gap-2">
            <div
              v-if="isAuthed"
              class="flex items-center gap-2 rounded-full border border-zinc-200 px-3 py-1 text-sm
                     text-zinc-800 bg-white/70
                     dark:border-zinc-800 dark:bg-zinc-900/60 dark:text-zinc-100"
            >
              <div
                class="flex h-7 w-7 items-center justify-center rounded-full
                       bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900
                       text-xs font-semibold"
                aria-hidden="true"
              >
                {{ initials }}
              </div>
              <span class="max-w-[220px] truncate">{{ email }}</span>
            </div>

            <UButton v-if="isAuthed" to="/logout" color="gray" variant="soft" size="sm">
              Logout
            </UButton>

            <UButton v-else to="/login" color="primary" variant="solid" size="sm">
              Login
            </UButton>
          </div>
        </div>

        <div class="mx-auto max-w-6xl px-4 pb-3">
          <div class="flex flex-wrap gap-2">
            <UButton
              v-for="item in visibleNav"
              :key="item.to"
              :to="item.to"
              size="xs"
              color="gray"
              :variant="route.path === item.to ? 'solid' : 'soft'"
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

    <!-- Keep this in the layout (works in your project) -->
    <UToaster/>
  </UApp>
</template>
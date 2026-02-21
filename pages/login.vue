<script setup lang="ts">
const route = useRoute()
const err = computed(() => (route.query.err ? String(route.query.err) : ''))

const email = ref('')
const password = ref('')
</script>

<template>
  <div class="min-h-[70vh] flex items-center justify-center">
    <UCard class="w-full max-w-md">
      <template #header>
        <div class="flex items-center justify-between">
          <div class="font-semibold">Login</div>
          <UBadge color="gray" variant="soft" size="xs">MVP</UBadge>
        </div>
      </template>

      <form method="post" action="/api/auth/login" class="space-y-4">
        <UFormField label="Email" name="email">
          <UInput v-model="email" name="email" type="email" required placeholder="name@example.com" />
        </UFormField>

        <UFormField label="Password" name="password">
          <UInput v-model="password" name="password" type="password" required placeholder="••••••••" />
        </UFormField>

        <UButton type="submit" block>Sign in</UButton>

        <UAlert
          v-if="err"
          color="red"
          variant="soft"
          title="Login failed"
          :description="err"
        />
      </form>
    </UCard>
  </div>
</template>
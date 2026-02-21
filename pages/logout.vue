<script setup lang="ts">
definePageMeta({ layout: 'default' })
</script>

<template>
  <div class="space-y-3">
    <UCard>
      <template #header>Logout</template>

      <p class="text-gray-600">Click to end your session.</p>

      <form method="post" action="/api/auth/logout" class="mt-4">
        <UButton type="submit" color="gray" variant="soft">Logout</UButton>
      </form>
    </UCard>
  </div>
</template>
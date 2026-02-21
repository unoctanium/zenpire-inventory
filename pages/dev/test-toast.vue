<script setup lang="ts">
const toast = useToast()

function showToast() {
  toast.add({
    title: 'Toast works',
    description: 'Nuxt UI notifications are working correctly.',
  })
}

function showErrorToast() {
  toast.add({
    title: 'Error example',
    description: 'Something went wrong.',
    color: 'red',
  })
}
</script>

<template>
  <div class="space-y-6">
    <h1 class="text-2xl font-semibold">Toast Test</h1>

    <div class="flex gap-4">
      <UButton @click="showToast">
        Show success toast
      </UButton>

      <UButton color="red" @click="showErrorToast">
        Show error toast
      </UButton>
    </div>
  </div>
</template>
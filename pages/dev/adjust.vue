<script setup lang="ts">
const ingredientId = ref('0cbc0da1-9f85-4ca9-a6ab-2e2d6ea8a3fc') // Test Rice
const result = ref('')

async function run() {
  result.value = 'Posting...'
  try {
    const res = await $fetch('/api/stock/adjust', {
      method: 'POST',
      body: {
        ingredient_id: ingredientId.value,
        quantity: 500,
        note: 'nuxt smoke test adjustment',
        unit_cost_snapshot: 0,
      },
    })
    result.value = JSON.stringify(res, null, 2)
  } catch (e: any) {
    result.value =
      `${e?.statusCode ?? ''} ${e?.statusMessage ?? ''}\n` +
      JSON.stringify(e?.data ?? {}, null, 2)
  }
}
</script>

<template>
  <main style="padding:24px;max-width:720px">
    <h1>Nuxt Dev: Stock Adjust Smoke Test</h1>

    <label>Ingredient UUID</label>
    <input v-model="ingredientId" style="padding:8px;width:100%;margin-top:8px" />

    <button @click="run" style="padding:10px;margin-top:12px">
      Run adjustment (+500)
    </button>

    <pre style="white-space:pre-wrap;margin-top:16px">{{ result }}</pre>
  </main>
</template>

<script setup lang="ts">
const out = ref('')

async function call(path: string) {
  out.value = `Calling ${path}...`
  try {
    const res = await $fetch(path, { method: 'POST' })
    out.value = JSON.stringify(res, null, 2)
  } catch (e: any) {
    out.value = `${e?.statusCode ?? ''} ${e?.statusMessage ?? ''}\n${JSON.stringify(e?.data ?? {}, null, 2)}`
  }
}
</script>

<template>
  <main style="padding:24px;max-width:720px">
    <h1>Dev Tools</h1>
    <div style="display:flex;gap:12px;margin-top:12px">
      <button @click="call('/api/dev/purge')" style="padding:10px">Purge</button>
      <button @click="call('/api/dev/seed')" style="padding:10px">Seed</button>
    </div>
    <pre style="white-space:pre-wrap;margin-top:16px">{{ out }}</pre>
  </main>
</template>
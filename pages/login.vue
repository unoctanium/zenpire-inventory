<script setup lang="ts">
const email = ref('')
const password = ref('')
const err = ref<string | null>(null)

async function login() {
  err.value = null
  try {
    await $fetch('/api/auth/login', { method: 'POST', body: { email: email.value, password: password.value } })
    await navigateTo('/')
  } catch (e: any) {
    err.value = e?.statusMessage ?? 'Login failed'
  }
}
</script>

<template>
  <main style="padding:24px;max-width:420px">
    <h1>Login</h1>
    <input v-model="email" placeholder="Email" type="email" style="padding:8px;width:100%;margin-top:8px" />
    <input v-model="password" placeholder="Password" type="password" style="padding:8px;width:100%;margin-top:8px" />
    <button @click="login" style="padding:10px;margin-top:12px">Sign in</button>
    <p v-if="err" style="color:crimson;margin-top:12px">{{ err }}</p>
  </main>
</template>

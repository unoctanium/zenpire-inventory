// https://nuxt.com/docs/api/configuration/nuxt-config

export default defineNuxtConfig({
  runtimeConfig: {
      compatibilityDate: '2025-07-15',
      devtools: { enabled: false },
      devMode: process.env.DEV_MODE === '1',
      supabaseServiceKey: process.env.SUPABASE_SERVICE_KEY,
      public: {
          supabaseUrl: process.env.NUXT_PUBLIC_SUPABASE_URL,
          supabasePublishableKey: process.env.NUXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
          iteUrl: process.env.NUXT_PUBLIC_SITE_URL,
      },
  },
  vite: {
      server: {
          allowedHosts: ['dev.zenpire.eu'],
          host: true,
          port: 3000
      }
  }
})

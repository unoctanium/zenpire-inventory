// https://nuxt.com/docs/api/configuration/nuxt-config

export default defineNuxtConfig({
    compatibilityDate: '2026-01-01',
    
    devtools: { enabled: true },
        
    modules: ['@nuxt/ui'],
    css: ['~/assets/css/main.css'],
    
    runtimeConfig: {
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

// @ts-check
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import svelte from '@astrojs/svelte';

// https://astro.build/config
export default defineConfig({
    output: 'static',
    compressHTML: true,
    integrations: [tailwind(), svelte()],
    vite: {
      plugins: [],
      resolve: {
        alias: {
          "@client": "/src/client",
          "@components": "/src/components",
          "@icons": "/src/components/icons",
          "@layouts": "/src/layouts",
          "@stores": "/src/stores",
          "@typedef": "/src/typedef",
          "@utils": "/src/utils",
        },
      },
    }
});

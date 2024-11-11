// @ts-check
import { defineConfig } from "astro/config";
import tailwind from "@astrojs/tailwind";
import svelte from "@astrojs/svelte";

import starlight from "@astrojs/starlight";
import { githubLink, NAVIGATION_MENU } from "./src/utils/configs";

// https://astro.build/config
export default defineConfig({
  site: "https://gugupay.io",
  output: "static",
  compressHTML: true,
  integrations: [
    svelte(),
    starlight({
      logo: {
        src: "./public/logo.svg",
      },
      title: "Documentation",
      description: "Documentation for GuguPay",
      social: {
        github: githubLink,
      },
      sidebar: NAVIGATION_MENU,
      components: {
        Head: "/src/components/starlight/Head.astro",
        ThemeSelect: "/src/components/starlight/ThemeSelect.astro",
      },
      favicon: "favicon.ico",
    }),
    tailwind(),
  ],
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
  },
});

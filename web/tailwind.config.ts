import { light, dark } from "daisyui-ntsd";

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{astro,html,js,svelte,ts,svx,md}"],
  safelist: ["alert-info", "alert-success", "alert-error"],
  theme: {
    extend: {},
  },
  plugins: [require("@tailwindcss/typography"), require("daisyui")],
  darkMode: ["class"], // media for system dark mode
  daisyui: {
    themes: [
      {
        light: {
          ...light,
          fontFamily: "Inter, sans-serif, system-ui",
          "--rounded-box": "1rem", // border radius rounded-box utility class, used in card and other large boxes
          "--rounded-btn": "0.5rem", // border radius rounded-btn utility class, used in buttons and similar element
          "--rounded-badge": "1.9rem", // border radius rounded-badge utility class, used in badges and similar
          "--tab-radius": "0.5rem", // border radius of tabs
        },
      },
      {
        dark: {
          ...dark,
          fontFamily: "Inter, sans-serif, system-ui",
          "--rounded-box": "1rem", // border radius rounded-box utility class, used in card and other large boxes
          "--rounded-btn": "0.5rem", // border radius rounded-btn utility class, used in buttons and similar element
          "--rounded-badge": "1.9rem", // border radius rounded-badge utility class, used in badges and similar
          "--tab-radius": "0.5rem", // border radius of tabs
        },
      },
    ],
  },
};

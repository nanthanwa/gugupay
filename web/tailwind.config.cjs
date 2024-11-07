/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,js,svelte,ts,astro}'],
  safelist: ['alert-info', 'alert-success', 'alert-error'],
  theme: {
    extend: {}
  },
  darkMode: ['class'], // media for system dark mode
  plugins: [require('daisyui')],
  daisyui: {
    styled: true,
    base: true,
    utils: true,
    logs: false,
    rtl: false,
    prefix: '',
    themes: [...require("daisyui-ntsd")]
  }
};

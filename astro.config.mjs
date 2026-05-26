import { defineConfig } from 'astro/config';
import alpinejs  from '@astrojs/alpinejs';
import sitemap   from '@astrojs/sitemap';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://mrglassproject.github.io',
  base: '',
  integrations: [
    alpinejs(),
    sitemap(),
  ],
  image: {
    domains: ['res.cloudinary.com'],
  },
  output: 'static',
  vite: {
  server: {
    open: '/mrglassproject-com',
  },
  plugins: [tailwindcss()],
},
});

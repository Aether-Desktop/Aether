import astro from '@astrojs/tailwind';
import { defineCollection, defineReference } from 'astro:content';

export const collections = {
  docs: defineCollection(),
  pages: defineCollection(),
};

export default {
  site: 'https://aether-desktop.github.io/AETHER/',
  base: '/AETHER/',
  integrations: [astro()],
  trailingSlash: 'always',
  build: { format: 'file' },
  markdown: {
    // Use our custom layout for all markdown pages
    layout: './src/layouts/PageLayout.astro',
  },
  // Ensure links are base-path safe
  redirects: {
    '/': '/AETHER/',
  },
};

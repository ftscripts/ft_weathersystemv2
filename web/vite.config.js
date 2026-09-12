import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

const JS_BUNDLE  = 'assets/index-BIFyG5fV.js';
const CSS_BUNDLE = 'assets/index-DNoMMhfR.css';

export default defineConfig({
  plugins: [svelte()],

  base: './',

  build: {
    outDir: 'dist',
    emptyOutDir: true,
    rollupOptions: {
      output: {
        entryFileNames: JS_BUNDLE,
        chunkFileNames: 'assets/[name].js',
        assetFileNames: (asset) =>
          asset.name && asset.name.endsWith('.css')
            ? CSS_BUNDLE
            : 'assets/[name][extname]',
      },
    },
  },
});

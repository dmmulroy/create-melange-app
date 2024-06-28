// @ts-check

import * as esbuild from 'esbuild';
import url from "node:url";
import fs from 'fs';
import path from 'path';

const __dirname = url.fileURLToPath(new URL(".", import.meta.url));

const nodeEnv = process.env.NODE_ENV || "production";
const isProd = nodeEnv === "production";

// Function to copy index.html to dist directory
const copyIndexHtml = () => {
  const src = path.resolve(__dirname, 'index.html');
  const distDir = path.resolve(__dirname, 'dist');
  if (!fs.existsSync(distDir)) {
    fs.mkdirSync(distDir);
  }
  const dest = path.resolve(distDir, 'index.html');
  fs.copyFileSync(src, dest);
};

/* In dev mode we run the esbuild.mjs directly from root, while in prod
we run it already from `_build/default` (see `dune` file) */
const entryPoint = nodeEnv === "production" ? 'output/src/App.mjs' : '_build/default/output/src/App.mjs';

// Build options
/** @type {import('esbuild').BuildOptions} */
const buildOptions = {
  entryPoints: [entryPoint],
  outfile: 'dist/App.mjs',
  bundle: true,
  minify: isProd,
  sourcemap: isProd,
  logLevel: "info",
  define: {
    NODE_ENV: JSON.stringify(nodeEnv)
  }
};

async function startBuild() {
  copyIndexHtml();

  if (nodeEnv === "production") {
    try {
      await esbuild.build(buildOptions);
    } catch (error) {
      console.error('Build error:', error);
      process.exit(1);
    }
  } else {
    // Create the esbuild context
    let ctx = await esbuild.context(buildOptions);

    // Watch for changes and rebuild
    await ctx.watch();

    // Start the dev server
    let { host, port } = await ctx.serve({
      servedir: 'dist',
      port: 3000, // Change the port if needed
    });
  }

}

startBuild().catch((error) => {
  console.error("Build error:", error);
  process.exit(1)
});

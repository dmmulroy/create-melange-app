import { nodeResolve } from "@rollup/plugin-node-resolve";

export default {
  build: {
    outDir: "./dist",
  },
  plugins: [nodeResolve()],
};

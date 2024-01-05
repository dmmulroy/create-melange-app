# create-melange-app


## Contributing

### Building the project from source

1. Install [OCaml](https://ocaml.org/install)
2. Install [Bun](https://bun.sh/)
3. `opam switch create .`
4. `dune build`
5. `bun install`
6. `npm run prepend-node-shebang` (b/c bun run caused Undefined Behavior)
7. `chmod a+x ./build/src/app.mjs`
8. `./build/src/app.mjs`

Questions from meta:
1. How do I install system-wide?

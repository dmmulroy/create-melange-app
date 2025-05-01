## Contributing

### Building the project from source

Install [OCaml](https://ocaml.org/install)

Install [Bun](https://bun.sh/)

Create an opam switch for the project

``` shell
opam switch create .
```

Build OCaml/Reason assets

```
dune build
```

Install JavaScr*pt assets

``` shell
bun install
```

### Configuring Editor

Activate OCaml-LSP for project

``` shell
opam install ocaml-lsp-server
```

Activate OCaml format (version must match the one specified in .ocamlformat at root of project)

``` shell
opam install ocamlformat.0.26.1
```


### Running the project

There are two options. You can run the previously built CLI script directly.
Important: you should not run script from inside CMA directory or else generated project config files will interfeer with CMA project.

``` shell
bun <path_starting_outside_cma_dir>/build/src/cli.mjs
```

Or you can link the project so it can be run as if installed globally

```shell
bun link
```

After every `dune build` you'll need to change the file perms of the built entrypoint

``` shell
chmod +x ./build/src/cli.mjs
```

Then you can call CMA as if it's globally installed. 
Note: make sure to run command outside of CMA project directory.

``` shell
create-melange-app
```

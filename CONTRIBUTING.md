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

### Running the project

There are two options. You can run

``` shell
bun build/src/cli.mjs
```

or you can link the project so it can be run as if installed globally

```shell
bun link
```

After every `dune build` you'll need to change the file perms of the built entrypoint

``` shell
chmod +x ./build/src/cli.mjs
```

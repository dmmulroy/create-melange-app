# create-melange-app

## commands

- init, i
- env-check, ec

### init

'''bash

> npx create-melange-app init [dir] > [create-melange-app] Performing system requirement checks...
> ✅ opam version 2.1.5 found
> ✅ node version v20.0.0 found

Enter your app name: my-app
Select your npmdler:

> [x] vite (default)

    [ ] webpack
    [ ] esbuild
    [ ] rollup

Select your npm dependencies:
[x] react
[ ] foobar

> [x] tailwind
> Select your Melange dependencies:

    [ ] ReasonReact
    [x] mlx (JSX support for OCaml)

> [x] melange-fetch
> [create-melange-app] Preparing your project...
> [create-melange-app] Bootstrapping OCaml dependencies...
> [create-melange-app] Bootstrapping npm dependencies...
> [create-melange-app] Project successfully created 🎉
> [create-melange-app] Run `cd my-app && dune build @dev` to launch the dev server
> '''

'''bash

> npx create-melange-app [dir]
> '''

## ux ideas/brainstorming

'''bash

> npmx create-melange-app --add-lib chart-components
> [create-melange-app] Adding new dune library `chart-components`...
> [create-melange-app] Updating dune files...
> [create-melange-app] Successfully added `chart-components` to your project 🎉
> '''

'''bash

> npmx create-melange-app --add-mel-dep melange-fetch
> [create-melange-app] Adding new melange dependency `melange-fetch`...
> [create-melange-app] Updating dune files...
> [create-melange-app] Installing from opam...
> [create-melange-app] Successfully added `melange-fetch` to your project 🎉
> '''

open Bindings

let eval_env = "eval $(opam env)"
let with_eval_env cmd = Printf.sprintf "%s && %s" eval_env cmd

module Version : Process.S with type input = unit and type output = string =
struct
  type input = unit
  type output = string

  let name = "opam --version"

  let exec (_ : input) =
    let options = Node.Child_process.option ~encoding:"utf8" () in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const "Failed to get opam version")
  ;;
end

module Update : Process.S with type input = string and type output = string =
struct
  type input = string
  type output = string

  let name = "opam update"

  let error_message =
    {|
    Failed to update opam

    The scaffolding process failed while running `opam update`. Opam is OCaml
    and ReasonML's package manager. Please try running `create-melange-app` 
    again and choose to `Clear` the project directory created by this run.

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
  ;;

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end

module Install_dune :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "opam install dune"

  let error_message =
    {|
    Failed to install dune to your local opam switch

    The scaffolding process failed while running `opam install dune`. 
    Opam is OCaml and ReasonML's package manager. Dune is Ocaml and ReasonML's 
    build tool. 

    Please try `cd`ing into the project directory created by 
    `create-melange-app` and running the following commands:

    eval $(opam env)
    opam install dune
    dune build @install
    opam install ocaml-lsp-server ocamlformat odoc utop --yes
    opam install . --deps-only --yes
    dune build

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.

    If you open an issue, please `cd` into the directory created by 
    `create-melange-app` and include the output from the following commands: 

    `opam switch list`,
    `opam install ocaml-lsp-server ocamlformat odoc utop --yes`, 
    `cat dune-project`, and `cat dune`
  |}
  ;;

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec (with_eval_env name) options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end

module Create_switch :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "opam switch create . 5.1.1 --deps-only --yes"

  let error_message =
    {|
    Failed to create a local opam switch using OCaml 5.1.1 

    The scaffolding process failed while running 
    `opam switch create . 5.1.1 --deps-only --yes`. Opam is OCaml and ReasonML's 
    package manager. Please try running `create-melange-app` again and choose to 
    `Clear` the project directory created by this run. If the problem persists,
    please open an issue at github.com/dmmulroy/create-melange-app/issues, and 
    or join our discord for help at https://discord.gg/fNvVdsUWHE.

    If you open an issue, please `cd` into the directory created by 
    `create-melange-app` and include the output from the following commands: 

    `opam switch list`,`opam switch create . 5.1.1 --deps-only --yes`, 
    `cat dune-project`, and `cat dune`
  |}
  ;;

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end

module Install_dev_dependencies :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "opam install ocaml-lsp-server ocamlformat odoc utop --yes"

  let error_message =
    {|
    Failed to install OCaml dev dependencies to your local opam switch

    The scaffolding process failed while running 
    `opam install ocaml-lsp-server ocamlformat odoc utop --yes`. Opam is OCaml 
    and ReasonML's package manager. 

    Please try `cd`ing into the project directory created by 
    `create-melange-app` and running the following commands:

    eval $(opam env)
    opam install ocaml-lsp-server ocamlformat odoc utop --yes
    opam install . --deps-only --yes
    dune build

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.

    If you open an issue, please `cd` into the directory created by 
    `create-melange-app` and include the output from the following commands: 

    `opam switch list`,
    `opam install ocaml-lsp-server ocamlformat odoc utop --yes`, 
    `cat dune-project`, and `cat dune`
  |}
  ;;

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec (with_eval_env name) options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end

module Install_dependencies :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "opam install . --deps-only --yes"

  let error_message =
    {|
    Failed to install OCaml dependencies to your local opam switch

    The scaffolding process failed while running 
    `opam install . --deps-only --yes`. Opam is OCaml and ReasonML's package 
    manager. 

    Please try `cd`ing into the project directory created by 
    `create-melange-app` and running the following commands:

    eval $(opam env)
    opam install . --deps-only --yes
    dune build

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.

    If you open an issue, please `cd` into the directory created by 
    `create-melange-app` and include the output from the following commands: 

    `opam switch list`,
    `opam install . --deps-only --yes`, 
    `cat dune-project`, and `cat dune`
  |}
  ;;

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec (with_eval_env name) options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end
(* eval $(opam env) *)

module Dependency = Dependency.Make (struct
  include Version

  let name = "Opam"

  let help =
    {|
    Opam is the package manager for OCaml and is required to run create-melange-app.  

    Here's how to install it:

      On macOS: Use Homebrew by running `brew install opam` in your terminal.

      On Linux: Use your distribution's package manager. For example, on Ubuntu, run `sudo apt-get install opam`.

      On Windows: It's recommended to use WSL (Windows Subsystem for Linux) and then follow the Linux installation instructions.

      After installing, initialize opam with `opam init` in your terminal.

      For more information, visit https://ocaml.org/docs/installing-ocaml#installing-ocaml 
  |}
  ;;

  let required = true
  let input = ()
end)

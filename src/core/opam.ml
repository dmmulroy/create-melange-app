open Bindings

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

module Create_switch :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "opam switch create . 5.1.1 --deps-only --yes"

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const "Failed to create opam switch")
  ;;
end

module Install_dev_dependencies :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "opam install ocaml-lsp-server ocamlformat odoc utop --yes"

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const "Failed to install dev dependencies")
  ;;
end

module Install_dependencies :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "opam install . --deps-only --yes"

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const "Failed to install dev dependencies")
  ;;
end

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

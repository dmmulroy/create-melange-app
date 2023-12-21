open Bindings
open Context_plugin

module Version : Process.S with type input = unit and type output = string =
struct
  type input = unit
  type output = string

  let name = "opam --version"

  let exec (_ : input) =
    let options = Node.Child_process.option ~encoding:"utf8" () in
    Nodejs.Child_process.async_exec name options
    |> Js.Promise.then_ (fun value -> Js.Promise.resolve @@ Ok value)
    |> Js.Promise.catch (fun _err ->
           Js.Promise.resolve @@ Error "Failed to get opam version")
  ;;
end

module Create_switch :
  Process.S with type input = unit and type output = string = struct
  type input = unit
  type output = string

  let name = "opam switch create . 5.1.1 --deps-only --yes"

  let exec (_ : input) =
    let options = Node.Child_process.option ~encoding:"utf8" () in
    Nodejs.Child_process.async_exec name options
    |> Js.Promise.then_ (fun value -> Js.Promise.resolve @@ Ok value)
    |> Js.Promise.catch (fun _err ->
           Js.Promise.resolve @@ Error "Failed to get opam version")
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

module Plugin = struct
  module Create_switch = struct
    include Plugin.Make_process (struct
      include Create_switch

      let stage = `Post_compile
      let input_of_context _ = Ok ()
    end)
  end
end

open Bindings

module Build : Process.S with type input = string and type output = string =
struct
  type input = string
  type output = string

  let name = "dune build"

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const "Failed to build project with dune")
  ;;
end

module Install_dev_dependencies :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "opam install ocaml-lsp-server ocamlformat odoc utop"

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

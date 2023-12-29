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

module Dune_file = struct
  module Ppx = struct
    type t = { name : string }

    let make name = { name }
  end

  type t = { name : string; ppxs : Ppx.t list }

  let make ?(ppxs = []) name = { name; ppxs }

  let to_json dune_file =
    let dict = Js.Dict.empty () in
    Js.Dict.set dict "name" (Js.Json.string dune_file.name);
    Js.Dict.set dict "ppxs"
      (dune_file.ppxs
      |> List.map (fun (ppx : Ppx.t) -> Js.Json.string ppx.name)
      |> Array.of_list |> Js.Json.array);
    Js.Json.object_ dict
  ;;

  let template ~project_directory ~template_directory ?(ppxs = []) name =
    let template_directory =
      Node.Path.join [| project_directory; template_directory |]
    in
    Template.make ~name:"dune.tmpl" ~value:(make ~ppxs name)
      ~dir:template_directory ~to_json
  ;;
end

module Dune_project = struct
  module String_map = Map.Make (String)

  module Dependency = struct
    type t = {
      name : string;
      version : string option;
          (* TODO: Add version_constraint: version_constraint option *)
          (* TODO: Add filter: filter option *)
    }

    let make ?version name = { name; version }
  end

  let default_dependencies =
    [
      Dependency.make ~version:">= 5.1.0" "ocaml";
      Dependency.make ~version:">= 3.11" "dune";
      Dependency.make ~version:">= 2.1.0" "melange";
      Dependency.make ~version:">= 3.10.0" "reason";
      Dependency.make "opam-check-npm-deps";
      Dependency.make "ppx_deriving";
    ]
    |> List.fold_left
         (fun acc (dependency : Dependency.t) ->
           String_map.add dependency.name dependency acc)
         String_map.empty
  ;;

  type t = { name : string; depends : Dependency.t String_map.t }

  let empty = { name = ""; depends = default_dependencies }
  let make ~name ~depends = { name; depends }
  let set_name name dune_project = { dune_project with name }

  let add_dependency (dependency : Dependency.t) dune_project =
    {
      dune_project with
      depends = String_map.add dependency.name dependency dune_project.depends;
    }
  ;;

  let add_dependencies dependencies dune_project =
    List.fold_left (Fun.flip add_dependency) dune_project dependencies
  ;;

  let to_json dune_project =
    let dict = Js.Dict.empty () in
    Js.Dict.set dict "name" (Js.Json.string dune_project.name);
    let depends =
      String_map.to_list dune_project.depends
      |> List.map (fun (key, (dependency : Dependency.t)) ->
             let version_json =
               match dependency.version with
               | None -> Js.Json.null
               | Some version -> Js.Json.string version
             in
             (key, version_json))
      |> Js.Dict.fromList |> Js.Json.object_
    in
    Js.Dict.set dict "depends" depends;
    Js.Json.object_ dict
  ;;

  let template ~project_name ~project_directory =
    let template_directory = Node.Path.join [| project_directory; "./" |] in
    Template.make ~name:"dune-project.tmpl"
      ~value:{ empty with name = project_name }
      ~dir:template_directory ~to_json
  ;;
end

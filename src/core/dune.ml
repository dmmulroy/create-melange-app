open Bindings

module Build : Process.S with type input = string and type output = string =
struct
  type input = string
  type output = string

  let name = "opam exec -- dune build"

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

module Install : Process.S with type input = string and type output = string =
struct
  (* We are using this command to force dune to generate an opam file without
     erroring prior to the first build *)
  type input = string
  type output = string

  let name = "dune build @install"

  let exec (project_directory : input) =
    let options =
      Node.Child_process.option ~cwd:project_directory ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const "Failed to 'dune build @install'")
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

module Dune_file = struct
  (* Note these are the bare minimum stanzas/fields required to get our project to build *)
  module Alias = struct
    type t = { name : string; deps : string list }

    let empty = { name = ""; deps = [] }
    let set_name name alias = { alias with name }
    let add_dep dep alias = { alias with deps = dep :: alias.deps }
    let add_deps deps alias = { alias with deps = deps @ alias.deps }

    let to_json alias =
      let dict = Js.Dict.empty () in
      Js.Dict.set dict "name" (Js.Json.string alias.name);
      Js.Dict.set dict "deps"
        (alias.deps |> List.map Js.Json.string |> Array.of_list |> Js.Json.array);
      Js.Json.object_ dict
    ;;
  end

  module Rule = struct
    type t = {
      alias : string;
      targets : string list;
      deps : string list;
      action : string;
    }

    let empty = { alias = ""; targets = []; deps = []; action = "" }
    let add_target target rule = { rule with targets = target :: rule.targets }

    let add_targets targets rule =
      { rule with targets = targets @ rule.targets }
    ;;

    let add_dep dep rule = { rule with deps = dep :: rule.deps }
    let add_deps deps rule = { rule with deps = deps @ rule.deps }
    let set_action action rule = { rule with action }
    let set_alias alias rule = { rule with alias }

    let to_json rule =
      let dict = Js.Dict.empty () in
      Js.Dict.set dict "alias" (Js.Json.string rule.alias);
      Js.Dict.set dict "targets"
        (rule.targets |> List.map Js.Json.string |> Array.of_list
       |> Js.Json.array);
      Js.Dict.set dict "deps"
        (rule.deps |> List.map Js.Json.string |> Array.of_list |> Js.Json.array);
      Js.Dict.set dict "action" (Js.Json.string rule.action);
      Js.Json.object_ dict
    ;;
  end

  module Library = struct
    type t = { alias : string; libraries : string list; ppxs : string list }

    let empty = { alias = ""; libraries = []; ppxs = [] }
    let set_alias alias library = { library with alias }

    let add_library lib library =
      { library with libraries = lib :: library.libraries }
    ;;

    let add_libraries libraries library =
      { library with libraries = libraries @ library.libraries }
    ;;

    let to_json library =
      let dict = Js.Dict.empty () in
      Js.Dict.set dict "alias" (Js.Json.string library.alias);
      Js.Dict.set dict "libraries"
        (library.libraries |> List.map Js.Json.string |> Array.of_list
       |> Js.Json.array);
      Js.Dict.set dict "ppxs"
        (library.ppxs |> List.map Js.Json.string |> Array.of_list
       |> Js.Json.array);
      Js.Json.object_ dict
    ;;
  end

  type t = {
    project_name : string;
    aliases : Alias.t list;
    rules : Rule.t list;
    libraries : Library.t list;
  }

  let empty = { project_name = ""; aliases = []; rules = []; libraries = [] }
  let set_project_name project_name dune_file = { dune_file with project_name }

  let add_alias alias dune_file =
    { dune_file with aliases = alias :: dune_file.aliases }
  ;;

  let add_aliases aliases dune_file =
    { dune_file with aliases = aliases @ dune_file.aliases }
  ;;

  let add_rule rule dune_file =
    { dune_file with rules = rule :: dune_file.rules }
  ;;

  let add_rules rules dune_file =
    { dune_file with rules = rules @ dune_file.rules }
  ;;

  let add_library library dune_file =
    { dune_file with libraries = library :: dune_file.libraries }
  ;;

  let add_libraries libraries dune_file =
    { dune_file with libraries = libraries @ dune_file.libraries }
  ;;

  let to_json = function
    | { project_name; aliases; rules; libraries } ->
        let dict = Js.Dict.empty () in
        Js.Dict.set dict "name" (Js.Json.string project_name);
        Js.Dict.set dict "aliases"
          (aliases |> List.map Alias.to_json |> Array.of_list |> Js.Json.array);
        Js.Dict.set dict "rules"
          (rules |> List.map Rule.to_json |> Array.of_list |> Js.Json.array);
        Js.Dict.set dict "libraries"
          (libraries |> List.map Library.to_json |> Array.of_list
         |> Js.Json.array);
        Js.Json.object_ dict
  ;;

  let template ~project_directory ~template_directory dune_file =
    let template_directory =
      Node.Path.join [| project_directory; template_directory |]
    in
    Template.make ~name:"dune.tmpl" ~value:dune_file ~dir:template_directory
      ~to_json
  ;;
end

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
    let set_alias alias rule = { rule with alias }
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
    type t = {
      alias : string;
      modes : string;
      libraries : string list;
      ppxs : string list;
    }

    let empty = { alias = ""; modes = ""; libraries = []; ppxs = [] }
    let set_alias alias library = { library with alias }
    let set_modes modes library = { library with modes }

    let add_library lib library =
      { library with libraries = lib :: library.libraries }
    ;;

    let add_libraries libraries library =
      { library with libraries = libraries @ library.libraries }
    ;;

    let add_ppx ppx library = { library with ppxs = ppx :: library.ppxs }
    let add_ppxs ppxs library = { library with ppxs = ppxs @ library.ppxs }

    let to_json library =
      let dict = Js.Dict.empty () in
      Js.Dict.set dict "alias" (Js.Json.string library.alias);
      Js.Dict.set dict "modes" (Js.Json.string library.modes);
      Js.Dict.set dict "libraries"
        (library.libraries |> List.map Js.Json.string |> Array.of_list
       |> Js.Json.array);
      Js.Dict.set dict "ppxs"
        (library.ppxs |> List.map Js.Json.string |> Array.of_list
       |> Js.Json.array);
      Js.Json.object_ dict
    ;;
  end

  module Melange_emit = struct
    type t = {
      alias : string;
      target : string;
      libraries : string list;
      module_system : string;
    }

    let empty = { alias = ""; target = ""; libraries = []; module_system = "" }
    let set_alias alias melange_emit = { melange_emit with alias }
    let set_target target melange_emit = { melange_emit with target }

    let add_library library melange_emit =
      { melange_emit with libraries = library :: melange_emit.libraries }
    ;;

    let add_libraries libraries melange_emit =
      { melange_emit with libraries = libraries @ melange_emit.libraries }
    ;;

    let set_module_system module_system melange_emit =
      { melange_emit with module_system }
    ;;

    let to_json melange_emit =
      let dict = Js.Dict.empty () in
      Js.Dict.set dict "alias" (Js.Json.string melange_emit.alias);
      Js.Dict.set dict "target" (Js.Json.string melange_emit.target);
      Js.Dict.set dict "libraries"
        (melange_emit.libraries |> List.map Js.Json.string |> Array.of_list
       |> Js.Json.array);
      Js.Dict.set dict "module_system"
        (Js.Json.string melange_emit.module_system);
      Js.Json.object_ dict
    ;;
  end

  type t = {
    project_name : string;
    dirs : string list;
    aliases : Alias.t list;
    rules : Rule.t list;
    libraries : Library.t list;
    melange_emit : Melange_emit.t list;
  }

  let empty =
    {
      project_name = "";
      dirs = [];
      aliases = [];
      rules = [];
      libraries = [];
      melange_emit = [];
    }
  ;;

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

  let add_melange_emit melange_emit dune_file =
    { dune_file with melange_emit = melange_emit :: dune_file.melange_emit }
  ;;

  let add_melange_emits melange_emits dune_file =
    { dune_file with melange_emit = melange_emits @ dune_file.melange_emit }
  ;;

  let to_json = function
    | { project_name; dirs; aliases; rules; libraries; melange_emit } ->
        let dict = Js.Dict.empty () in
        Js.Dict.set dict "project_name" (Js.Json.string project_name);
        Js.Dict.set dict "dirs"
          (dirs |> List.map Js.Json.string |> Array.of_list |> Js.Json.array);
        Js.Dict.set dict "aliases"
          (aliases |> List.map Alias.to_json |> Array.of_list |> Js.Json.array);
        Js.Dict.set dict "rules"
          (rules |> List.map Rule.to_json |> Array.of_list |> Js.Json.array);
        Js.Dict.set dict "libraries"
          (libraries |> List.map Library.to_json |> Array.of_list
         |> Js.Json.array);
        Js.Dict.set dict "melange_emit"
          (melange_emit
          |> List.map Melange_emit.to_json
          |> Array.of_list |> Js.Json.array);
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

let vite_root_dune_file project_name =
  let open Dune_file in
  empty
  |> add_rule
       (Rule.empty |> Rule.set_alias "vite" |> Rule.add_target "dir dist"
       |> Rule.add_deps
            [
              "alias_rec" ^ project_name;
              ":vite ./vite.config.js";
              ":index_html ./index.html";
            ]
       |> Rule.set_action {|system "../../node_modules/.bin/vite build"|})
  |> add_alias
       (Alias.empty |> Alias.set_name "all" |> Alias.add_dep "alias_rec vite")
  |> add_melange_emit
       (Melange_emit.empty
       |> Melange_emit.set_alias project_name
       |> Melange_emit.set_target "output"
       |> Melange_emit.add_library "app"
       |> Melange_emit.set_module_system "es6 mjs")
;;

let app_library_dune_file ?(is_react_app = false) () =
  let open Dune_file in
  let ppxs =
    match is_react_app with
    | true -> [ "melange.ppx"; "reason-react-ppx" ]
    | false -> [ "melange.ppx" ]
  in
  empty
  |> add_library
       (Library.empty |> Library.set_alias "app"
       |> Library.set_modes "melange"
       |> Library.add_ppxs ppxs)
;;

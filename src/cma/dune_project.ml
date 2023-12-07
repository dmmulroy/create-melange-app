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
    Dependency.make ~version:">=5.1.0" "ocaml";
    Dependency.make ~version:">= 3.11" "dune";
    Dependency.make ~version:">=2.1.0" "melange";
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

let name = "dune-project.tmpl"
let empty = { name = ""; depends = default_dependencies }
let make ~name ~depends = { name; depends }
let set_name name dune_project = { dune_project with name }

let add_depends (dependency : Dependency.t) dune_project =
  {
    dune_project with
    depends = String_map.add dependency.name dependency dune_project.depends;
  }
;;

let to_json dune_project =
  let obj = Js.Dict.empty () in
  Js.Dict.set obj "name" (Js.Json.string dune_project.name);
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
  Js.Dict.set obj "depends" depends;
  Js.Json.object_ obj
;;

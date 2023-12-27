module String_map = Map.Make (String)
module Make_template = Template.Make

module Dependency = struct
  type descriptor = { name : string; version : string }
  type t = Regular of descriptor | Development of descriptor

  let make ~kind ~name ~version =
    match kind with
    | `Regular -> Regular { name; version }
    | `Development -> Development { name; version }
  ;;

  let name = function
    | Regular dependency | Development dependency -> dependency.name
  ;;

  let version = function
    | Regular dependency | Development dependency -> dependency.version
  ;;
end

module Script = struct
  type t = { name : string; script : string }

  let make ~name ~script = { name; script }
end

type t = {
  name : string;
  dependencies : Dependency.t String_map.t;
  dev_dependencies : Dependency.t String_map.t;
  scripts : Script.t String_map.t;
}

let empty =
  {
    name = "";
    dependencies = String_map.empty;
    dev_dependencies = String_map.empty;
    scripts = String_map.empty;
  }
;;

let set_name name pkg = { pkg with name }

let add_dependency dependency pkg =
  match dependency with
  | Dependency.Regular _ ->
      {
        pkg with
        dependencies =
          String_map.add
            (Dependency.name dependency)
            dependency pkg.dependencies;
      }
  | Dependency.Development _ ->
      {
        pkg with
        dev_dependencies =
          String_map.add
            (Dependency.name dependency)
            dependency pkg.dev_dependencies;
      }
;;

let add_script (script : Script.t) pkg =
  { pkg with scripts = String_map.add script.name script pkg.scripts }
;;

let depedencies_to_json dependencies =
  String_map.to_list dependencies
  |> List.fold_left
       (fun dict (_, dependency) ->
         Js.Dict.set dict
           (Dependency.name dependency)
           (Dependency.version dependency |> Js.Json.string);
         dict)
       (Js.Dict.empty ())
  |> Js.Json.object_
;;

let to_json pkg =
  let dict = Js.Dict.empty () in
  Js.Dict.set dict "name" (Js.Json.string pkg.name);
  let scripts =
    String_map.to_list pkg.scripts
    |> List.map (fun (_key, Script.{ name; script }) ->
           (name, Js.Json.string script))
    |> Js.Dict.fromList |> Js.Json.object_
  in
  Js.Dict.set dict "scripts" scripts;
  let dependencies = depedencies_to_json pkg.dependencies in
  Js.Dict.set dict "dependencies" dependencies;
  let dev_dependencies = depedencies_to_json pkg.dev_dependencies in
  Js.Dict.set dict "devDependencies" dev_dependencies;
  Js.Json.object_ dict
;;

let template project_name =
  Template_v2.make ~name:"package.json.tmpl"
    ~value:{ empty with name = project_name }
    ~to_json
;;

module Template = struct
  include Make_template (struct
    type nonrec t = t

    let name = "package.json.tmpl"
    let to_json = to_json
  end)
end

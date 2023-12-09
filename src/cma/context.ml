module String_map = Map.Make (String)

type t = {
  configuration : Configuration.t;
  (* Template name -> Template module *)
  templates : (module Template.S) String_map.t;
  (* Template key -> Template value*)
  template_values : Hmap.t;
}

let make (configuration : Configuration.t) =
  let pkg = Package_json.empty |> Package_json.set_name configuration.name in
  let dune_project =
    Dune_project.empty |> Dune_project.set_name configuration.name
  in
  let template_values =
    Hmap.empty
    |> Hmap.add Package_json.Template.key pkg
    |> Hmap.add Template.Dune_project_template.key dune_project
  in
  let templates =
    String_map.empty
    |> String_map.add Package_json.Template.name
         (module Package_json.Template : Template.S)
    |> String_map.add Template.Dune_project_template.name
         (module Template.Dune_project_template : Template.S)
  in
  { configuration; templates; template_values }
;;

let get_template template_name ctx =
  String_map.find_opt template_name ctx.templates
;;

let get_template_value template_key ctx =
  Hmap.find template_key ctx.template_values
;;

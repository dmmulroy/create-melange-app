type t = Configuration.t

let to_json = Configuration.to_json

let template (configuration : Configuration.t) =
  let template_directory =
    Node.Path.join [| configuration.directory; "./"; "src" |]
  in
  let name =
    match (configuration.syntax_preference, configuration.is_react_app) with
    | _, true -> "App.re.tmpl"
    | `OCaml, false -> "app.ml.tmpl"
    | `ReasonML, false -> "app.re.tmpl"
  in

  Template.make ~name ~value:configuration ~dir:template_directory ~to_json
;;

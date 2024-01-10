open Bindings

type t = Configuration.t

let to_json (readme : Configuration.t) =
  let dict = Js.Dict.empty () in
  Js.Dict.set dict "name" (Js.Json.string readme.name);
  Js.Dict.set dict "directory" (Js.Json.string readme.directory);
  Js.Dict.set dict "node_package_manager"
    (Js.Json.string
       (readme.node_package_manager |> Nodejs.Process.npm_user_agent_to_string));
  Js.Dict.set dict "syntax_preference"
    (Js.Json.string
       (Configuration.syntax_preference_to_string readme.syntax_preference));
  Js.Dict.set dict "bundler"
    (Js.Json.string
       (Bundler.to_string readme.bundler |> String.capitalize_ascii));
  (* We add a derived field to feed into our template for convenience *)
  Js.Dict.set dict "is_webpack_app"
    (Js.Json.boolean (readme.bundler == Webpack));
  Js.Json.object_ dict
;;

let template (configuration : Configuration.t) : t Template.t =
  let template_directory = Node.Path.join [| configuration.directory; "./" |] in
  Template.make ~name:"README.md.tmpl" ~value:configuration
    ~dir:template_directory ~to_json
;;

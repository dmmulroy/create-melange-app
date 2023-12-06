open Package_json
module String_map = Map.Make (String)

let dev_dependencies =
  [
    Dependency.make ~kind:`Development ~name:"webpack" ~version:"^5.89.0";
    Dependency.make ~kind:`Development ~name:"webpack-cli" ~version:"^5.1.4";
    Dependency.make ~kind:`Development ~name:"webpack-dev-server"
      ~version:"^4.15.1";
  ]
;;

let scripts =
  String_map.empty
  |> String_map.add "bundle"
       "webpack --mode production --entry \
        ./_build/default/src/output/src/app.js"
  |> String_map.add "server"
       "webpack serve --open --mode development --entry \
        ./_build/default/src/output/src/app.js"
;;

let files =
  [ Node.Path.join [| "templates"; "extras"; "webpack"; "webpack.config.js" |] ]
;;

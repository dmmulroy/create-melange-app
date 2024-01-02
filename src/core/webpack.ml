open Bindings
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
  [
    Script.make ~name:"bundle"
      ~script:
        "webpack --mode production --entry \
         ./_build/default/src/output/src/App.js";
    Script.make ~name:"server"
      ~script:
        "webpack serve --open --mode development --entry \
         ./_build/default/src/output/src/App.js";
  ]
;;

module V2 = struct
  module Copy_webpack_config_js :
    Process.S with type input = string and type output = unit = struct
    type input = string
    (** The project directory name *)

    type output = unit

    let name = "copy webpack.config.js"

    let webpack_config_js_path =
      Node.Path.join
        [|
          Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
          "..";
          "templates";
          "extensions";
          "webpack";
          "webpack.config.js";
        |]
    ;;

    let exec (project_dir_name : input) =
      let dest =
        Node.Path.join [| project_dir_name; "/"; "webpack.config.js" |]
      in
      Fs.copy_file_v2 ~dest webpack_config_js_path
    ;;
  end
end

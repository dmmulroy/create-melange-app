[@@@ocaml.warning "-32"]

open Bindings
open Package_json
module String_map = Map.Make (String)

let dev_dependencies =
  [
    Dependency.make ~kind:`Development ~name:"webpack" ~version:"^5.89.0";
    Dependency.make ~kind:`Development ~name:"webpack-cli" ~version:"^5.1.4";
    Dependency.make ~kind:`Development ~name:"webpack-dev-server"
      ~version:"^4.15.1";
    Dependency.make ~kind:`Development ~name:"concurrently" ~version:"^8.2.2";
  ]
;;

let scripts =
  [
    Script.make ~name:"dev"
      ~script:"dune build && concurrently 'npm:webpack-dev' 'npm:dune-watch'";
    Script.make ~name:"webpack-dev"
      ~script:
        "webpack serve --open --mode development --entry \
         ./_build/default/output/src/App.mjs";
    Script.make ~name:"build" ~script:"dune build";
    Script.make ~name:"dune-watch" ~script:"dune build -w";
  ]
;;

module Copy_index_html :
  Process.S with type input = string and type output = unit = struct
  type input = string
  (** The project directory name *)

  type output = unit

  let name = "copy index.html"

  let webpack_public_dir_path =
    Node.Path.join
      [|
        Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
        "..";
        "templates";
        "extensions";
        "webpack";
        "index.html";
      |]
  ;;

  let name = "copy index.html"

  let exec (project_dir_name : input) =
    let dest = Node.Path.join [| project_dir_name; "/"; "index.html" |] in
    Fs.copy_file ~dest webpack_public_dir_path
  ;;
end

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
    Fs.copy_file ~dest webpack_config_js_path
  ;;
end

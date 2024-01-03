open Bindings
open Package_json
module String_map = Map.Make (String)

let dev_dependencies =
  [
    Dependency.make ~kind:`Development ~name:"vite" ~version:"^4.5.0";
    Dependency.make ~kind:`Development ~name:"vite-plugin-melange"
      ~version:"^2.2.0";
    Dependency.make ~kind:`Development ~name:"@rollup/plugin-node-resolve"
      ~version:"^15.2.3";
    Dependency.make ~kind:`Development ~name:"concurrently" ~version:"^8.2.2";
  ]
;;

let scripts =
  [
    Script.make ~name:"dev"
      ~script:"dune build && concurrently 'npm:vite-dev' 'npm:dune-watch'";
    Script.make ~name:"vite-dev" ~script:"vite _build/default";
    Script.make ~name:"build" ~script:"dune build";
    Script.make ~name:"dune-watch" ~script:"dune build -w";
    Script.make ~name:"serve" ~script:"dune build && vite preview";
  ]
;;

module V2 = struct
  module Copy_vite_config_js :
    Process.S with type input = string and type output = unit = struct
    type input = string
    (** The project directory name *)

    type output = unit

    let name = "copy vite.config.js"

    let vite_config_js_path =
      Node.Path.join
        [|
          Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
          "..";
          "templates";
          "extensions";
          "vite";
          "vite.config.js";
        |]
    ;;

    let exec (project_dir_name : input) =
      let dest = Node.Path.join [| project_dir_name; "/"; "vite.config.js" |] in
      Fs.copy_file_v2 ~dest vite_config_js_path
    ;;
  end

  module Copy_index_html :
    Process.S with type input = string and type output = unit = struct
    type input = string
    (** The project directory name *)

    type output = unit

    let name = "copy index.html"

    let vite_config_js_path =
      Node.Path.join
        [|
          Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
          "..";
          "templates";
          "extensions";
          "vite";
          "index.html";
        |]
    ;;

    let exec (project_dir_name : input) =
      let dest = Node.Path.join [| project_dir_name; "/"; "index.html" |] in
      Fs.copy_file_v2 ~dest vite_config_js_path
    ;;
  end
end

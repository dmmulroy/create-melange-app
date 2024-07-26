open Bindings
open Package_json
module String_map = Map.Make (String)

let dev_dependencies =
  [
    Dependency.make ~kind:`Development ~name:"esbuild" ~version:"^0.21.4";
    Dependency.make ~kind:`Development ~name:"concurrently" ~version:"^8.2.2";
  ]
;;

let scripts ~project_name =
  [
    Script.make ~name:"dev"
      ~script:"concurrently 'npm:esbuild-dev' 'npm:dune-watch'";
    Script.make ~name:"build" ~script:"dune build";
    Script.make ~name:"dune-watch"
      ~script:("dune build @" ^ project_name ^ " -w");
    Script.make ~name:"esbuild-dev" ~script:"NODE_ENV=\\\"development\\\" node esbuild.mjs";
  ]
;;

module Copy_esbuild_config_js :
  Process.S with type input = string and type output = unit = struct
  type input = string
  (** The project directory name *)

  type output = unit

  let name = "copy esbuild.mjs"

  let esbuild_mjs_path =
    Node.Path.join
      [|
        Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
        "..";
        "templates";
        "extensions";
        "esbuild";
        "esbuild.mjs";
      |]
  ;;

  let error_message =
    {|
    Failed to copy esbuild.mjs to project directory 

    The scaffolding process failed while copying `esbuild.mjs`. Please try 
    running `create-melange-app` again and choose to `Clear` the project 
    directory created by this run.

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
  ;;

  let exec (project_dir_name : input) =
    let dest = Node.Path.join [| project_dir_name; "/"; "esbuild.mjs" |] in
    Fs.copy_file ~dest esbuild_mjs_path
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end

module Copy_index_html :
  Process.S with type input = string and type output = unit = struct
  type input = string
  (** The project directory name *)

  type output = unit

  let name = "copy index.html"

  let esbuild_config_html_path =
    Node.Path.join
      [|
        Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
        "..";
        "templates";
        "extensions";
        "esbuild";
        "index.html";
      |]
  ;;

  let error_message =
    {|
    Failed to copy esbuild's index.html to project directory 

    The scaffolding process failed while copying `index.html`. Please try 
    running `create-melange-app` again and choose to `Clear` the project 
    directory created by this run.

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
  ;;

  let exec (project_dir_name : input) =
    let dest = Node.Path.join [| project_dir_name; "/"; "index.html" |] in
    Fs.copy_file ~dest esbuild_config_html_path
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end

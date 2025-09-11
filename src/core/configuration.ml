open Bindings

type overwrite_preference = [ `Clear | `Overwrite ]

let overwrite_preference_to_string = function
  | `Clear -> "Clear"
  | `Overwrite -> "Overwrite"
;;

type syntax_preference = [ `OCaml | `ReasonML ]

let syntax_preference_to_string = function
  | `OCaml -> "OCaml"
  | `ReasonML -> "ReasonML"
;;

let syntax_preference_of_string str =
  str |> String.lowercase_ascii
  |> function
  | "ocaml" -> `OCaml
  | "reasonml" -> `ReasonML
  | _ -> failwith "Invalid syntax preference"
;;

type project_type = [ `Frontend | `Fullstack ]

let project_type_to_string = function
  | `Frontend -> "Frontend"
  | `Fullstack -> "Fullstack"
;;

let project_type_of_string str =
  str |> String.lowercase_ascii
  |> function
  | "frontend" -> `Frontend
  | "fullstack" -> `Fullstack
  | _ -> failwith "Invalid project type"
;;

type backend_framework = [ `Dream ]

let backend_framework_to_string = function `Dream -> "Dream"

let backend_framework_of_string str =
  str |> String.lowercase_ascii
  |> function "dream" -> `Dream | _ -> failwith "Invalid backend framework"
;;

type api_features = [ `REST ]

let api_features_to_string = function `REST -> "REST"

let api_features_of_string str =
  str |> String.lowercase_ascii
  |> function "rest" -> `REST | _ -> failwith "Invalid API features"
;;

type t = {
  name : string;
  directory : string;
  node_package_manager : Nodejs.Process.npm_user_agent;
  syntax_preference : syntax_preference;
  project_type : project_type;
  backend_framework : backend_framework option;
  api_features : api_features option;
  bundler : Bundler.t;
  is_react_app : bool;
  has_tests : bool;
  initialize_git : bool;
  initialize_npm : bool;
  initialize_ocaml_toolchain : bool;
  overwrite : overwrite_preference option;
}

let make ~name ~directory ~syntax_preference ~project_type ~bundler
    ~is_react_app ~has_tests ~initialize_git ~initialize_npm
    ~initialize_ocaml_toolchain ~overwrite ?(backend_framework = None)
    ?(api_features = None) () =
  {
    name;
    directory;
    node_package_manager = Nodejs.Process.npm_config_user_agent;
    syntax_preference;
    project_type;
    backend_framework;
    api_features;
    bundler;
    is_react_app;
    has_tests;
    initialize_git;
    initialize_npm;
    initialize_ocaml_toolchain;
    overwrite;
  }
;;

let set_overwrite overwrite config = { config with overwrite = Some overwrite }
let is_fullstack config = config.project_type = `Fullstack
let is_frontend_only config = config.project_type = `Frontend

let to_string config =
  let backend_info =
    match config.project_type with
    | `Frontend -> ""
    | `Fullstack ->
        Printf.sprintf "Backend framework: %s\nAPI features: %s\n"
          (config.backend_framework
          |> Option.map backend_framework_to_string
          |> Option.value ~default:"None")
          (config.api_features
          |> Option.map api_features_to_string
          |> Option.value ~default:"None")
  in
  Printf.sprintf
    "Name: %s\n\
     Directory: %s\n\
     Project type: %s\n\
     %sSyntax preference: %s\n\
     Bundler: %s\n\
     is_react_app: %b\n\
     Initialize git: %b\n\
     Initialize npm: %b\n\
     Initialize OCaml toolchain: %b\n"
    config.name config.directory
    (project_type_to_string config.project_type)
    backend_info
    (syntax_preference_to_string config.syntax_preference)
    (Bundler.to_string config.bundler)
    config.is_react_app config.initialize_git config.initialize_npm
    config.initialize_ocaml_toolchain
;;

let to_json (configuration : t) =
  let dict = Js.Dict.empty () in
  Js.Dict.set dict "name" (Js.Json.string configuration.name);
  Js.Dict.set dict "directory" (Js.Json.string configuration.directory);
  Js.Dict.set dict "node_package_manager"
    (Js.Json.string
       (configuration.node_package_manager
      |> Nodejs.Process.npm_user_agent_to_string |> String.capitalize_ascii));
  Js.Dict.set dict "syntax_preference"
    (Js.Json.string
       (syntax_preference_to_string configuration.syntax_preference));
  Js.Dict.set dict "project_type"
    (Js.Json.string (project_type_to_string configuration.project_type));
  (match configuration.backend_framework with
  | Some framework ->
      Js.Dict.set dict "backend_framework"
        (Js.Json.string (backend_framework_to_string framework))
  | None -> ());
  (match configuration.api_features with
  | Some features ->
      Js.Dict.set dict "api_features"
        (Js.Json.string (api_features_to_string features))
  | None -> ());
  Js.Dict.set dict "bundler"
    (Js.Json.string
       (Bundler.to_string configuration.bundler |> String.capitalize_ascii));
  Js.Dict.set dict "is_react_app" (Js.Json.boolean configuration.is_react_app);
  Js.Dict.set dict "initialize_git"
    (Js.Json.boolean configuration.initialize_git);
  Js.Dict.set dict "initialize_npm"
    (Js.Json.boolean configuration.initialize_npm);
  Js.Dict.set dict "initialize_ocaml_toolchain"
    (Js.Json.boolean configuration.initialize_ocaml_toolchain);
  let overwrite_str =
    configuration.overwrite
    |> Option.map overwrite_preference_to_string
    |> Option.value ~default:"None"
  in
  Js.Dict.set dict "overwrite" (Js.Json.string overwrite_str);
  Js.Json.object_ dict
;;

type partial = {
  name : string option;
  directory : string option;
  syntax_preference : syntax_preference option;
  project_type : project_type option;
  backend_framework : backend_framework option;
  api_features : api_features option;
  bundler : Bundler.t option;
  is_react_app : bool option;
  has_tests : bool option;
  initialize_git : bool option;
  initialize_npm : bool option;
  initialize_ocaml_toolchain : bool option;
}

let make_partial ?name ?directory ?syntax_preference ?project_type
    ?backend_framework ?api_features ?bundler ?is_react_app ?has_tests
    ?initialize_git ?initialize_npm ?initialize_ocaml_toolchain () =
  {
    name;
    directory;
    syntax_preference;
    project_type;
    backend_framework;
    api_features;
    bundler;
    is_react_app;
    has_tests;
    initialize_git;
    initialize_npm;
    initialize_ocaml_toolchain;
  }
;;

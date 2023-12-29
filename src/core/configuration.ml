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
  str |> String.lowercase_ascii |> function
  | "ocaml" -> `OCaml
  | "reasonml" -> `ReasonML
  | _ -> failwith "Invalid syntax preference"
;;

type t = {
  name : string;
  directory : string;
  syntax_preference : syntax_preference;
  bundler : Bundler.t;
  is_react_app : bool;
  initialize_git : bool;
  initialize_npm : bool;
  initialize_ocaml_toolchain : bool;
  overwrite : overwrite_preference option;
}

let make ~name ~directory ~syntax_preference ~bundler ~is_react_app
    ~initialize_git ~initialize_npm ~initialize_ocaml_toolchain ~overwrite =
  {
    name;
    directory;
    syntax_preference;
    bundler;
    is_react_app;
    initialize_git;
    initialize_npm;
    initialize_ocaml_toolchain;
    overwrite;
  }
;;

let set_overwrite overwrite config = { config with overwrite = Some overwrite }

let to_string config =
  Printf.sprintf
    "Name: %s\n\
     Directory: %s\n\
     Syntax preference: %s\n\
     Bunder: %s\n\
     is_react_app: %b\n\
     Initialize git: %b\n\
     Initialize npm: %b\n\
     Initialize OCaml toolchain: %b\n"
    config.name config.directory
    (syntax_preference_to_string config.syntax_preference)
    (Bundler.to_string config.bundler)
    config.is_react_app config.initialize_git config.initialize_npm
    config.initialize_ocaml_toolchain
;;

let to_json (configuration : t) =
  let dict = Js.Dict.empty () in
  Js.Dict.set dict "name" (Js.Json.string configuration.name);
  Js.Dict.set dict "directory" (Js.Json.string configuration.directory);
  Js.Dict.set dict "syntax_preference"
    (Js.Json.string
       (syntax_preference_to_string configuration.syntax_preference));
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
  bundler : Bundler.t option;
  is_react_app : bool option;
  initialize_git : bool option;
  initialize_npm : bool option;
  initialize_ocaml_toolchain : bool option;
}

let make_partial ?name ?directory ?syntax_preference ?bundler ?is_react_app
    ?initialize_git ?initialize_npm ?initialize_ocaml_toolchain () =
  {
    name;
    directory;
    syntax_preference;
    bundler;
    is_react_app;
    initialize_git;
    initialize_npm;
    initialize_ocaml_toolchain;
  }
;;

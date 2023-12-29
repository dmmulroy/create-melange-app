type overwrite_preference = [ `Clear | `Overwrite ]

let overwrite_preference_to_string = function
  | `Clear -> "clear"
  | `Overwrite -> "overwrite"
;;

type t = {
  name : string;
  directory : string;
  bundler : Bundler.t;
  initialize_git : bool;
  initialize_npm : bool;
  initialize_ocaml_toolchain : bool;
  overwrite : overwrite_preference option;
}

let make ~name ~directory ~bundler ~initialize_git ~initialize_npm
    ~initialize_ocaml_toolchain ~overwrite =
  {
    name;
    directory;
    bundler;
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
     Bunder: %s\n\
     Initialize git: %b\n\
     Initialize npm: %b\n\
     Initialize OCaml toolchain: %b\n"
    config.name config.directory
    (Bundler.to_string config.bundler)
    config.initialize_git config.initialize_npm
    config.initialize_ocaml_toolchain
;;

type partial = {
  name : string option;
  directory : string option;
  bundler : Bundler.t option;
  initialize_git : bool option;
  initialize_npm : bool option;
  initialize_ocaml_toolchain : bool option;
}

let make_partial ?name ?directory ?bundler ?initialize_git ?initialize_npm
    ?initialize_ocaml_toolchain () =
  {
    name;
    directory;
    bundler;
    initialize_git;
    initialize_npm;
    initialize_ocaml_toolchain;
  }
;;

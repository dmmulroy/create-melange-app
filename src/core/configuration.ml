type t = {
  name : string;
  directory : string;
  bundler : Bundler.t;
  initialize_git : bool;
  initialize_npm : bool;
  overwrite : [ `Clear | `Overwrite ] option;
}

let make ~name ~directory ~bundler ~initialize_git ~initialize_npm ~overwrite =
  { name; directory; bundler; initialize_git; initialize_npm; overwrite }
;;

let set_overwrite overwrite config = { config with overwrite = Some overwrite }

let to_string config =
  Printf.sprintf
    "Name: %s\nBunder: %s\nInitialize git: %b\nInitialize npm: %b\n" config.name
    (Bundler.to_string config.bundler)
    config.initialize_git config.initialize_npm
;;

type partial = {
  name : string option;
  directory : string option;
  bundler : Bundler.t option;
  initialize_git : bool option;
  initialize_npm : bool option;
}

let make_partial ?name ?directory ?bundler ?initialize_git ?initialize_npm () =
  { name; directory; bundler; initialize_git; initialize_npm }
;;

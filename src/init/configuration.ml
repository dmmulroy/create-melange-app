type t = {
  name : string;
  bundler : Bundler.t;
  initialize_git : bool;
  initialize_npm : bool;
}

let make ~name ~bundler ~initialize_git ~initialize_npm =
  { name; bundler; initialize_git; initialize_npm }
;;

let to_string config =
  Printf.sprintf
    "Name: %s\nBunder: %s\bInitialize git: %b\nInitialize npm: %b\n" config.name
    (Bundler.to_string config.bundler)
    config.initialize_git config.initialize_npm
;;

type partial = {
  name : string option;
  bundler : Bundler.t option;
  initialize_git : bool option;
  initialize_npm : bool option;
}

module Bundler = struct
  type t = Vite | Webpack | None

  let to_string = function
    | Vite -> "vite"
    | Webpack -> "webpack"
    | None -> "none"
  ;;

  let of_string = function "vite" -> Vite | "webpack" -> Webpack | _ -> None
end

type t = {
  name : string;
  bundler : Bundler.t;
  initialize_git : bool;
  initialize_npm : bool;
  overwrite : [ `Clear | `Overwrite ] option;
}

let make ~name ~bundler ~initialize_git ~initialize_npm ~overwrite =
  { name; bundler; initialize_git; initialize_npm; overwrite }
;;

let to_string config =
  Printf.sprintf
    "Name: %s\nBunder: %s\nInitialize git: %b\nInitialize npm: %b\n" config.name
    (Bundler.to_string config.bundler)
    config.initialize_git config.initialize_npm
;;

type partial = {
  name : string option;
  bundler : Bundler.t option;
  initialize_git : bool option;
  initialize_npm : bool option;
}

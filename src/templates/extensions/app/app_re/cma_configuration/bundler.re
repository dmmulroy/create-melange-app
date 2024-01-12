type t =
  | Vite
  | Webpack
  | None;

let to_string =
  fun
  | Vite => "vite"
  | Webpack => "webpack"
  | None => "none";

let of_string =
  fun
  | "vite" => Ok(Vite)
  | "webpack" => Ok(Webpack)
  | "none" => Ok(None)
  | _ => Error("Invalid bundler");

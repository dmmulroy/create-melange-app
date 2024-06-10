type t =
  | Vite
  | Webpack
  | Esbuild
  | None;

let to_string =
  fun
  | Vite => "vite"
  | Webpack => "webpack"
  | Esbuild => "esbuild"
  | None => "none";

let of_string =
  fun
  | "vite" => Ok(Vite)
  | "webpack" => Ok(Webpack)
  | "esbuild" => Ok(Esbuild)
  | "none" => Ok(None)
  | _ => Error("Invalid bundler");

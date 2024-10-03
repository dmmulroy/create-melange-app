type t = Vite | Webpack | Esbuild | None

let to_string = function
  | Vite -> "vite"
  | Webpack -> "webpack"
  | Esbuild -> "esbuild"
  | None -> "none"
;;

let of_string = function
  | "vite" -> Ok Vite
  | "webpack" -> Ok Webpack
  | "esbuild" -> Ok Esbuild
  | "none" -> Ok None
  | _ -> Error "Invalid bundler"
;;

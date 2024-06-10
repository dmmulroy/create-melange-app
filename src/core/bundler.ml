type t = Vite | Webpack | Esbuild

let to_string = function
  | Vite -> "vite"
  | Webpack -> "webpack"
  | Esbuild -> "esbuild"
;;

let of_string = function
  | "vite" -> Vite
  | "webpack" -> Webpack
  | "esbuild" -> Esbuild
  | _ -> failwith "invalid bundler"
;;

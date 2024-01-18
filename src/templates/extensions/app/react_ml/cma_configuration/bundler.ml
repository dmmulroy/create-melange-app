type t = Vite | Webpack | None

let to_string = function
  | Vite -> "vite"
  | Webpack -> "webpack"
  | None -> "none"
;;

let of_string = function
  | "vite" -> Ok Vite
  | "webpack" -> Ok Webpack
  | "none" -> Ok None
  | _ -> Error "Invalid bundler"
;;

type t = Vite | Webpack | None

let to_string = function
  | Vite -> "vite"
  | Webpack -> "webpack"
  | None -> "none"
;;

let of_string = function "vite" -> Vite | "webpack" -> Webpack | _ -> None

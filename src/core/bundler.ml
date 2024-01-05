type t = Vite | Webpack

let to_string = function Vite -> "vite" | Webpack -> "webpack"

let of_string = function
  | "vite" -> Vite
  | "webpack" -> Webpack
  | _ -> failwith "invalid bundler"
;;

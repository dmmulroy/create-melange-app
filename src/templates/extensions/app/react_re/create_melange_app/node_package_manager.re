type t =
  | Npm
  | Yarn
  | Pnpm
  | Bun;

let of_string =
  fun
  | "npm" => Ok(Npm)
  | "yarn" => Ok(Yarn)
  | "pnpm" => Ok(Pnpm)
  | "bun" => Ok(Bun)
  | _ => Error("Invalid npm user agent");

let to_string =
  fun
  | Npm => "npm"
  | Yarn => "yarn"
  | Pnpm => "pnpm"
  | Bun => "bun";

include Node.Process

external npm_config_user_agent : string option = "npm_config_user_agent"
[@@mel.scope "env"] [@@mel.module "process"] [@@mel.return undefined_to_opt]

type npm_user_agent = [ `Npm | `Yarn | `Pnpm | `Bun ]

let npm_user_agent_to_string = function
  | `Npm -> "npm"
  | `Yarn -> "yarn"
  | `Pnpm -> "pnpm"
  | `Bun -> "bun"
;;

let npm_user_agent_of_string = function
  | "bun" -> Ok `Bun
  | "npm" -> Ok `Npm
  | "pnpm" -> Ok `Pnpm
  | "yarn" -> Ok `Yarn
  | _ -> Error "Unknown npm user agent"
;;

let npm_config_user_agent : npm_user_agent =
  let ua = Option.value ~default:"npm" npm_config_user_agent in
  if String.starts_with ua ~prefix:"yarn" then `Yarn
  else if String.starts_with ua ~prefix:"pnpm" then `Pnpm
  else if String.starts_with ua ~prefix:"bun" then `Bun
  else `Npm
;;

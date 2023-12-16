open Context_plugin

module Install : Process.S with type input = string and type output = string =
struct
  type input = string
  type output = string

  open Nodejs.Process

  let name = "npm install"

  let npm_user_agent_to_install_cmd = function
    | Bun -> "bun install"
    | Npm -> "npm install"
    | Pnpm -> "pnpm install"
    | Yarn -> "yarn"
  ;;

  let exec (project_dir_name : input) =
    let options =
      Node.Child_process.option ~cwd:project_dir_name ~encoding:"utf8" ()
    in
    let ua_install_cmd =
      npm_config_user_agent |> npm_user_agent_to_install_cmd
    in
    Nodejs.Child_process.async_exec ua_install_cmd options
    |> Js.Promise.then_ (fun value -> Js.Promise.resolve @@ Ok value)
    |> Js.Promise.catch (fun _err ->
           Js.Promise.resolve
           @@ Error
                ("Failed to initialize "
                ^ (npm_config_user_agent |> npm_user_agent_to_string)))
  ;;
end

module Plugin = struct
  module Install = struct
    include Plugin.Make_process (struct
      include Install

      let stage = `Post_compile
      let input_of_context (ctx : Context.t) = Ok ctx.configuration.name
    end)
  end
end

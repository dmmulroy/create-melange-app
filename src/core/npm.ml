open Bindings

module Install : Process.S with type input = string and type output = string =
struct
  type input = string
  type output = string

  open Nodejs.Process

  let name = "npm install"

  let npm_user_agent_to_install_cmd = function
    | `Bun -> "bun install"
    | `Npm -> "npm install"
    | `Pnpm -> "pnpm install"
    | `Yarn -> "yarn"
  ;;

  let error_message =
    {|
    Failed to install npm dependencies

    The scaffolding process failed while attempting to install npm dependencies 

    Please try `cd`ing into the project directory created by 
    `create-melange-app` and running the following commands:
 
    npm install

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.

    If you open an issue, please `cd` into the directory created by 
    `create-melange-app` and include the output from the following commands: 

    `npm install`
  |}
  ;;

  let exec (project_dir_name : input) =
    let options =
      Node.Child_process.option ~cwd:project_dir_name ~encoding:"utf8" ()
    in
    let ua_install_cmd =
      npm_config_user_agent |> npm_user_agent_to_install_cmd
    in
    Nodejs.Child_process.async_exec ua_install_cmd options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end

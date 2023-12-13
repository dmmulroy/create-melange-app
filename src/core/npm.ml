open Context_plugin

module Install : Process.S with type input = string and type output = string =
struct
  type input = string
  type output = string

  let name = "npm install"

  let exec (project_dir_name : input) =
    let options =
      Node.Child_process.option ~cwd:project_dir_name ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec "npm i" options
    |> Js.Promise.then_ (fun value -> Js.Promise.resolve @@ Ok value)
    |> Js.Promise.catch (fun _err ->
           Js.Promise.resolve @@ Error "Failed to initialize npm")
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

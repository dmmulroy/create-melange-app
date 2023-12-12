open Context_plugin

let run (ctx : Context.t) =
  let dir = ctx.configuration.name in
  let options = Node.Child_process.option ~cwd:dir ~encoding:"utf8" () in
  Nodejs.Child_process.async_exec "npm i" options
  |> Js.Promise.then_ (fun _value -> Js.Promise.resolve @@ Ok ctx)
  |> Js.Promise.catch (fun _err ->
         Js.Promise.resolve @@ Error "Failed to initialize npm")
;;

module Plugin = struct
  module Command = struct
    include Plugin.Make_command (struct
      let name = "npm"
      let stage = `Post_compile
      let exec = run
    end)
  end
end

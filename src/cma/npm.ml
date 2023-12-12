let run (ctx : Scaffold_v2.Context.t) =
  let dir = ctx.configuration.name in
  let options = Node.Child_process.option ~cwd:dir ~encoding:"utf8" () in
  Nodejs.Child_process.async_exec "npm i" options
  |> Js.Promise.then_ (fun _value -> Js.Promise.resolve @@ Ok ctx)
  |> Js.Promise.catch (fun _err ->
         Js.Promise.resolve @@ Error "Failed to initialize npm")
;;

(* try
     let _ = Node.Child_process.execSync "npm i" options in
     Js.Promise.resolve @@ Ok ctx
   with exn ->
     Js.Promise.resolve
     @@ Error
          (Printf.sprintf "Failed to initialize npm: %s" (Printexc.to_string exn)) *)

(* TODO: Start here on Tuesday morning - npm is failing because it's running
   before the template is compiled.
*)

(* Nodejs.Child_process.async_exec "npm i" options
   |> Js.Promise.then_ (fun _value -> Js.Promise.resolve @@ Ok ctx)
   |> Js.Promise.catch (fun _err ->
          let _ = failwith "Failed to initialize npm" in
          Js.Promise.resolve @@ Error "Failed to initialize npm") *)

module Plugin = struct
  module Command = struct
    include Scaffold_v2.Plugin.Make_command (struct
      let name = "npm"
      let stage = `Post_compile
      let exec = run
    end)
  end
end

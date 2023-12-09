let run (ctx : Context.t) =
  (* TODO: Handle if name is "." *)
  let dir = ctx.configuration.name in
  let options = Node.Child_process.option ~cwd:dir ~encoding:"utf8" () in
  Node.Child_process.execSync "npm i" options |> ignore
;;

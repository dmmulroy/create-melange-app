let run (ctx : Scaffold_v2.Context.t) =
  (* TODO: Handle if name is "." *)
  let dir = ctx.configuration.name in
  let options = Node.Child_process.option ~cwd:dir ~encoding:"utf8" () in
  Node.Child_process.execSync "git init && git add -A" options |> ignore
;;

let files =
  [
    Node.Path.join
      [|
        [%mel.raw "__dirname"];
        "..";
        "templates";
        "extensions";
        "git";
        ".gitignore";
      |];
  ]
;;

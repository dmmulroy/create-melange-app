let run (ctx : Scaffold_v2.Context.t) =
  (* TODO: Handle if name is "." *)
  let dir = ctx.configuration.name in
  let options = Node.Child_process.option ~cwd:dir ~encoding:"utf8" () in
  Nodejs.Child_process.async_exec "git init && git add -A" options
  |> Js.Promise.then_ (fun _value -> Js.Promise.resolve @@ Ok ctx)
  |> Js.Promise.catch (fun _err ->
         Js.Promise.resolve @@ Error "Failed to initialize git")
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

module Plugin = struct
  module Command = struct
    include Scaffold_v2.Plugin.Make_command (struct
      let name = "git"

      let exec (ctx : Scaffold_v2.Context.t) =
        List.fold_left
          (fun promise file_path ->
            Js.Promise.then_
              (fun result ->
                if Result.is_error result then Js.Promise.resolve result
                else
                  let file_name = Node.Path.basename file_path in
                  let dest =
                    Node.Path.join [| ctx.configuration.name; "/"; file_name |]
                  in
                  Fs.copy_file ~dest file_path)
              promise)
          (Js.Promise.resolve @@ Ok ())
          files
        |> Js.Promise.then_ (fun result ->
               match result with
               | Ok _ -> Js.Promise.resolve @@ Ok ctx
               | Error err -> Js.Promise.resolve @@ Error err)
      ;;
    end)
  end
end

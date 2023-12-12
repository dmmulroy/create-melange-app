let run (ctx : Scaffold_v2.Context.t) =
  let dir = ctx.configuration.name in
  let options = Node.Child_process.option ~cwd:dir ~encoding:"utf8" () in
  Nodejs.Child_process.async_exec "git init && git add -A" options
  |> Js.Promise.then_ (fun _value -> Js.Promise.resolve @@ Ok ctx)
  |> Js.Promise.catch (fun _err ->
         Js.Promise.resolve @@ Error "Failed to initialize git")
;;

(* try
     let _ = Node.Child_process.execSync "git init && git add -A" options in
     Js.Promise.resolve @@ Ok ctx
   with exn ->
     Js.Promise.resolve
     @@ Error
          (Printf.sprintf "Failed to initialize git: %s" (Printexc.to_string exn)) *)

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
      let stage = `Post_compile

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
        |> Js.Promise.then_ (fun result ->
               match result with
               | Ok _ -> run ctx
               | Error err -> Js.Promise.resolve @@ Error err)
      ;;
    end)
  end
end

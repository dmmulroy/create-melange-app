open Package_json
module String_map = Map.Make (String)

let dev_dependencies =
  [
    Dependency.make ~kind:`Development ~name:"webpack" ~version:"^5.89.0";
    Dependency.make ~kind:`Development ~name:"webpack-cli" ~version:"^5.1.4";
    Dependency.make ~kind:`Development ~name:"webpack-dev-server"
      ~version:"^4.15.1";
  ]
;;

let scripts =
  [
    Script.make ~name:"bundle"
      ~script:
        "webpack --mode production --entry \
         ./_build/default/src/output/src/app.js";
    Script.make ~name:"server"
      ~script:
        "webpack serve --open --mode development --entry \
         ./_build/default/src/output/src/app.js";
  ]
;;

let files =
  [
    Node.Path.join
      [|
        [%mel.raw "__dirname"];
        "..";
        "templates";
        "extensions";
        "webpack";
        "webpack.config.js";
      |];
  ]
;;

module Plugin = struct
  module Extension = struct
    include Scaffold_v2.Plugin.Make_extension (struct
      include Package_json.Template

      let stage = `Pre_compile

      let extend_template pkg =
        (* Add dependencies to package.json *)
        let pkg =
          dev_dependencies
          |> List.fold_left (Fun.flip Package_json.add_dependency) pkg
        in
        (* Add scripts to package.json *)
        scripts
        |> List.fold_left (Fun.flip Package_json.add_script) pkg
        |> Result.ok |> Js.Promise.resolve
      ;;
    end)
  end

  module Command = struct
    include Scaffold_v2.Plugin.Make_command (struct
      let name = "webpack"
      let stage = `Pre_compile

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

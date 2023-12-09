open Package_json
module String_map = Map.Make (String)

let dev_dependencies =
  [
    Dependency.make ~kind:`Development ~name:"vite" ~version:"^4.5.0";
    Dependency.make ~kind:`Development ~name:"vite-plugin-melange"
      ~version:"^2.2.0";
  ]
;;

let scripts =
  [
    Script.make ~name:"dev" ~script:"vite";
    Script.make ~name:"serve" ~script:"vite preview";
    Script.make ~name:"bundle" ~script:"vite build";
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
        "vite";
        "vite.config.js";
      |];
  ]
;;

module Plugin = struct
  module Extension = struct
    include Scaffold_v2.Plugin.Make_extension (struct
      include Package_json.Template

      let extend_template pkg =
        (* Add dependencies to package.json *)
        let pkg =
          dev_dependencies
          |> List.fold_left (Fun.flip Package_json.add_dependency) pkg
        in
        (* Add scripts to package.json *)
        scripts
        |> List.fold_left (Fun.flip Package_json.add_script) pkg
        |> Result.ok
      ;;
    end)
  end

  module Command = struct
    include Scaffold_v2.Plugin.Make_command (struct
      let name = "webpack"

      let exec (ctx : Scaffold_v2.Context.t) =
        let () =
          List.iter
            (fun file_path ->
              let file_name = Node.Path.basename file_path in
              let dest =
                Node.Path.join [| ctx.configuration.name; "/"; file_name |]
              in
              Fs.copy_file ~dest file_path)
            files
        in
        Ok ctx
      ;;
    end)
  end
end

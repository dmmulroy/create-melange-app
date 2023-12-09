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

module Extension = struct
  include Plugin.Make_extension (struct
    include Package_json.Template

    let extend_template pkg_json =
      (* Add dependencies to package.json *)
      let pkg_json =
        dev_dependencies
        |> List.fold_left (Fun.flip Package_json.add_dependency) pkg_json
      in
      (* Add scripts to package.json *)
      let pkg_json =
        scripts |> List.fold_left (Fun.flip Package_json.add_script) pkg_json
      in
      Ok pkg_json
    ;;
  end)
end

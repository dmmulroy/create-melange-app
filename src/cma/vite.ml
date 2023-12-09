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

let _ = Node.Path.basename

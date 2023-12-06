[@@@ocaml.warning "-21-26-27-32"]

open Common
open Syntax
open Let
module String_map = Map.Make (String)

module Package_json = struct
  type t = {
    name : string;
    scripts : string String_map.t;
    dependencies : string String_map.t;
    dev_dependencies : string String_map.t;
  }

  let name = "package.json.tmpl"

  let empty =
    {
      name = "";
      scripts = String_map.empty;
      dependencies = String_map.empty;
      dev_dependencies = String_map.empty;
    }
  ;;

  let make ~name ~scripts ~dependencies ~dev_dependencies =
    { name; scripts; dependencies; dev_dependencies }
  ;;

  let set_name name pkg = { pkg with name }

  let add_script ~name ~script pkg =
    { pkg with scripts = String_map.add name script pkg.scripts }
  ;;

  let add_dependency ~name ~version pkg =
    { pkg with dependencies = String_map.add name version pkg.dependencies }
  ;;

  let add_dev_dependency ~name ~version pkg =
    {
      pkg with
      dev_dependencies = String_map.add name version pkg.dev_dependencies;
    }
  ;;

  let to_json pkg =
    let obj = Js.Dict.empty () in
    Js.Dict.set obj "name" (Js.Json.string pkg.name);
    let scripts =
      String_map.to_list pkg.scripts
      |> List.map (fun (key, value) -> (key, Js.Json.string value))
      |> Js.Dict.fromList |> Js.Json.object_
    in
    Js.Dict.set obj "scripts" scripts;
    let dependencies =
      String_map.to_list pkg.dependencies
      |> List.map (fun (key, value) -> (key, Js.Json.string value))
      |> Js.Dict.fromList |> Js.Json.object_
    in
    Js.Dict.set obj "dependencies" dependencies;
    let dev_dependencies =
      String_map.to_list pkg.dev_dependencies
      |> List.map (fun (key, value) -> (key, Js.Json.string value))
      |> Js.Dict.fromList |> Js.Json.object_
    in
    Js.Dict.set obj "devDependencies" dev_dependencies;
    Js.Json.object_ obj
  ;;

  let merge_enrichment enrichment pkg =
    {
      pkg with
      scripts =
        String_map.union
          (fun _key enrichment_value _pkg_value -> Some enrichment_value)
          enrichment.scripts pkg.scripts;
      dependencies =
        String_map.union
          (fun _key enrichment_value _pkg_value -> Some enrichment_value)
          enrichment.dependencies pkg.dependencies;
      dev_dependencies =
        String_map.union
          (fun _key enrichment_value _pkg_value -> Some enrichment_value)
          enrichment.dev_dependencies pkg.dev_dependencies;
    }
  ;;

  let compile pkg =
    let json = to_json pkg in
    let@ contents = Fs.read_template ~dir:pkg.name name in
    let template = Handlebars.compile contents () in
    let compiled_contents = template json () in
    Fs.write_template ~dir:pkg.name name compiled_contents
  ;;

  module Enrichment = struct
    module type S = sig
      val enrich : unit -> t
    end

    module Vite = struct
      let scripts =
        String_map.empty
        |> String_map.add "bundle" "vite build"
        |> String_map.add "serve" "vite"
        |> String_map.add "dev" "vite"
      ;;

      let dependencies = String_map.empty

      let dev_dependencies =
        String_map.empty
        |> String_map.add "vite-plugin-melange" "^2.2.0"
        |> String_map.add "vite" "^5.0.5"
      ;;

      let enrich () = make ~name:"" ~scripts ~dependencies ~dev_dependencies
    end

    module Webpack : S = struct
      let scripts =
        String_map.empty
        |> String_map.add "bundle"
             "webpack --mode production --entry \
              ./_build/default/src/output/src/ReactApp.js"
        |> String_map.add "server"
             "webpack serve --open --mode development --entry \
              ./_build/default/src/output/src/ReactApp.js"
      ;;

      let dependencies =
        String_map.empty
        |> String_map.add "react" "^18.0.0"
        |> String_map.add "react-dom" "^18.0.0"
      ;;

      let dev_dependencies =
        String_map.empty
        |> String_map.add "webpack" "^5.73.0"
        |> String_map.add "webpack-cli" "^18.0.0"
        |> String_map.add "webpack-dev-server" "^4.9.1"
      ;;

      let enrich () = make ~name:"" ~scripts ~dependencies ~dev_dependencies
    end
  end
end

module Dune_project = struct
  type t = { name : string; depends : string option String_map.t }

  let name = "dune-project.tmpl"
  let empty = { name = ""; depends = String_map.empty }
  let make ~name ~depends = { name; depends }
  let set_name name dune_project = { dune_project with name }

  let add_depends ~name ?version_constraint dune_project =
    {
      dune_project with
      depends = String_map.add name version_constraint dune_project.depends;
    }
  ;;

  let to_json dune_project =
    let obj = Js.Dict.empty () in
    Js.Dict.set obj "name" (Js.Json.string dune_project.name);
    let depends =
      String_map.to_list dune_project.depends
      |> List.map (fun (key, (value : string option)) ->
             ( key,
               if Option.is_some value then Js.Json.string (Option.get value)
               else Js.Json.null ))
      |> Js.Dict.fromList |> Js.Json.object_
    in
    Js.Dict.set obj "depends" depends;
    Js.Json.object_ obj
  ;;

  let compile dune_project =
    let json = to_json dune_project in
    let@ contents =
      Fs.read_template ~dir:dune_project.name "dune-project.tmpl"
    in

    let template = Handlebars.compile contents () in
    let compiled_contents = template json () in
    Fs.write_template ~dir:dune_project.name "dune-project.tmpl"
      compiled_contents
  ;;
end

let compile_pkg_json (configuration : Configuration.t) =
  let pkg_json = Package_json.(empty |> set_name configuration.name) in
  let pkg_json =
    match configuration.bundler with
    | Webpack ->
        Package_json.(merge_enrichment (Enrichment.Webpack.enrich ()) pkg_json)
    | _ -> pkg_json
  in
  Package_json.compile pkg_json
;;

let compile_dune_project (configuration : Configuration.t) =
  let dune_project = Dune_project.(empty |> set_name configuration.name) in
  Dune_project.compile dune_project
;;

let compile_all (configuration : Configuration.t) =
  let@ _ = compile_pkg_json configuration in
  let@ _ = compile_dune_project configuration in
  Ok ()
;;

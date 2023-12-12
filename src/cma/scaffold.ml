open Common
open Syntax
open! Let
open Scaffold_v2
module String_map = Map.Make (String)

let copy_base_dir (ctx : Context.t) =
  let| _ =
    Fs.copy_base_dir ?overwrite:ctx.configuration.overwrite
      ctx.configuration.name
  in
  Js.Promise.resolve @@ Ok ctx
;;

(* TODO: Think about a potential helper for mapping template values in the context *)

let fold_compilation_results (ctx : Context.t) (acc : (unit, string) result)
    (_, (module Template : Template.S)) =
  if Result.is_error acc then acc
  else
    let template_value = Hmap.find Template.key ctx.template_values in
    let dir = Node.Path.join [| "./"; ctx.configuration.name |] in
    match template_value with
    | None ->
        Error
          (Printf.sprintf "A value for Template %s was not found" Template.name)
    | Some value -> Template.compile ~dir value
;;

let run_pre_compile_plugins (ctx : Context.t) =
  List.fold_left
    (fun promise (module Plugin : Plugin.S) ->
      Js.Promise.then_
        (fun acc ->
          if Result.is_error acc || Plugin.stage = `Post_compile then
            Js.Promise.resolve acc
          else Plugin.run ctx)
        promise)
    (Js.Promise.resolve @@ Ok ctx)
    ctx.plugins
;;

let run_post_compile_plugins (ctx : Context.t) =
  List.fold_left
    (fun promise (module Plugin : Plugin.S) ->
      Js.Promise.then_
        (fun acc ->
          match acc with
          | Error _ -> Js.Promise.resolve acc
          | Ok _ when Plugin.stage = `Pre_compile -> Js.Promise.resolve acc
          | Ok ctx' -> Plugin.run ctx')
        promise)
    (Js.Promise.resolve @@ Ok ctx)
    ctx.plugins
;;

let compile_template (ctx : Context.t) =
  let open Infix.Result in
  String_map.to_list ctx.templates
  |> List.fold_left (fold_compilation_results ctx) (Ok ())
  >|= (fun _ -> ctx)
  |> Js.Promise.resolve
;;

let make_context (configuration : Configuration.t) =
  let templates =
    String_map.empty
    |> String_map.add Package_json.Template.name
         (module Package_json.Template : Template.S)
    |> String_map.add Dune_project.Template.name
         (module Dune_project.Template : Template.S)
  in
  let template_values =
    Hmap.empty
    |> Hmap.add Package_json.Template.key
         (Package_json.empty |> Package_json.set_name configuration.name)
    |> Hmap.add Dune_project.Template.key
         (Dune_project.empty |> Dune_project.set_name configuration.name)
  in
  let plugins : (module Plugin.S) list =
    match configuration.bundler with
    | Webpack ->
        [ (module Webpack.Plugin.Command); (module Webpack.Plugin.Extension) ]
    | Vite -> [ (module Vite.Plugin.Command); (module Vite.Plugin.Extension) ]
    | None -> []
  in
  let plugins =
    if configuration.initialize_git then
      (module Git.Plugin.Command : Plugin.S) :: plugins
    else plugins
  in
  let plugins =
    if configuration.initialize_npm then
      (module Npm.Plugin.Command : Plugin.S) :: plugins
    else plugins
  in
  Context.{ configuration; templates; template_values; plugins }
;;

let run (config : Configuration.t) =
  make_context config |> copy_base_dir
  |> Js.Promise.then_ (fun ctx_result ->
         match ctx_result with
         | Error err -> Js.Promise.resolve @@ Error err
         | Ok ctx -> run_pre_compile_plugins ctx)
  |> Js.Promise.then_ (fun ctx_result ->
         match ctx_result with
         | Error _ -> Js.Promise.resolve @@ Error "pre compile failed"
         | Ok ctx -> compile_template ctx)
  |> Js.Promise.then_ (fun ctx_result ->
         match ctx_result with
         | Error err -> Js.Promise.resolve @@ Error err
         | Ok ctx -> run_post_compile_plugins ctx)
  |> Js.Promise.catch (fun err ->
         Js.log "Error: ";
         Js.log err;
         Js.Promise.resolve @@ Error "In Catch :(")
;;

(* |> Js.Promise.then_ (fun ctx_result ->
       match ctx_result with
       | Error err -> Js.Promise.resolve @@ Error err
       | Ok _ -> Js.Promise.resolve @@ Ok ()) *)

open Bindings
module String_map = Map.Make (String)

(*
let fold_compilation_results (ctx : Context.t)
    (acc : (unit, string) Promise_result.t) (_, (module Template : Template.S))
    =
  let open Promise.Syntax.Let in
  let* is_error = Promise_result.is_error acc in
  if is_error then acc
  else
    let template_value = Hmap.find Template.key ctx.template_values in
    match template_value with
    | None ->
        Promise_result.resolve_error
          (Printf.sprintf "A value for Template %s was not found" Template.name)
    | Some value -> Template.compile ~dir:ctx.configuration.directory value
;; *)

(* let compile_template (ctx : Context.t) =
     String_map.to_list ctx.templates
     |> List.fold_left
          (fold_compilation_results ctx)
          (Promise_result.resolve_ok ())
     |> Promise_result.map (fun _ -> ctx)
   ;; *)

(* let make_context (configuration : Configuration.t) =
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
           [
             (module Webpack.Plugin.Copy_webpack_config_js);
             (module Webpack.Plugin.Extend_package_json);
           ]
       | Vite ->
           [
             (module Vite.Plugin.Copy_vite_config_js);
             (module Vite.Plugin.Extend_package_json);
           ]
       | None -> []
     in
     (* let plugins = (module Opam.Plugin.Create_switch : Plugin.S) :: plugins in *)
     let plugins =
       if configuration.initialize_git then
         [
           (module Git_scm.Plugin.Copy_gitignore : Plugin.S);
           (module Git_scm.Plugin.Init_and_stage : Plugin.S);
         ]
         @ plugins
       else plugins
     in
     let plugins =
       if configuration.initialize_npm then
         (module Npm.Plugin.Install : Plugin.S) :: plugins
       else plugins
     in
     Context.{ configuration; templates; template_values; plugins }
   ;; *)

(* let run (config : Configuration.t) =
     make_context config |> copy_base_dir
     |> Js.Promise.then_ (fun ctx_result ->
            match ctx_result with
            | Error err -> Js.Promise.resolve @@ Error err
            | Ok ctx -> run_pre_compile_plugins ctx)
     |> Js.Promise.catch (fun _ ->
            Js.Promise.resolve @@ Error "pre compile failed")
     |> Js.Promise.then_ (fun ctx_result ->
            match ctx_result with
            | Error _ -> Js.Promise.resolve @@ Error "pre compile failed"
            | Ok ctx -> (
                try compile_template ctx
                with exn ->
                  Js.Promise.resolve
                  @@ Error
                       (Format.sprintf "compile failed dawg: %s"
                          (Printexc.to_string exn))))
     |> Js.Promise.catch (fun _ ->
            Js.Promise.resolve @@ Error "template compilation failed")
     |> Js.Promise.then_ (fun ctx_result ->
            match ctx_result with
            | Error err -> Js.Promise.resolve @@ Error err
            | Ok ctx -> run_post_compile_plugins ctx)
   ;; *)

let dependencies : (module Dependency.S) list =
  [
    (module Opam.Dependency);
    (module Node_js.Dependency : Dependency.S);
    (module Git_scm.Dependency : Dependency.S);
  ]
;;

let fold_dependency_to_result acc (module Dep : Dependency.S) =
  let open Promise_result.Syntax.Let in
  let+ check = Dep.check () in
  let result =
    match check with
    | `Pass -> `Pass (module Dep : Dependency.S)
    | `Fail -> `Fail (module Dep : Dependency.S)
  in
  acc |> Promise_result.map (fun results -> result :: results)
;;

let check_dependencies () =
  List.fold_left fold_dependency_to_result
    (Promise_result.resolve_ok [])
    dependencies
;;

module V2 = struct
  (* let extend_package_json  *)
end

module V3 = struct
  let directory_exists = Fs.exists
  let create_project_directory = Fs.create_project_directory
  let copy_base_project = Fs.copy_base_project

  let copy_bundler_files ~(bundler : Bundler.t) project_directory =
    match bundler with
    | None -> Promise_result.resolve_ok ()
    | Webpack -> Webpack.V2.Copy_webpack_config_js.exec project_directory
    | Vite -> Vite.V2.Copy_vite_config_js.exec project_directory
  ;;

  module Tea = struct
    type state =
      | Idle
      | Create_dir
      | Copy_base_templates
      | Bundler_copy_files
      | Bundler_extend_package_json
      | Node_pkg_manager
      | Git
      | Opam_create_switch
      | Opam_install_deps
      | Opam_install_dev_deps
      | Dune_build
      | Finished
      | Error

    let state_to_string = function
      | Idle -> "Idle"
      | Create_dir -> "Create_dir"
      | Copy_base_templates -> "Copy_base_templates"
      | Bundler_copy_files -> "Bundler_copy_files"
      | Bundler_extend_package_json -> "Bundler_extend_package_json"
      | Node_pkg_manager -> "Node_pkg_manager"
      | Git -> "Git"
      | Opam_create_switch -> "Opam_create_switch"
      | Opam_install_deps -> "Opam_install_deps"
      | Opam_install_dev_deps -> "Opam_install_dev_deps"
      | Dune_build -> "Dune_build"
      | Finished -> "Finished"
      | Error -> "Error"
    ;;

    type action = Start of state | Complete of state | Finished
    type transition = { from : state; action : action; to' : state }
    type error = Invalid_state_transition of state * action

    type model = {
      configuration : Configuration.t;
      pkg_json : Package_json.t Template_v2.t;
      dune_project : Dune_project.t Template_v2.t;
      state : state;
      on_transition : transition -> unit;
      on_error : error -> unit;
      on_finish : unit -> unit;
    }

    let to_next_state = function
      | Idle -> Create_dir
      | Create_dir -> Copy_base_templates
      | Copy_base_templates -> Bundler_copy_files
      | Bundler_copy_files -> Bundler_extend_package_json
      | Bundler_extend_package_json -> Node_pkg_manager
      | Node_pkg_manager -> Git
      | Git -> Opam_create_switch
      | Opam_create_switch -> Opam_install_deps
      | Opam_install_deps -> Opam_install_dev_deps
      | Opam_install_dev_deps -> Dune_build
      | Dune_build -> Finished
      | _ -> assert false
    ;;

    let make ~configuration ~on_transition ~on_error ~on_finish =
      {
        configuration;
        pkg_json = Package_json.template configuration.name;
        dune_project = Dune_project.template configuration.name;
        state = Idle;
        on_transition;
        on_error;
        on_finish;
      }
    ;;

    let transition ~(action : action) (model : model) : (model, error) result =
      match (model.state, action) with
      | (state, Start next_state | state, Complete next_state)
        when next_state = to_next_state state ->
          Ok { model with state = next_state }
      | _, _ -> Error (Invalid_state_transition (model.state, action))
    ;;

    let map ~f (model : model) = f model
  end

  let run ~(on_transition : Tea.transition -> unit)
      ~(on_error : Tea.error -> unit) ~(on_finish : unit -> unit)
      ~(configuration : Configuration.t) =
    Tea.make ~configuration ~on_transition ~on_error ~on_finish
    |> Tea.map ~f:(Tea.transition ~action:(Start Idle))
    |> Result.map (fun machine -> machine)
  ;;
end

[@@@ocaml.warning "-27-32"]

open Bindings
module String_map = Map.Make (String)

let dependencies : (module Dependency.S) list =
  [
    (module Opam.Dependency);
    (module Node_js.Dependency);
    (module Git_scm.Dependency);
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

let directory_exists = Fs.exists
let create_project_directory = Fs.create_project_directory
let copy_base_project dir = dir |> Fs.copy_base_project

let copy_bundler_files ~(bundler : Bundler.t) ~is_react_app project_directory =
  let open Promise_result.Syntax.Let in
  match bundler with
  | Webpack ->
      let+ _ = Webpack.Copy_webpack_config_js.exec project_directory in
      let+ _ = Webpack.Copy_index_html.exec project_directory in
      Promise_result.resolve_ok ()
  | Vite ->
      let+ _ = Vite.Copy_vite_config_js.exec project_directory in
      let+ _ = Vite.Copy_index_html.exec project_directory in
      Promise_result.resolve_ok ()
  | Esbuild ->
      let+ _ = Esbuild.Copy_esbuild_config_js.exec project_directory in
      let+ _ = Esbuild.Copy_index_html.exec project_directory in
      Promise_result.resolve_ok ()
;;

let extend_package_json_with_bundler ~(bundler : Bundler.t)
    ~(project_name : string) (pkg_json_tmpl : Package_json.t Template.t) =
  let dependencies, scripts =
    match bundler with
    | Webpack -> (Webpack.dev_dependencies, Webpack.scripts)
    | Vite -> (Vite.dev_dependencies, Vite.scripts)
    | Esbuild -> (Esbuild.dev_dependencies, Esbuild.scripts ~project_name)
  in
  pkg_json_tmpl
  |> Template.map (Package_json.add_scripts scripts)
  |> Template.map (Package_json.add_dependencies dependencies)
;;

let copy_app_files ~syntax_preference ~is_react_app project_directory =
  let open App_files in
  Copy.exec { project_directory; syntax_preference; is_react_app }
;;

let extend_package_json_with_app_settings ~(is_react_app : bool)
    (pkg_json_tmpl : Package_json.t Template.t) =
  if is_react_app then
    pkg_json_tmpl
    |> Template.map
         (Package_json.add_dependencies React.Package_json.dependencies)
  else pkg_json_tmpl
;;

let extend_dune_project_with_app_settings ~(is_react_app : bool)
    ~(project_name : string)
    (dune_project_tmpl : Dune.Dune_project.t Template.t) =
  if is_react_app then
    dune_project_tmpl
    |> Template.map
         (Dune.Dune_project.add_dependencies React.Dune_project.dependencies)
  else dune_project_tmpl
;;

let compile = Template.compile
let node_pkg_manager_install = Npm.Install.exec
let copy_git_ignore = Git_scm.Copy_gitignore.exec
let git_init_and_stage = Git_scm.Init_and_stage.exec
let opam_update = Opam.Update.exec
let opam_install_dune = Opam.Install_dune.exec
let dune_install = Dune.Install.exec
let opam_create_switch = Opam.Create_switch.exec
let opam_install_dev_dependencies = Opam.Install_dev_dependencies.exec
let opam_install_dependencies = Opam.Install_dependencies.exec
let dune_build = Dune.Build.exec

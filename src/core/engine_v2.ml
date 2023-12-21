(* val create_project_directoy: Core.Configuration.t => (unit, string) result
   val copy_base_template_directory: Core.Configuration.t => (unit, string) result
   val copy_extension_templates: Core.Configuration.t => (unit, string) result
   val precompile: Core.Configuration.t => (unit, string) result
   val compile_templates: Core.Configuration.t => (unit, string) result
   val postcompile: Core.Configuration.t => (unit, string) result
   val finish: Core.Configuration.t => (unit, string) result *)

let base_templates = []
let extension_templates = []

let create_project_directoy (config : Configuration.t) =
  Fs.create_project_directory ?overwrite:config.overwrite config.directory
  |> Js.Promise.catch (fun _ ->
         Js.Promise.resolve @@ Error "create_project failed")
;;

let copy_base_template_directory (config : Configuration.t) =
  Fs.copy_base_template_directory config.directory
;;

let copy_extension_templates (config : Configuration.t) = ()

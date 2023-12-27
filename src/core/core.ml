module Bundler = Bundler
module Configuration = Configuration
module Dependency = Dependency
module Dune_project = Dune_project
module Engine = Engine
module Fs = Fs
module Package_json = Package_json
module Template = Template
module Template_v2 = Template_v2
module Validation = Validation

(* module Context = struct
     module String_map = Map.Make (String)
     type t = {
       configuration : Configuration.t;
       (* Template name -> Template module *)
       templates : (module Template.S) String_map.t;
       (* Template key -> Template value*)
       template_values : Hmap.t;
     }

     type template_instance =
       | TemplateInstance :
           (module Template.S with type t = 'a) * 'a
           -> template_instance

     (* let base_templates : template_instance list =
          [
            TemplateInstance
              ( (module Package_json.Template : Template.S with type t = Package_json.t),
                Package_json.empty );
            TemplateInstance
              ( (module Dune_project.Template : Template.S with type t = Dune_project.t),
                Dune_project.empty );
          ]
        ;; *)

     let make ?(templates = String_map.empty) ?(template_values = Hmap.empty)
         ~configuration () =
       { configuration; templates; template_values }
     ;;

     let of_configuration (configuration : Configuration.t) =
       List.fold_left
         (fun ctx (TemplateInstance (template, empty_value)) ->
           let module TemplateInstance =
             (val template : Template.S with type t = 'a)
           in
           {
             ctx with
             templates =
               String_map.add TemplateInstance.name
                 (module TemplateInstance : Template.S)
                 ctx.templates;
             template_values =
               Hmap.add TemplateInstance.key empty_value ctx.template_values;
           })
         (make ~configuration ()) []
     ;;

     let get_template_by_name ~name ctx = String_map.find_opt name ctx.templates

     let get_template_value (type a)
         ~template:(module Template : Template.S with type t = a) ctx =
       Hmap.find Template.key ctx.template_values
     ;;

     let set_template_value (type a)
         ~template:(module Template : Template.S with type t = a) ~(value : a) ctx
         =
       {
         ctx with
         template_values = Hmap.add Template.key value ctx.template_values;
       }
     ;;
   end *)

(* module Extension = struct
     module type S = sig
       val extend : Context.t -> (Context.t, string) Promise_result.t
     end

     module Config = struct
       module type S = sig
         include Template.S

         val input_of_context : Context.t -> (t, string) Promise_result.t
         val extend : t -> (t, string) Promise_result.t
       end
     end

     module Make (M : Config.S) = struct
       let extend (ctx : Context.t) =
         ctx
         |> Context.get_template_value
              ~template:(module M : Template.S with type t = M.t)
         |> Option.to_result
              ~none:
                (Printf.sprintf "Template value not found for template: %s" M.name)
         |> Promise_result.resolve
         |. Promise_result.bind M.extend
         |> Promise_result.map (fun updated_value ->
                Context.set_template_value
                  ~template:(module M)
                  ~value:updated_value ctx)
       ;;
     end
   end *)

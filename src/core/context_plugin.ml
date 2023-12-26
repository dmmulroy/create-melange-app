(* module String_map = Map.Make (String)

   module rec Context : sig
     type t = {
       configuration : Configuration.t;
       (* Template name -> Template module *)
       templates : (module Template.S) String_map.t;
       (* Template key -> Template value*)
       template_values : Hmap.t;
       plugins : (module Plugin.S) list;
     }

     val make :
       ?templates:(module Template.S) String_map.t ->
       ?template_values:Hmap.t ->
       ?plugins:(module Plugin.S) list ->
       Configuration.t ->
       t

     val add_plugin : (module Plugin.S) -> t -> t
     val get_template : string -> t -> (module Template.S) option
     val get_template_value : 'a Hmap.key -> t -> 'a option
     val set_template_value : 'a Hmap.key -> 'a -> t -> t
   end = struct
     type t = {
       configuration : Configuration.t;
       (* Template name -> Template module *)
       templates : (module Template.S) String_map.t;
       (* Template key -> Template value*)
       template_values : Hmap.t; (* plugins : (module Plugin.S) list; *)
       plugins : (module Plugin.S) list;
     }

     let make ?(templates = String_map.empty) ?(template_values = Hmap.empty)
         ?(plugins = []) configuration =
       { configuration; templates; template_values; plugins }
     ;;

     let add_plugin plugin ctx = { ctx with plugins = plugin :: ctx.plugins }

     let get_template template_name ctx =
       String_map.find_opt template_name ctx.templates
     ;;

     let get_template_value template_key ctx =
       Hmap.find template_key ctx.template_values
     ;;

     let set_template_value template_key template_value ctx =
       {
         ctx with
         template_values = Hmap.add template_key template_value ctx.template_values;
       }
     ;;
   end

   and Plugin : sig
     type plugin
     type stage = [ `Pre_compile | `Post_compile ]

     module type S = sig
       val stage : stage
       val key : plugin Hmap.key
       val run : Context.t -> (Context.t, string) result Js.Promise.t
     end

     module Config : sig
       module Extension : sig
         module type S = sig
           include Template.S

           val stage : stage
           val extend_template : t -> (t, string) result Js.Promise.t
         end
       end

       module Process : sig
         module type S = sig
           include Process.S

           val stage : stage
           val input_of_context : Context.t -> (input, string) result
         end
       end
     end

     module Make_extension : functor (_ : Config.Extension.S) -> S
     module Make_process : functor (_ : Config.Process.S) -> S
   end = struct
     type plugin
     type stage = [ `Pre_compile | `Post_compile ]

     module type S = sig
       val stage : stage
       val key : plugin Hmap.key
       val run : Context.t -> (Context.t, string) result Js.Promise.t
     end

     module Config = struct
       module Extension = struct
         module type S = sig
           include Template.S

           val stage : stage
           val extend_template : t -> (t, string) result Js.Promise.t
         end
       end

       module Process = struct
         module type S = sig
           include Process.S

           val stage : stage
           val input_of_context : Context.t -> (input, string) result
         end
       end
     end

     module Make_extension (E : Config.Extension.S) : S = struct
       let key = Hmap.Key.create ()
       let stage = E.stage

       let run ctx =
         Context.get_template_value E.key ctx
         |> Option.to_result
              ~none:
                (Printf.sprintf "Template value not found for template: %s" E.name)
         |> Js.Promise.resolve
         (* TODO: Write Js.Promise.ok_then*)
         |> Js.Promise.then_ (fun template_value_result ->
                match template_value_result with
                | Error (error : string) -> Js.Promise.resolve (Error error)
                | Ok template_value -> E.extend_template template_value)
         |> Js.Promise.then_ (fun updated_template_value_result ->
                match updated_template_value_result with
                | Error (error : string) -> Js.Promise.resolve (Error error)
                | Ok updated_template_value ->
                    Context.set_template_value E.key updated_template_value ctx
                    |> Result.ok |> Js.Promise.resolve)
       ;;
     end

     module Make_process (C : Config.Process.S) : S = struct
       let key = Hmap.Key.create ()
       let stage = C.stage

       let run (ctx : Context.t) : (Context.t, string) result Js.Promise.t =
         let input_result = C.input_of_context ctx in
         match input_result with
         | Error (error : string) -> Js.Promise.resolve (Error error)
         | Ok input ->
             C.exec input
             |> Js.Promise.then_ (fun output_result ->
                    match output_result with
                    | Error (error : string) -> Js.Promise.resolve (Error error)
                    | Ok _ -> Js.Promise.resolve @@ Ok ctx)
       ;;
     end
   end

   module V2 = struct
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

     let base_templates : template_instance list =
       [
         TemplateInstance
           ( (module Package_json.Template : Template.S with type t = Package_json.t),
             Package_json.empty );
         TemplateInstance
           ( (module Dune_project.Template : Template.S with type t = Dune_project.t),
             Dune_project.empty );
       ]
     ;;

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
         (make ~configuration ()) base_templates
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

module String_map = Map.Make (String)

type t = {
  configuration : Configuration.t;
  (* Template name -> Template module *)
  templates : (module Template.S) String_map.t;
  (* Template key -> Template value*)
  template_values : Hmap.t;
}

(*
  type template_instance =
    | TemplateInstance :
        (module Template.S with type t = 'a) * 'a
        -> template_instance *)

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

let of_configuration (configuration : Configuration.t) = make ~configuration ()
(* List.fold_left
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
   (make ~configuration ()) base_templates *)

let get_template_by_name ~name ctx = String_map.find_opt name ctx.templates

let get_template_value (type a)
    ~template:(module Template : Template.S with type t = a) ctx =
  Hmap.find Template.key ctx.template_values
;;

let set_template_value (type a)
    ~template:(module Template : Template.S with type t = a) ~(value : a) ctx =
  { ctx with template_values = Hmap.add Template.key value ctx.template_values }
;;

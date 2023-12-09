open Common.Syntax.Let
module String_map = Map.Make (String)

module rec Context : sig
  type t = {
    configuration : Configuration.t;
    (* Template name -> Template module *)
    templates : (module Template.S) String_map.t;
    (* Template key -> Template value*)
    template_values : Hmap.t; (* plugins : (module Plugin.S) list; *)
    plugins : string list;
  }

  val make :
    ?templates:(module Template.S) String_map.t ->
    ?template_values:Hmap.t ->
    ?plugins:string list ->
    Configuration.t ->
    t

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
    plugins : string list;
  }

  let make ?(templates = String_map.empty) ?(template_values = Hmap.empty)
      ?(plugins = []) configuration =
    { configuration; templates; template_values; plugins }
  ;;

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

  module type S = sig
    val key : plugin Hmap.key
    val run : Context.t -> (Context.t, string) result
  end

  module Config : sig
    module Extension : sig
      module type S = sig
        include Template.S

        val extend_template : t -> (t, string) result
      end
    end

    module Command : sig
      module type S = sig
        val name : string
        val exec : Context.t -> (Context.t, string) result
      end
    end
  end

  module Make_extension : functor (_ : Config.Extension.S) -> S
  module Make_command : functor (_ : Config.Command.S) -> S
end = struct
  type plugin

  module type S = sig
    val key : plugin Hmap.key
    val run : Context.t -> (Context.t, string) result
  end

  module Config = struct
    module Extension = struct
      module type S = sig
        include Template.S

        val extend_template : t -> (t, string) result
      end
    end

    module Command = struct
      module type S = sig
        val name : string
        val exec : Context.t -> (Context.t, string) result
      end
    end
  end

  module Make_extension (E : Config.Extension.S) : S = struct
    let key = Hmap.Key.create ()

    let run ctx =
      let@ template_value =
        Context.get_template_value E.key ctx
        |> Option.to_result
             ~none:
               (Printf.sprintf "Template value not found for template: %s"
                  E.name)
      in
      let@ updated_template_value = E.extend_template template_value in
      Context.set_template_value E.key updated_template_value ctx |> Result.ok
    ;;
  end

  module Make_command (C : Config.Command.S) : S = struct
    let key = Hmap.Key.create ()
    let run = C.exec
  end
end

open Common.Syntax.Let

module type S = sig
  val run : Context.t -> (Context.t, string) result
end

module Config = struct
  module Extension = struct
    module type S = sig
      include Template.S

      val extend_template : t -> (t, string) result
    end
  end

  module Template = struct
    include Template.Config
  end

  module Command = struct
    module type S = sig
      val name : string
      val run : Context.t -> (Context.t, string) result
    end
  end
end

module Make_extension (E : Config.Extension.S) = struct
  let run ctx =
    let@ template_value =
      Context.get_template_value E.key ctx
      |> Option.to_result
           ~none:
             (Printf.sprintf "Template value not found for template: %s" E.name)
    in
    E.extend_template template_value
  ;;
end

(*
  1. Extending an existing template
  2. Copying/creating a new template
  4. Running a commands (npm install, git init, copying files, etc)
 *)

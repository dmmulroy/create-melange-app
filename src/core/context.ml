module String_map = Map.Make (String)

(* TODO: Start here *)
type 'a template_context = {
  template : (module Template.S with type t = 'a);
  instance : 'a;
  json : Js.Json.t;
}

type t = {
  configuration : Configuration.t;
  templates : ((module Template.S) * Js.Json.t) String_map.t;
}

let make ~configuration ?(templates = String_map.empty) () =
  { configuration; templates }
;;

let get_template_by_name ~name ctx = String_map.find_opt name ctx.templates

let get_template_value (type a)
    ~template:(module Template : Template.S with type t = a) ctx =
  String_map.find_opt Template.name ctx.templates |> Option.map snd
;;

let set_template_value (type a)
    ~template:(module T : Template.S with type t = a) ~(_value : a) _ctx =
  ()
;;
(* let json =  *)

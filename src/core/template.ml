open Bindings

let root_dir = "templates"
let base_dir = Node.Path.join [| root_dir; "base" |]
let dir_to_string = function `Base -> "./" | `Extension dir -> dir

module type S = sig
  type t

  val key : t Hmap.key
  val name : string
  val compile : dir:string -> t -> (unit, string) Promise_result.t
end

module Config = struct
  module type S = sig
    type t

    val name : string
    val to_json : t -> Js.Json.t
  end
end

module Make (M : Config.S) : S with type t = M.t = struct
  type t = M.t

  let key = Hmap.Key.create ()
  let name = M.name

  let compile ~dir value =
    let open Promise_result.Syntax.Let in
    let+ _ = Fs.validate_template_exists ~dir M.name in
    let json = M.to_json value in
    let| contents = Fs.read_template ~dir M.name in
    let template = Handlebars.compile contents () in
    let compiled_contents = template json () in
    Fs.write_template ~dir name compiled_contents |> Promise.resolve
  ;;
end

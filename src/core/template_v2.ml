open Bindings
open Js

type 'a t = { name : string; value : 'a; to_json : 'a -> Json.t }

let make ~name ~value ~to_json = { name; value; to_json }
let to_json (template : 'a t) : Json.t = template.value |> template.to_json

let map (fn : 'a -> 'b) (template : 'a t) : 'b t =
  { template with value = fn template.value }
;;

let compile ~dir template =
  let open Promise_result.Syntax.Let in
  let+ _ = Fs.validate_template_exists ~dir template.name in
  let json = to_json template in
  let| contents = Fs.read_template ~dir template.name in
  let compile_template = Handlebars.compile contents () in
  let compiled_contents = compile_template json () in
  Fs.write_template ~dir template.name compiled_contents
  |> Promise_result.resolve
;;

open Bindings
open Js

type 'a t = {
  name : string;
  value : 'a;
  dir : string;
  state : [ `Uncompiled | `Compiled ];
  to_json : 'a -> Json.t;
}

let make ~name ~value ~dir ~to_json =
  { name; value; dir; state = `Uncompiled; to_json }
;;

let to_json (template : 'a t) : Json.t = template.value |> template.to_json

let map (fn : 'a -> 'b) (template : 'a t) : 'b t =
  { template with value = fn template.value }
;;

let already_compiled_error_message template =
  let base_message =
    Format.sprintf "Already compiled '%s' template" template.name
  in
  Format.sprintf
    {|
    %s

    The scaffolding process failed while compiling templates. Please try 
    running `create-melange-app` again and choose to `Clear` the project 
    directory created by this run.

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
    base_message
;;

let compiled_error_message template =
  let base_message =
    Format.sprintf "Error compiling '%s' template" template.name
  in
  Format.sprintf
    {|
    %s

    The scaffolding process failed while compiling templates. Please try 
    running `create-melange-app` again and choose to `Clear` the project 
    directory created by this run.

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
    base_message
;;

let compile template =
  if template.state = `Compiled then
    Promise_result.resolve_error (already_compiled_error_message template)
  else
    let open Promise_result.Syntax.Let in
    let dir = template.dir in
    let+ _ = Fs.validate_template_exists ~dir template.name in
    let json = to_json template in
    let| contents = Fs.read_template ~dir template.name in
    let compile_template = Handlebars.compile contents () in
    let compiled_contents = compile_template json () in
    Fs.write_template ~dir template.name compiled_contents
    |> Promise_result.resolve
    |> Promise_result.map (Fun.const { template with state = `Compiled })
    |> Promise_result.map_error (Fun.const @@ compiled_error_message template)
;;

open Common
open Syntax
open Let

let compile value file_name =
  let@ contents = Fs.read_template file_name in
  let template = Handlebars.compile contents () in
  let compiled_contents = template value () in
  Fs.write_template file_name compiled_contents
;;

let compile_all (configuration : Configuration.t) =
  let template_file_names = Fs.get_template_file_names configuration.name in
  let compile_with_configuration = compile configuration in
  let x = List.map compile_with_configuration template_file_names in
  List.fold_left
    (fun acc result -> if Result.is_ok result then acc else result)
    (Ok ()) x
;;

[@@@ocaml.warning "-26-27"]

open Common
open Syntax
open! Let

type overwrite = Clear | Overwrite

let project_dir_exists = Fs_extra.existsSync
let project_dir_is_empty dir = Fs_extra.readdirSync dir |> Array.length = 0

(*
  let exists =Scaffold.project_dir_exists config.name
  // if exists then
  let is_empty = Scaffold.project_dir_is_empty config.name
  // if not is_empty then
  prompt of overwrite option
  // if abort then process.exit
  // else
    Scaffold.create_dir_with_clear config.name ~overwrite
 *)

let template_dir = Node.Path.join [| "."; "_templates"; "base" |]

let create_dir ?overwrite dir =
  match overwrite with
  | None -> Fs_extra.copySync template_dir dir
  | Some overwrite ->
      if overwrite = Clear then Fs_extra.emptyDirSync dir;
      Fs_extra.copySync template_dir dir
;;

(* function emptyDirSync(path: string): void *)
external emptyDirSync : string -> unit = "emptyDirSync"
[@@mel.module "fs-extra"]

external copySync : string -> string -> unit = "copySync"
[@@mel.module "fs-extra"]

external existsSync : string -> bool = "existsSync" [@@mel.module "fs-extra"]

external renameSync : string -> string -> unit = "renameSync"
[@@mel.module "fs-extra"]

external removeSync : string -> unit = "removeSync" [@@mel.module "fs-extra"]

let renameSync ~src ~dest =
  let src_path = Node.Path.join [| src |] in
  let dest_path = Node.Path.join [| dest |] in
  renameSync src_path dest_path
;;

let readdirSync = Node.Fs.readdirSync
let readFileSync = Node.Fs.readFileSync
let writeFileSync = Node.Fs.writeFileSync

(* function ensureDirSync(path: string): void *)

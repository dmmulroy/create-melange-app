external emptyDirSync : string -> unit = "emptyDirSync"
[@@mel.module "fs-extra/esm"]

external emptyDir : string -> unit Js.Promise.t = "emptyDir"
[@@mel.module "fs-extra/esm"]

external copySync : string -> string -> unit = "copySync"
[@@mel.module "fs-extra/esm"]

external copy : string -> string -> unit Js.Promise.t = "copy"
[@@mel.module "fs-extra/esm"]

external ensureDir : string -> unit Js.Promise.t = "ensureDir"
[@@mel.module "fs-extra/esm"]

external ensureDirSync : string -> unit = "ensureDirSync"
[@@mel.module "fs-extra/esm"]

external ensureFile : string -> unit Js.Promise.t = "ensureFile"
[@@mel.module "fs-extra/esm"]

external ensureFileSync : string -> unit = "ensureFileSync"
[@@mel.module "fs-extra/esm"]

external exists : string -> bool Js.Promise.t = "pathExists"
[@@mel.module "fs-extra/esm"]

external existsSync : string -> bool = "pathExistsSync"
[@@mel.module "fs-extra/esm"]

external renameSync : string -> string -> unit = "renameSync"
[@@mel.module "node:fs"]

external rename : string -> string -> unit Js.Promise.t = "rename"
[@@mel.module "node:fs/promises"]

let renameSync ~src ~dest =
  let src_path = Node.Path.join [| src |] in
  let dest_path = Node.Path.join [| dest |] in
  renameSync src_path dest_path
;;

let rename ~src ~dest =
  let src_path = Node.Path.join [| src |] in
  let dest_path = Node.Path.join [| dest |] in
  rename src_path dest_path
;;

external removeSync : string -> unit = "removeSync"
[@@mel.module "fs-extra/esm"]

external remove : string -> unit Js.Promise.t = "remove"
[@@mel.module "fs-extra/esm"]

external readdirSync : string -> string array = "readdirSync"
[@@mel.module "node:fs"]

external readdir : string -> string array Js.Promise.t = "readdir"
[@@mel.module "node:fs/promises"]

external readFileSync : string -> Node.Fs.encoding -> string = "readFileSync"
[@@mel.module "node:fs"]

let readFileSync string =
  try readFileSync string `utf8 |> Result.ok
  with _ -> Result.error "readFileSync failed"
;;

external readFile : string -> Node.Fs.encoding -> string Js.Promise.t
  = "readFile"
[@@mel.module "node:fs/promises"]

external writeFileSync : string -> string -> Node.Fs.encoding -> unit
  = "writeFileSync"
[@@mel.module "node:fs"]

external writeFile : string -> string -> Node.Fs.encoding -> unit Js.Promise.t
  = "writeFile"
[@@mel.module "node:fs/promises"]

external mkdirSync : string -> unit = "mkdirSync" [@@mel.module "node:fs"]

external mkdir : string -> unit Js.Promise.t = "mkdir"
[@@mel.module "node:fs/promises"]

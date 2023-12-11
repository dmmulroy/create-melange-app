external emptyDirSync : string -> unit = "emptyDirSync"
[@@mel.module "fs-extra"]

external emptyDir : string -> unit Js.Promise.t = "emptyDirSync"
[@@mel.module "fs-extra"]

external copySync : string -> string -> unit = "copySync"
[@@mel.module "fs-extra"]

external copy : string -> string -> unit Js.Promise.t = "copy"
[@@mel.module "fs-extra"]

external existsSync : string -> bool = "existsSync" [@@mel.module "fs-extra"]

external exists : string -> bool Js.Promise.t = "exists"
[@@mel.module "fs-extra"]

external renameSync : string -> string -> unit = "renameSync"
[@@mel.module "fs-extra"]

external rename : string -> string -> unit Js.Promise.t = "rename"
[@@mel.module "fs-extra"]

external removeSync : string -> unit = "removeSync" [@@mel.module "fs-extra"]

external remove : string -> unit Js.Promise.t = "remove"
[@@mel.module "fs-extra"]

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

external readdirSync : string -> string array = "readdirSync"
[@@mel.module "fs-extra"]

external readdir : string -> string array Js.Promise.t = "readdir"
[@@mel.module "fs-extra"]

external readFileSync : string -> Node.Fs.encoding -> string = "readFileSync"
[@@mel.module "fs-extra"]

external readFile : string -> Node.Fs.encoding -> string Js.Promise.t
  = "readFile"
[@@mel.module "fs-extra"]

external writeFileSync : string -> string -> Node.Fs.encoding -> unit
  = "writeFileSync"
[@@mel.module "fs-extra"]

external writeFile : string -> string -> Node.Fs.encoding -> unit Js.Promise.t
  = "writeFile"
[@@mel.module "fs-extra"]

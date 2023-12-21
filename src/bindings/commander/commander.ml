module Argument = Argument
module Opt = Opt
module Command = Command

external program : Command.t = "program" [@@mel.module "commander"]

external create_command : string -> Command.t = "createCommand"
[@@mel.module "commander"]
(** Factory routine to create a new unattached command.*)

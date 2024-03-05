module Big_text = Big_text
module Box = Box
module Gradient = Gradient
module Hooks = Hooks
module Instance = Instance
module Key = Key
module Link = Link
module Newline = Newline
module Spacer = Spacer
module Static = Static
module Stream = Stream
module Style = Style
module Text = Text
module Transform = Transform
module Ui = Ui

type render_options = {
  stdout : Stream.write option; [@mel.optional]
  stdin : Stream.read option; [@mel.optional]
  stderr : Stream.write option; [@mel.optional]
  debug : bool option; [@mel.optional]
  exit_on_ctrl_c : bool option; [@mel.optional]
  patch_console : bool option; [@mel.optional]
}
[@@deriving abstract]

external render : React.element -> Instance.t = "render" [@@mel.module "ink"]

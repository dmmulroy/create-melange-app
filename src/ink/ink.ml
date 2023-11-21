module Big_text = Big_text
module Box = Box
module Gradient = Gradient
module Hooks = Hooks
module Instance = Instance
module Key = Key
module Newline = Newline
module Spacer = Spacer
module Static = Static
module Stream = Stream
module Style = Style
module Text = Text
module Transform = Transform

type render_options = {
  stdout : Stream.write option; [@optional]
  stdin : Stream.read option; [@optional]
  stderr : Stream.write option; [@optional]
  debug : bool option; [@optional]
  exit_on_ctrl_c : bool option; [@optional]
  patch_console : bool option; [@optional]
}
[@@deriving abstract]

external render : React.element -> Instance.t = "render" [@@mel.module "ink"]

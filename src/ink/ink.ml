module Box = Box
module Instance = Instance
module Text = Text

type write_stream
type read_stream

type render_options = {
  stdout : write_stream option; [@optional]
  stdin : read_stream option; [@optional]
  stderr : write_stream option; [@optional]
  debug : bool option; [@optional]
  exit_on_ctrl_c : bool option; [@optional]
  patch_console : bool option; [@optional]
}
[@@deriving abstract]

external render : React.element -> Instance.t = "render" [@@mel.module "ink"]

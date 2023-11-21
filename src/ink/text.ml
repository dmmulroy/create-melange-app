external make :
  ?color:string ->
  ?backgrounColor:string ->
  ?dimColor:bool ->
  ?bold:bool ->
  ?italic:bool ->
  ?underline:bool ->
  ?strikethrough:bool ->
  ?inverse:bool ->
  ?wrap:
    ([ `Wrap
     | `Truncate
     | `Truncate_start [@mel.as "truncate-start"]
     | `Truncate_middle [@mel.as "truncate-middle"]
     | `Truncate_end [@mel.as "truncate-end"] ]
    [@mel.string]) ->
  children:React.element ->
  React.element = "Text"
[@@mel.module "ink"] [@@react.component]

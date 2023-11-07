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
    ([ `wrap
     | `truncate
     | `truncate_start [@mel.as "truncate-start"]
     | `truncate_middle [@mel.as "truncate-middle"]
     | `truncate_end [@mel.as "truncate-end"] ]
    [@mel.string]) ->
  children:React.element ->
  React.element = "Text"
[@@mel.module "ink"] [@@react.component]

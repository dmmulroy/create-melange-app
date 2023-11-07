external make :
  items:'a array ->
  ?style:Style.t ->
  children:(('a array -> int -> React.element)[@u]) ->
  React.element = "Static"
[@@mel.module "ink"] [@@react.component]

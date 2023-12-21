external make :
  transform:(string -> int -> string) -> children:React.element -> React.element
  = "Transform"
[@@mel.module "ink"] [@@react.component]

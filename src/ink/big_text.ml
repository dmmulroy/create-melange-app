external make :
  ?font:
    ([ `Block [@mel.as "block"]
     | `Slick [@mel.as "slick"]
     | `Tiny [@mel.as "tiny"]
     | `Grid [@mel.as "grid"]
     | `Pallet [@mel.as "pallet"]
     | `Shade [@mel.as "shade"]
     | `Simple [@mel.as "simple"]
     | `SimpleBlock [@mel.as "simpleBlock"]
     | `ThreeD [@mel.as "3d"]
     | `SimpleThreeD [@mel.as "simple3d"]
     | `Chrome [@mel.as "chrome"]
     | `Huge [@mel.as "huge"] ]
    [@mel.string]) ->
  ?align:
    ([ `Left [@mel.as "left"]
     | `Center [@mel.as "center"]
     | `Right [@mel.as "right"] ]
    [@mel.string]) ->
  ?colors:string list ->
  ?backgroundColor:
    ([ `Transparent [@mel.as "transparent"]
     | `Black [@mel.as "black"]
     | `Red [@mel.as "red"]
     | `Green [@mel.as "green"]
     | `Yellow [@mel.as "yellow"]
     | `Blue [@mel.as "blue"]
     | `Magenta [@mel.as "magenta"]
     | `Cyan [@mel.as "cyan"]
     | `White [@mel.as "white"] ]
    [@mel.string]) ->
  ?letterSpacing:float ->
  ?lineHeight:float ->
  ?space:bool ->
  ?maxLength:int ->
  children:React.element ->
  React.element = "default"
[@@mel.module ""] [@@react.component]

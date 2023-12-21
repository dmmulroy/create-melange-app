external make :
  ?name:
    ([ `Cristal [@mel.as "cristal"]
     | `Teen [@mel.as "teen"]
     | `Mind [@mel.as "mind"]
     | `Morning [@mel.as "morning"]
     | `Vice [@mel.as "vice"]
     | `Passion [@mel.as "passion"]
     | `Fruit [@mel.as "fruit"]
     | `Instagram [@mel.as "instagram"]
     | `Atlas [@mel.as "atlas"]
     | `Retro [@mel.as "retro"]
     | `Summer [@mel.as "summer"]
     | `Pastel [@mel.as "pastel"]
     | `Rainbow [@mel.as "rainbow"] ]
    [@mel.string]) ->
  ?colors:string array ->
  children:React.element ->
  React.element = "default"
[@@mel.module "ink-gradient"] [@@react.component]

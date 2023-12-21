external make :
  ?width:[ `int of int | `string of string ] ->
  ?height:[ `int of int | `string of string ] ->
  ?minHeight:int ->
  ?minWidth:int ->
  ?paddingTop:int ->
  ?paddingBottom:int ->
  ?paddingLeft:int ->
  ?paddingRight:int ->
  ?paddingX:int ->
  ?paddingY:int ->
  ?padding:int ->
  ?marginTop:int ->
  ?marginBottom:int ->
  ?marginLeft:int ->
  ?marginRight:int ->
  ?marginX:int ->
  ?marginY:int ->
  ?margin:int ->
  ?gap:int ->
  ?columnGap:int ->
  ?rowGap:int ->
  ?flexGrow:int ->
  ?flexShrink:int ->
  ?flexBasis:[ `int of int | `string of string ] ->
  ?flexDirection:
    [ `row
    | `column
    | `row_reverse [@mel.as "row-reverse"]
    | `column_reverse [@mel.as "column-reverse"] ] ->
  ?flexWrap:[ `wrap | `nowrap | `wrap_reverse [@mel.as "wrap-reverse"] ] ->
  ?alignItems:
    [ `flex_start [@mel.as "flex-start"]
    | `center
    | `flex_end [@mel.as "flex-end"] ] ->
  ?alignSelf:
    [ `auto
    | `flex_start [@mel.as "flex-start"]
    | `center
    | `flex_end [@mel.as "flex-end"] ] ->
  ?justifyContent:
    [ `flex_start [@mel.as "flex-start"]
    | `center
    | `flex_end [@mel.as "flex-end"]
    | `space_between [@mel.as "space-between"]
    | `space_around [@mel.as "space-around"] ] ->
  ?display:[ `flex | `none ] ->
  ?overflowX:[ `visible | `hidden ] ->
  ?overflowY:[ `visible | `hidden ] ->
  ?overflow:[ `visible | `hidden ] ->
  ?borderStyle:
    [ `solid
    | `double
    | `round
    | `bold
    | `single_double [@mel.as "single-double"]
    | `double_single [@mel.as "double-single"]
    | `classic
    | `BoxStyle ] ->
  ?borderColor:string ->
  ?borderTopColor:string ->
  ?borderLeftColor:string ->
  ?borderRightColor:string ->
  ?borderBottomColor:string ->
  ?borderDimColor:bool ->
  ?borderTopDimColor:bool ->
  ?borderLeftDimColor:bool ->
  ?borderRightDimColor:bool ->
  ?borderBottomDimColor:bool ->
  ?borderTop:bool ->
  ?borderLeft:bool ->
  ?borderRight:bool ->
  ?borderBottom:bool ->
  children:React.element ->
  React.element = "Box"
[@@mel.module "ink"] [@@react.component]

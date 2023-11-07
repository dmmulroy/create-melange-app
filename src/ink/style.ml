type dimension = [ `int of int | `string of string ]
type flex_dimension = [ `row | `column | `row_reverse | `column_reverse ]
type flex_wrap = [ `wrap | `nowrap | `wrap_reverse ]
type align_items = [ `flex_start | `center | `flex_end ]

type justify_content =
  [ `flex_start | `center | `flex_end | `space_between | `space_around ]

type display = [ `flex | `none ]
type overflow = [ `visible | `hidden ]

type border_style =
  [ `solid
  | `double
  | `round
  | `bold
  | `single_double
  | `double_single
  | `classic
  | `BoxStyle ]

type t = {
  width : dimension option;
  height : dimension option;
  minHeight : int option;
  minWidth : int option;
  paddingTop : int option;
  paddingBottom : int option;
  paddingLeft : int option;
  paddingRight : int option;
  paddingX : int option;
  paddingY : int option;
  padding : int option;
  marginTop : int option;
  marginBottom : int option;
  marginLeft : int option;
  marginRight : int option;
  marginX : int option;
  marginY : int option;
  margin : int option;
  gap : int option;
  columnGap : int option;
  rowGap : int option;
  flexGrow : int option;
  flexShrink : int option;
  flexBasis : dimension option;
  flexDirection : flex_dimension option;
  flexWrap : flex_wrap option;
  alignItems : align_items option;
  alignSelf : align_items option;
  justifyContent : justify_content option;
  display : display option;
  overflowX : overflow option;
  overflowY : overflow option;
  overflow : overflow option;
  borderStyle : border_style option;
  borderColor : string option;
  borderTopColor : string option;
  borderLeftColor : string option;
  borderRightColor : string option;
  borderBottomColor : string option;
  borderDimColor : bool option;
  borderTopDimColor : bool option;
  borderLeftDimColor : bool option;
  borderRightDimColor : bool option;
  borderBottomDimColor : bool option;
  borderTop : bool option;
  borderLeft : bool option;
  borderRight : bool option;
  borderBottom : bool option;
}

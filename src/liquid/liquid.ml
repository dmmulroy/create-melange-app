type dynamic = Dynamic : 'a -> dynamic [@@unboxed]

type liquid_options = {
  (* TODO: add bindingss for LiquidCache: https://github.com/harttle/liquidjs/blob/master/src/cache/cache.ts#L9 *)
  cache : [ `Number of int | `Boolean of bool ] option; [@optional]
  date_format : string option; [@optional] [@mel.as "dateFormat"]
  dynamic_partials : bool option; [@optional] [@mel.as "dynamicPartials"]
  extname : string option; [@optional]
  globals : dynamic Js.Dict.t option; [@optional]
  greedy : bool option; [@optional]
  jekyll_include : bool option; [@optional] [@mel.as "jekyllInclude"]
  js_truthy : bool option; [@optional] [@mel.as "jsTruthy"]
  keep_output_type : bool option; [@optional] [@mel.as "keepOutputType"]
  lenient_if : bool option; [@optional] [@mel.as "lenientIf"]
  (* TODO: add bindingss for Operators: https://github.com/harttle/liquidjs/blob/master/src/render/operator.ts#L10 *)
  operators : dynamic Js.Dict.t option; [@optional]
  ordered_filter_parameters : bool option;
      [@optional] [@mel.as "orderedFilterParameters"]
  output_delimiter_left : string option;
      [@optional] [@mel.as "outputDelimiterLeft"]
  output_delimiter_right : string option;
      [@optional] [@mel.as "outputDelimiterRight"]
  output_escape : [ `Escape | `Json ] option;
      [@mel.as "outputEscape"] [@optional]
  (* TODO: Ask the melange discord how we can potentially combine these two ↕ *)
  output_escape_fn : (dynamic -> string) option;
      [@optional] [@mel.as "outputEscape"]
  own_property_only : bool option; [@optional] [@mel.as "ownPropertyOnly"]
  partials : [ `String of string | `Strings of string array ] option;
      [@optional]
  preserve_timezeone : bool option; [@optional] [@mel.as "preserveTimezone"]
  relative_reference : bool option; [@optional] [@mel.as "relativeReference"]
  root : [ `String of string | `Strings of string array ] option; [@optional]
  strict_filters : bool option; [@optional] [@mel.as "strictFilters"]
  strict_variables : bool option; [@optional] [@mel.as "strictVariables"]
  tag_delimiter_left : string option; [@optional] [@mel.as "tagDelimiterLeft"]
  tag_delimiter_right : string option; [@optional] [@mel.as "tagDelimiterRight"]
  timezone_offset : [ `Int of int | `String of string ] option;
      [@optional] [@mel.as "timezoneOffset"]
  trim_tag_left : bool option; [@optional] [@mel.as "trimTagLeft"]
  trim_tag_right : bool option; [@optional] [@mel.as "trimTagRight"]
}
[@@deriving abstract]

type t

external make : ?options:liquid_options -> unit -> t = "Liquid"
[@@mel.new] [@@mel.module "liquidjs"]

(* TODO: Write binding *)
type template

external parse : ?filepath:string -> string -> template array = "parse"
[@@mel.send.pipe: t]

external render : unit -> unit = "render" [@@mel.send.pipe: t]

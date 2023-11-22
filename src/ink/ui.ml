module Text_input = struct
  external make :
    ?is_disabled:bool ->
    ?placeholder:string ->
    ?default_value:string ->
    ?suggestions:string array ->
    ?on_change:(string -> unit) ->
    ?value:string ->
    ?on_submit:(string -> unit) ->
    unit ->
    React.element = "TextInput"
  [@@mel.module "@inkjs/ui"] [@@react.component]
end

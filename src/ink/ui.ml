module Badge = struct
  external make :
    color:[ `green | `red | `blue | `yellow ] ->
    children:React.element ->
    React.element = "Badge"
  [@@mel.module "@inkjs/ui"] [@@react.component]
end

module Text_input = struct
  external make :
    ?isDisabled:bool ->
    ?placeholder:string ->
    ?defaultValue:string ->
    ?suggestions:string array ->
    ?onChange:(string -> unit) ->
    ?value:string ->
    ?onSubmit:(string -> unit) ->
    unit ->
    React.element = "TextInput"
  [@@mel.module "@inkjs/ui"] [@@react.component]
end

module Select = struct
  type select_option = { label : string; value : string }

  external make :
    ?isDisabled:bool ->
    ?visibleOptionCount:int ->
    ?highlightText:string ->
    ?defaultValue:string ->
    options:select_option array ->
    ?onChange:(string -> unit) ->
    unit ->
    React.element = "Select"
  [@@mel.module "@inkjs/ui"] [@@react.component]
end

module Spinner = struct
  external make : label:string -> React.element = "Spinner"
  [@@mel.module "@inkjs/ui"] [@@react.component]
end

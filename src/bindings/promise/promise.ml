type exn += Promise_error of string
type 'value t = 'value Js.Promise.t

let and_then = Js.Promise.then_
let resolve value = Js.Promise.resolve value
let of_js_promise (promise : 'value Js.Promise.t) : 'value t = promise

let reject (error_message : string) =
  Js.Promise.reject (Promise_error error_message)
;;

external catch : (('error -> 'error t)[@mel.uncurry]) -> 'error t = "catch"
[@@mel.send.pipe: 'error t]

let map (fn : 'value -> 'next_value) (promise : 'value t) : 'next_value t =
  and_then (fun value -> resolve (fn value)) promise
;;

let bind (promise : 'value t) (fn : 'value -> 'next_value t) : 'next_value t =
  and_then fn promise
;;

let tap (fn : 'value -> unit) (promise : 'value t) : 'value t =
  promise
  |> map (fun value ->
         fn value;
         value)
;;

module Syntax = struct
  module Infix = struct
    let ( >|= ) promise fn = map fn promise
    let ( >>= ) = bind
  end

  module Let = struct
    let ( let* ) = bind
  end
end

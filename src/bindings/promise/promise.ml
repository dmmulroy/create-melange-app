type exn += Promise_error of string
type 'value t = 'value Js.Promise.t

external catch : (('error -> 'next_value t)[@mel.uncurry]) -> 'next_value t
  = "catch"
[@@mel.send.pipe: 'next_value t]

let and_then = Js.Promise.then_
let resolve value = Js.Promise.resolve value

let reject (error_message : string) =
  Js.Promise.reject (Promise_error error_message)
;;

let of_js_promise (promise : 'value Js.Promise.t) : 'value t = promise

let map (fn : 'value -> 'next_value) (promise : 'value t) : 'next_value t =
  and_then (fun value -> resolve (fn value)) promise
;;

let bind (promise : 'value t) (fn : 'value -> 'next_value t) : 'next_value t =
  and_then fn promise
;;

let tap (fn : 'value -> unit) (promise : 'value t) : 'value t =
  promise
  |> and_then (fun value ->
         fn value;
         resolve value)
;;

let perform (fn : 'value -> unit) (promise : 'value t) : unit =
  promise |> tap fn |> ignore
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

type ('value, 'error) t = ('value, 'error) result Promise.t

let resolve (result : ('value, 'error) result) : ('value, 'error) t =
  Promise.resolve result
;;

let resolve_ok (value : 'value) : ('value, 'error) t = resolve (Ok value)
let resolve_error (error : 'error) : ('value, 'error) t = resolve (Error error)

external catch :
  (('error -> ('value, 'error) t)[@mel.uncurry]) -> ('value, 'error) t = "catch"
[@@mel.send.pipe: ('value, 'error) t]

let map (fn : 'value -> 'next_value) (promise_result : ('value, 'error) t) :
    ('next_value, 'error) t =
  let open Promise.Syntax.Let in
  let* result = promise_result in
  match result with
  | Ok value -> resolve_ok (fn value)
  | Error error -> resolve_error error
;;

let bind (promise_result : ('value, 'error) t)
    (fn : 'value -> ('next_value, 'error) t) : ('next_value, 'error) t =
  let open Promise.Syntax.Let in
  let* result = promise_result in
  match result with Ok value -> fn value | Error error -> resolve_error error
;;

let map_error (fn : 'error -> 'next_error) (promise_result : ('value, 'error) t)
    : ('value, 'next_error) t =
  let open Promise.Syntax.Let in
  let* result = promise_result in
  match result with
  | Ok (value : 'value) -> resolve_ok value
  | Error error -> resolve_error (fn error)
;;

module Syntax = struct
  module Infix = struct
    let ( >|= ) promise fn = map fn promise
    let ( >>= ) = bind
    let ( >|? ) promise fn = map_error fn promise
  end

  module Let = struct
    let ( let+ ) = bind
    let ( let| ) var fn = bind (resolve var) fn
    let ( let*| ) var fn = bind (Promise.map Result.ok var) fn
  end
end

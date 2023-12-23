type ('value, 'error) t = ('value, 'error) result Promise.t

external catch :
  (('error -> ('value, 'error) t)[@mel.uncurry]) -> ('value, 'error) t = "catch"
[@@mel.send.pipe: ('value, 'error) t]

let resolve (result : ('value, 'error) result) : ('value, 'error) t =
  result |> Promise.resolve
  |> catch (fun error -> Promise.resolve (Error error))
;;

let resolve_ok (value : 'value) : ('value, 'error) t = resolve (Ok value)
let resolve_error (error : 'error) : ('value, 'error) t = resolve (Error error)

let of_promise (promise : 'value Promise.t) =
  let open Promise.Syntax.Let in
  let* result = promise in
  resolve_ok result
;;

let of_js_promise (promise : 'value Js.Promise.t) =
  promise |> Promise.of_js_promise |> of_promise
;;

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

let tap (fn : ('value, 'error) result -> unit)
    (promise_result : ('value, 'error) t) : ('value, 'error) t =
  promise_result |> Promise.tap fn
;;

let is_ok (promise_result : ('value, 'error) t) : bool Promise.t =
  let open Promise.Syntax.Let in
  let* result = promise_result in
  match result with
  | Ok _ -> Promise.resolve true
  | Error _ -> Promise.resolve false
;;

let is_error (promise_result : ('value, 'error) t) : bool Promise.t =
  let open Promise.Syntax.Let in
  let* result = promise_result in
  match result with
  | Ok _ -> Promise.resolve false
  | Error _ -> Promise.resolve true
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

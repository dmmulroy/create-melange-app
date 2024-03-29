(** OCaml interface for enhanced promise handling with result types *)

type ('value, 'error) t = ('value, 'error) result Promise.t
(** Type definition for a Promise wrapping a result type. *)

val resolve : ('value, 'error) result -> ('value, 'error) t
(** [resolve result] creates a promise resolved with [result]. *)

val resolve_ok : 'value -> ('value, 'error) t
(** [resolve_ok value] creates a promise resolved with [Ok value]. *)

val resolve_error : 'error -> ('value, 'error) t
(** [resolve_error error] creates a promise resolved with [Error error]. *)

val of_promise : 'value Promise.t -> ('value, 'a) result Promise.t
(** [of_promise promise] wraps  [promise] with an Ok variant. *)

val of_js_promise : 'value Js.Promise.t -> ('value, 'a) result Promise.t
(** [of_js_promise promise] wraps  [promise] with an Ok variant. *)

val catch :
  ('error -> ('value, 'error) t) -> ('value, 'error) t -> ('value, 'error) t
(** [catch fn promise_result] catches an error and returns a new promise. *)

val map :
  ('value -> 'next_value) -> ('value, 'error) t -> ('next_value, 'error) t
(** [map fn promise_result] applies [fn] to the Ok part of [promise_result]. *)

val bind :
  ('value, 'error) t ->
  ('value -> ('next_value, 'error) t) ->
  ('next_value, 'error) t
(** [bind promise_result fn] chains a promise with a result or an error. *)

val map_error :
  ('error -> 'next_error) -> ('value, 'error) t -> ('value, 'next_error) t
(** [map_error fn promise_result] applies [fn] to the Error part of [promise_result]. *)

val tap :
  (('value, 'error) result -> unit) -> ('value, 'error) t -> ('value, 'error) t
(** [tap fn promise_result] applies [fn] to the result of [promise_result] and returns the original promise. *)

val perform : (('value, 'error) result -> unit) -> ('value, 'error) t -> unit
(** [perform fn promise_result] applies [fn] to the result of [promise_result] and returns unit. *)

val is_ok : ('value, 'error) t -> bool Promise.t
(** [is_ok promise_result] returns true if [promise_result] is Ok. *)

val is_error : ('value, 'error) t -> bool Promise.t
(** [is_error promise_result] returns true if [promise_result] is Error. *)

(** Module containing syntax extensions for promises. *)
module Syntax : sig
  (** Infix operators for promise operations. *)
  module Infix : sig
    val ( >|= ) :
      ('value, 'error) t -> ('value -> 'next_value) -> ('next_value, 'error) t
    (** []>>|] is an infix operator for [map]. *)

    val ( >>= ) :
      ('value, 'error) t ->
      ('value -> ('next_value, 'error) t) ->
      ('next_value, 'error) t
    (** [>>=] is an infix operator for [bind]. *)

    val ( >|? ) :
      ('value, 'error) t -> ('error -> 'next_error) -> ('value, 'next_error) t
    (** [>|?] is an infix operator for [map_error]. *)
  end

  (** Let syntax for promise operations. *)
  module Let : sig
    val ( let+ ) :
      ('value, 'error) t ->
      ('value -> ('next_value, 'error) t) ->
      ('next_value, 'error) t
    (** [let+] is syntactic sugar for [bind]. *)

    val ( let| ) :
      ('value, 'error) result ->
      ('value -> ('next_value, 'error) t) ->
      ('next_value, 'error) t
    (** [let|] lifts a result to a promise, applying [fn]. *)

    val ( let*| ) :
      'value Promise.t ->
      ('value -> ('next_value, 'error) t) ->
      ('next_value, 'error) t
    (** [let*|] lifts a value to a promise with an Ok variant, applying [fn]. *)
  end
end

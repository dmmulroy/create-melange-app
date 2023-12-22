(** OCaml interface for enhanced promise handling with result types *)

type ('value, 'error) t = ('value, 'error) result Promise.t
(** Type definition for a Promise wrapping a result type. *)

val resolve : ('value, 'error) result -> ('value, 'error) t
(** [resolve result] creates a promise resolved with [result]. *)

val resolve_ok : 'value -> ('value, 'error) t
(** [resolve_ok value] creates a promise resolved with [Ok value]. *)

val resolve_error : 'error -> ('value, 'error) t
(** [resolve_error error] creates a promise resolved with [Error error]. *)

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

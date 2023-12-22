(** OCaml interface for enhanced promise handling *)

(** Extension of exceptions for promise error handling. *)
type exn += Promise_error of string

type 'value t
(** A type representing a promise. *)

val resolve : 'value -> 'value t
(** [resolve value] creates a promise that is immediately resolved with [value]. *)

val reject : string -> exn t
(** [reject error_message] creates a promise that is immediately rejected with [error_message]. *)

val catch : ('error -> 'error t) -> 'error t -> 'error t
(** [catch fn promise] applies [fn] to the error of [promise], returning a new promise. *)

val map : ('value -> 'next_value) -> 'value t -> 'next_value t
(** [map fn promise] applies [fn] to the result of [promise], returning a new promise. *)

val bind : 'value t -> ('value -> 'next_value t) -> 'next_value t
(** [bind promise fn] applies [fn] to the result of [promise], chaining promises. *)

(** Module containing syntax extensions for promises. *)
module Syntax : sig
  (** Infix operators for promise operations. *)
  module Infix : sig
    val ( >>= ) : 'value t -> ('value -> 'next_value t) -> 'next_value t
    (** [>>=] is an infix operator for [bind]. *)

    val ( >|= ) : 'value t -> ('value -> 'next_value) -> 'next_value t
    (** [>|=] is an infix operator for [map]. *)
  end

  (** Let syntax for promise operations. *)
  module Let : sig
    val ( let* ) : 'value t -> ('value -> 'next_value t) -> 'next_value t
    (** [let*] is syntactic sugar for [bind]. *)
  end
end

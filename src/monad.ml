module type MONAD = sig
  type 'a t

  val map : ('a -> 'b) -> 'a t -> 'b t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t
end

module Monads = struct
  module Identity : MONAD with type 'a t = 'a = struct
    type 'a t = 'a

    let map fn a = fn a
    let bind a fn = fn a
    let return a = a
  end
end

module Make (M : MONAD) = struct
  open! M

  (* let ( >>= ) = bind
     let ( >|= ) = map
     let ( let* ) = bind
     let ( let+ ) = map *)
end

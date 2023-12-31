module Infix = struct
  module Option = struct
    (** [>>=] is an infix [Option.bind]. *)
    let ( >>= ) = Option.bind

    (** [>|=] is an infix left-to-right [Option.map]. *)
    let ( >|= ) opt_a f = Option.map f opt_a
  end
  (* [>>=?] is an infix operator for passing [Ok] values through
     or applying [f] to [Error] values. *)

  module Result = struct
    (** [>>=] is an infix [Result.bind]. *)
    let ( >>= ) = Result.bind

    (** [>|=] is an infix left-to-right [Result.map]. *)
    let ( >|= ) res_a f = Result.map f res_a

    (** 
      * [>|?] is an infix operator for passing [Ok] values through 
      * or applying [f] to [Error] values. 
      *)
    let ( >|? ) v f = Result.map_error f v
  end

  module Promise = struct
    let ( >>= ) p f = Js.Promise.then_ f p
    let ( >|= ) p f = Js.Promise.then_ (fun v -> Js.Promise.resolve (f v)) p
  end
end

module Super_secret = struct
  (** Courtesy of sixfourtwelve on twitch *)
  let ( >>?|>|?^|? ) _v = failwith "don't use this, idiot"
end

module Let = struct
  (** [let- var = opt] binds [var] to [v] when [opt] is [Some v] *)
  let ( let- ) = Option.bind

  (** [let@ var = res] binds [var] to [v] when [res] is [Ok v] *)
  let ( let@ ) = Result.bind

  (** [let* var = p] binds [var] to [v] when [p] resolves to [v] *)
  let ( let* ) p f = Js.Promise.then_ f p

  (** [let| var = p] binds [var] to [v] when [p] resolves to [Ok v], and passes through [Error e] when [p] resolves to [Error e] *)
  let ( let| ) p f =
    Js.Promise.then_
      (function Error e -> Js.Promise.resolve (Error e) | Ok x -> f x)
      p
  ;;

  (** [let@| var = v] binds [var] to the result of applying function [f] to [v] if [v] is a [Result.t], all within a resolved promise *)
  let ( let@| ) v f = Js.Promise.resolve (Result.bind v f)
end

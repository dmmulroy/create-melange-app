open Bindings

module type S = sig
  val check : unit -> ([ `Pass | `Fail ], string) Promise_result.t
  val help : string
  val name : string
  val required : bool
end

module Config = struct
  module type S = sig
    include Process.S

    val required : bool
    val input : input
    val help : string
  end
end

module Make (C : Config.S) : S = struct
  let name = C.name
  let required = C.required
  let help = C.help

  let check () =
    C.exec C.input
    |. Promise.bind (fun result ->
           match result with
           | Ok _ -> Promise_result.resolve_ok `Pass
           | Error _ -> Promise_result.resolve_ok `Fail)
  ;;
end

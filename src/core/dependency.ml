module type S = sig
  val check : unit -> (bool, string) result Js.Promise.t
  val help : string
  val name : string
  val required : bool
end

type check_result = {
  dependency : (module S);
  status : [ `Pass | `Failed of string ];
}

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
    |> Js.Promise.then_ (fun output_result ->
           match output_result with
           | Error (error : string) -> Js.Promise.resolve (Error error)
           | Ok _ -> Js.Promise.resolve @@ Ok true)
  ;;
end

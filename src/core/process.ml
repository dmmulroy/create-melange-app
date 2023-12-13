module type S = sig
  type input
  type output

  val name : string
  val exec : input -> (output, string) result Js.Promise.t
end

module Node = struct
  module Version : S = struct
    type input = unit
    type output = string

    let name = "node --version"

    let exec (_input : input) : (output, string) result Js.Promise.t =
      let options = Node.Child_process.option ~encoding:"utf8" () in
      Nodejs.Child_process.async_exec "node --version" options
      |> Js.Promise.then_ (fun value -> Js.Promise.resolve @@ Ok value)
      |> Js.Promise.catch (fun _err ->
             Js.Promise.resolve @@ Error "Failed to run node --version")
    ;;
  end
end

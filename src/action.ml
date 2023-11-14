module type S = sig
  type input
  type output

  val name : string
  val run : input -> output
end

module Env_check = struct
  (* TODO: Add level logging *)
  let name = "env-check"

  type input = unit
  type output = ([ `Pass ], [ `All | `Node | `Opam ]) result

  let check_opam () =
    let cmd_options = Node.Child_process.option ~encoding:"utf8" () in
    try
      let version = Node.Child_process.execSync "opam --version" cmd_options in
      Js.log version;
      Ok ()
    with _ -> Error (`Msg "opam was not found")

  let check_node () =
    let cmd_options = Node.Child_process.option ~encoding:"utf8" () in
    try
      let version = Node.Child_process.execSync "node --version" cmd_options in
      Js.log version;
      Ok ()
    with _ -> Error (`Msg "node was not found")

  let run () =
    match (check_opam (), check_node ()) with
    (* Both dependencies were found and resolved successfully *)
    | Ok _, Ok _ -> Ok `Pass
    (* Opam was not found, but node was *)
    | Error _, Ok _ -> Error `Opam
    (* Node was not found, but opam was *)
    | Ok _, Error _ -> Error `Node
    (* Neither opam nor node were found *)
    | Error _, Error _ -> Error `All
end

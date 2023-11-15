let name = "env-check"

let run () =
  let opam_result = Dependency.Opam.check () in
  let node_result = Dependency.Node.check () in
  match (opam_result, node_result) with
  | Ok opam, Ok node -> Ok [ Dependency.Opam opam; Dependency.Node node ]
  | Error _, Ok _ -> Error [ "opam" ]
  | Ok _, Error _ -> Error [ "node" ]
  | Error _, Error _ -> Error [ "opam"; "node" ]

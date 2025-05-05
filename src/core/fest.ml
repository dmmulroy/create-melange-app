[@@@ocaml.warning "-32"]

open Package_json
module String_map = Map.Make (String)

let react_dependencies =
  [
    Dependency.make ~kind:`Development ~name:"@testing-library/react"
      ~version:"^14.0.0";
    Dependency.make ~kind:`Development ~name:"jsdom" ~version:"^22.1.0";
  ]
;;

let scripts =
  [
    Script.make ~name:"test" ~script:"dune build --force @runtest";
    Script.make ~name:"test:watch" ~script:"dune build --force @runtest -w";
  ]
;;

module Dune_project = struct
  open Dune.Dune_project

  let dependencies = [ Dependency.make "melange-fest" ]
  let react_dependencies = [ Dependency.make "melange-testing-library" ]
end

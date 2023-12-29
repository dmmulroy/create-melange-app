module Package_json = struct
  open Package_json

  let dependencies =
    [
      Dependency.make ~kind:`Regular ~name:"react" ~version:"^18.0.0";
      Dependency.make ~kind:`Regular ~name:"react-dom" ~version:"^18.0.0";
    ]
  ;;
end

module Dune_project = struct
  open Dune.Dune_project

  let dependencies =
    [
      Dependency.make ~version:">= 0.13.0" "reason-react";
      Dependency.make "reason-react-ppx";
    ]
  ;;
end

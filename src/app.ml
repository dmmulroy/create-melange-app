let _ =
  let open Commander in
  let opts =
    program
    |> Command.option ~flags:"--first"
    |> Command.option ~flags:"-s, --separator <char>"
    |> Command.opts ()
  in
  let _ = Command.parse program in
  Js.Console.log opts

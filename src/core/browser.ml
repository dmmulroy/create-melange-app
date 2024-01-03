open Bindings

module Open_app :
  Process.S with type input = Configuration.t and type output = unit = struct
  type input = Configuration.t
  type output = unit

  let name = "open app"

  let exec (_configuration : Configuration.t) =
    Open.open_browser "localhost:5473/" |> ignore |> Promise_result.resolve_ok
  ;;
end

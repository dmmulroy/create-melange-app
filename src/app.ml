let main () =
  let open Commander in
  let _ =
    program
    |> Command.set_name "create-melange-app"
    |> Command.set_description "A CLI for creating applications with Melange"
    |> Command.set_version "0.0.1"
    |> Command.argument ~name:"[dir]"
         ~description:
           "The name of the application, as well as the name of the directory \
            to create"
    |> Command.add_action (fun (a : string) ->
           Js.Console.log a;
           `Void ())
    |> Command.parse
  in
  ()

let () = main ()

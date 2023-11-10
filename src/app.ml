let main () =
  let root_command =
    Cli.Command.make ~name:"create-melange-app"
      ~description:"A CLI for creating applications with Melange"
      ~arguments:
        [
          Cli.Argument.make ~name:"dir"
            ~description:
              "The name of the application, as well as the name of the \
               directory to create"
            ~required:false ();
        ]
      ()
  in
  let program =
    Cli.Program.make ~root_command ~version:"0.0.1" () |> Cli.Commander_js.make
  in
  let _ = Commander.Command.parse program in
  ()

let () = main ()

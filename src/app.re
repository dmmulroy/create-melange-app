let main = () => {
  open Commander;

  let env_check =
    Commander.create_command("env-check")
    |> Command.set_description(
         "Check and validate that all system dependencies are installed",
       );

  let _ =
    program
    |> Command.set_name("create-melange-app")
    |> Command.set_description(
         "A CLI for creating applications with Melange",
       )
    |> Command.set_version("0.0.1", ~flags="-v")
    |> Command.argument(
         ~name="[dir]",
         ~description=
           "The name of the application, as well as the name of the directory to create",
       )
    |> Command.add_action((a: string) => {
         let ink =
           Ink.render(<Ink.Text color="blue"> {React.string(a)} </Ink.Text>);
         `Promise_void(Ink.Instance.wait_until_exit(ink));
       })
    |> Command.add_command(env_check)
    |> Command.parse;

  ();
};

let () = main();

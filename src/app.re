let main = () => {
  open Commander;

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
    |> Command.add_action1((dir: option(string), _this) => {
         Ink.render(<Init.Component name=dir />)
         |> Ink.Instance.wait_until_exit
         |> (exit_promise => `Promise_void(exit_promise))
       })
    |> Command.add_command(Env_check.command)
    |> Command.parse;

  // print_endline(Cma.Scaffold.Package_json_template.name);
  ();
};
let () = main();

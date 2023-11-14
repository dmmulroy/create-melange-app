[@ocaml.warning "-32"]
//open Syntax;
//open Let;
let main = () => {
  open Commander;

  let env_check =
    Commander.create_command("env-check")
    |> Command.set_description(
         "Check and validate that all system dependencies are installed",
       )
    |> Command.add_action(((), _this) => {
         let result = Action.Env_check.run();

         switch (result) {
         | Ok(_) =>
           let ink =
             Ink.render(
               <Ink.Text color="green"> {React.string("Success")} </Ink.Text>,
             );
           `Promise_void(Ink.Instance.wait_until_exit(ink));
         | Error(err) =>
           let missing_dep =
             switch (err) {
             | `Opam => "opam"
             | `Node => "node"
             | `All => "all"
             };
           let ink =
             Ink.render(
               <Ink.Text color="red">
                 {React.string(
                    {
                      "Failure: " ++ missing_dep;
                    },
                  )}
               </Ink.Text>,
             );
           `Promise_void(Ink.Instance.wait_until_exit(ink));
         };
       });

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
    |> Command.add_action1((a: string, _this) => {
         let ink =
           Ink.render(<Ink.Text color="blue"> {React.string(a)} </Ink.Text>);
         `Promise_void(Ink.Instance.wait_until_exit(ink));
       })
    |> Command.add_command(env_check)
    |> Command.parse;

  ();
};

let () = main();

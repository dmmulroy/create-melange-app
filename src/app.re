open Bindings;
open Commander;

let run = () => {
  program
  |> Command.set_name("create-melange-app")
  |> Command.set_description("A CLI for creating applications with Melange")
  |> Command.set_version("1.1.1", ~flags="-v")
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
  // We'll uncomment this when caml-install is ready
  // |> Command.add_command(Ocaml_install.command)
  |> Command.parse
  |> ignore;
};

open Bindings;
module Component = Component;

let command = {
  Commander.(
    create_command("ocaml-install")
    |> Command.set_description(
         "Adds OCaml and ReasonML dependencies to your projects via opam, OCaml's package manager. This command will add the dependency to your `dune-project` file, regenerate your projects .opam file, and install the dependencies.",
       )
    |> Command.argument(
         ~name="<package>",
         ~description="The name of the package to install",
       )
    |> Command.add_action1((package: string, _this) => {
         Ink.render(<Component _package=package />)
         |> Ink.Instance.wait_until_exit
         |> (exit_promise => `Promise_void(exit_promise))
       })
  );
};

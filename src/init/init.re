module Component = Component;

let command = {
  Commander.(
    create_command("init")
    |> Command.set_description(
         "Check and validate that all system dependencies are installed",
       )
    |> Command.add_action(((), _this) => {`Void()})
  );
};

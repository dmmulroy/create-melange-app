external __dirname: string = "__dirname";

//let main = () => {
//  open Commander;
//
//  let _ =
//    program
//    |> Command.set_name("create-melange-app")
//    |> Command.set_description(
//         "A CLI for creating applications with Melange",
//       )
//    |> Command.set_version("0.0.1", ~flags="-v")
//    |> Command.argument(
//         ~name="[dir]",
//         ~description=
//           "The name of the application, as well as the name of the directory to create",
//         ~default_value=`String(__dirname),
//       )
//    |> Command.add_action1((dir: string, _this) => {
//         Ink.render(<Init.Component dir />)
//         |> Ink.Instance.wait_until_exit
//         |> (exit_promise => `Promise_void(exit_promise))
//       })
//    |> Command.add_command(Env_check.command)
//    |> Command.parse;
//
//  ();
//};

module Counter = {
  [@react.component]
  let make = () => {
    let (count, set_count) = React.useState(() => 0);

    React.useEffect0(() => {
      let interval =
        Js.Global.setInterval(() => {set_count(count => count + 1)}, 1000);
      Some(() => Js.Global.clearInterval(interval));
    });

    let str_count = string_of_int(count);

    <Ink.Text color="green">
      {React.string(str_count ++ " tests passed")}
    </Ink.Text>;
  };
};

module Example = {
  [@react.component]
  let make = () => {
    let (value, setValue) = React.useState(() => "");

    <Ink.Box padding=2 flexDirection=`column gap=1>
      <Ink.Ui.Text_input
        placeholder="Start typing..."
        on_change={new_value => setValue(_ => new_value)}
      />
      <Ink.Text> {React.string("Input value: " ++ value)} </Ink.Text>
    </Ink.Box>;
  };
};

let _ = Ink.render(<Example />);

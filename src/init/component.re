open Ink;
open! Common;

type env_check_result =
  result(
    (Env_check.Dependency.Node.t, Env_check.Dependency.Opam.t),
    (string, string),
  );

[@react.component]
let make = (~dir as _dir: string) => {
  let (value, set_value) = React.useState(() => "");
  let (_env_check_result: option([ | `Pass | `Fail]), set_env_check_result) =
    React.useState(() => None);

  let _on_env_check = (result: env_check_result) => {
    switch (result) {
    | Ok(_) => set_env_check_result(_ => Some(`Pass))
    | Error(_) => set_env_check_result(_ => Some(`Fail))
    };
  };

  <Box flexDirection=`column gap=1>
    <Ui.Text_input
      placeholder="Start typing..."
      on_change={new_value => set_value(_ => new_value)}
    />
    <Text> {React.string("Value: " ++ value)} </Text>
  </Box>;
  //
};
//switch (env_check_result) {
//| Some(`Pass) =>
//  <>
//    <Gradient name=`Retro> <Banner /> </Gradient>
//    <Env_check.Component />
//    <Text> {React.string("success - starting initialization...")} </Text>
//  </>
//| _ =>
//  <>
//    <Gradient name=`Retro> <Banner /> </Gradient>
//    <Env_check.Component on_env_check />
//  </>
//};

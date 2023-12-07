open Ink;
open Common;

type env_check_result =
  result(
    (Env_check.Dependency.Node.t, Env_check.Dependency.Opam.t),
    (string, string),
  );

[@react.component]
let make = (~name as initial_name) => {
  let (env_check_result: option([ | `Pass | `Fail]), set_env_check_result) =
    React.useState(() => None);

  let (configuration, set_configuration) =
    React.useState(() => (None: option(Cma.Configuration.t)));

  let on_env_check = (result: env_check_result) => {
    switch (result) {
    | Ok(_) => set_env_check_result(_ => Some(`Pass))
    | Error(_) => set_env_check_result(_ => Some(`Fail))
    };
  };

  let on_complete_wizard = configuration => {
    set_configuration(_ => Some(configuration));
  };

  Ink.Hooks.use_input(
    (~input as _input, ~key as _key) => (),
    ~options={is_active: Some(true)},
  );

  <Box flexDirection=`column gap=1>
    <Banner />
    <Env_check.Component onEnvCheck=on_env_check />
    {switch (env_check_result) {
     | Some(_) => <Wizard name=initial_name onComplete=on_complete_wizard />
     | None => React.null
     }}
    {switch (configuration) {
     | Some(configuration) => <Scaffold configuration />
     | None => React.null
     }}
  </Box>;
};

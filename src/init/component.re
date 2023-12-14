open Ink;
open Common;

[@react.component]
let make = (~name as initial_name) => {
  let (is_active, set_is_active) = React.useState(() => Some(true));
  let (env_check_result: option([ | `Pass | `Fail]), set_env_check_result) =
    React.useState(() => None);
  let (should_prompt_git, set_should_prompt_git) =
    React.useState(() => false);

  let (configuration, set_configuration) =
    React.useState(() => (None: option(Core.Configuration.t)));

  let on_env_check = result => {
    switch (result) {
    | `Pass(results) =>
      set_env_check_result(_ => Some(`Pass));
      let should_prompt_git =
        List.exists(
          (result: Core.Dependency.check_result) => {
            module Dep = (val result.dependency);
            if (Dep.name == "Git") {
              switch (result.status) {
              | `Pass => true
              | `Failed(_) => false
              };
            } else {
              false;
            };
          },
          results,
        );

      set_should_prompt_git(_ => should_prompt_git);
      ();
    | `Fail(_) =>
      set_env_check_result(_ => Some(`Fail));
      set_is_active(_ => Some(false));
    };
  };

  let on_complete_wizard = configuration => {
    set_configuration(_ => Some(configuration));
  };

  let on_complete_scaffold = () => {
    set_is_active(_ => Some(false));
  };

  Ink.Hooks.use_input(
    (~input as _input, ~key as _key) => (),
    ~options={is_active: is_active},
  );

  <Box flexDirection=`column gap=1>
    <Banner />
    <Env_check.Component onEnvCheck=on_env_check />
    {switch (env_check_result) {
     | Some(result) when result == `Pass =>
       <Wizard
         name=initial_name
         onComplete=on_complete_wizard
         should_prompt_git
       />
     | _ => React.null
     }}
    {switch (configuration) {
     | Some(configuration) =>
       <Scaffold configuration onComplete=on_complete_scaffold />
     | None => React.null
     }}
  </Box>;
};

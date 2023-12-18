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

  let parsed_name_and_dir =
    Option.map(Core.Fs.parse_project_name_and_dir, initial_name);

  let initial_name_is_valid =
    parsed_name_and_dir
    |> Option.map(fst)
    |> Option.map(Core.Validation.Project_name.validate);

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

  let initial_configuration =
    Core.Configuration.make_partial(
      ~name=?Option.map(fst, parsed_name_and_dir),
      ~directory=?Option.map(snd, parsed_name_and_dir),
      (),
    );

  <Box flexDirection=`column gap=1>
    <Banner />
    {switch (initial_name_is_valid) {
     | Some(Error(`Msg(error))) =>
       <Ui.Badge color=`red> {React.string(error)} </Ui.Badge>
     | _ =>
       <>
         <Env_check.Component onEnvCheck=on_env_check />
         {switch (env_check_result) {
          | Some(result) when result == `Pass =>
            <Wizard
              initial_configuration
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
       </>
     }}
  </Box>;
};

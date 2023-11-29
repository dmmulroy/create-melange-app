open Ink;
open Common;

type env_check_result =
  result(
    (Env_check.Dependency.Node.t, Env_check.Dependency.Opam.t),
    (string, string),
  );

[@react.component]
let make = (~name as initial_name) => {
  let (_env_check_result: option([ | `Pass | `Fail]), set_env_check_result) =
    React.useState(() => None);

  let (configuration, set_configuration) =
    React.useState(() => (None: option(Wizard.configuration)));

  let on_env_check = (result: env_check_result) => {
    switch (result) {
    | Ok(_) => set_env_check_result(_ => Some(`Pass))
    | Error(_) => set_env_check_result(_ => Some(`Fail))
    };
  };

  let on_complete_wizard = configuration => {
    set_configuration(_ => Some(configuration));
  };

  <Box flexDirection=`column>
    <Banner />
    <Env_check.Component onEnvCheck=on_env_check />
    <Wizard name=initial_name onComplete=on_complete_wizard />
    {if (Option.is_some(configuration)) {
       <Box marginY=1>
         <Prefix>
           {React.string(
              "Configuration: \n"
              ++ Wizard.configuration_to_string(Option.get(configuration)),
            )}
         </Prefix>
       </Box>;
     } else {
       React.null;
     }}
  </Box>;
};

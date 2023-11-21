open Ink;
open Common;

type env_check_result =
  result(
    (Env_check.Dependency.Node.t, Env_check.Dependency.Opam.t),
    (string, string),
  );

[@react.component]
let make = (~dir as _dir: string) => {
  let (env_check_result: option([ | `Pass | `Fail]), set_env_check_result) =
    React.useState(() => None);

  let on_env_check = (result: env_check_result) => {
    switch (result) {
    | Ok(_) => set_env_check_result(_ => Some(`Pass))
    | Error(_) => set_env_check_result(_ => Some(`Fail))
    };
  };

  switch (env_check_result) {
  | Some(`Pass) =>
    <>
      <Gradient name=`Retro> <Banner /> </Gradient>
      <Env_check.Component />
      <Text> {React.string("success - starting initialization...")} </Text>
    </>
  | _ =>
    <>
      <Gradient name=`Retro> <Banner /> </Gradient>
      <Env_check.Component on_env_check />
    </>
  };
};

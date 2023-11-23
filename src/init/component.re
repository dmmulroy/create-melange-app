open Ink;
open Common;

module Wizard = {
  module Name = {
    [@react.component]
    let make = (~onSubmit) => {
      let (name, set_name) = React.useState(() => "");

      <Box flexDirection=`column gap=1>
        <Ui.Text_input
          placeholder="What will your project be called?"
          onChange={new_value => set_name(_ => new_value)}
          onSubmit
        />
        <Text> {React.string(name)} </Text>
      </Box>;
    };
  };

  module Bundler = {
    type t =
      | Vite
      | Webpack
      | None;

    let to_string =
      fun
      | Vite => "vite"
      | Webpack => "webpack"
      | None => "none";

    let of_string =
      fun
      | "vite" => Vite
      | "webpack" => Webpack
      | _ => None;

    let to_select_option = bundler =>
      Ui.Select.{
        value: to_string(bundler),
        label: to_string(bundler) |> String.capitalize_ascii,
      };

    let bundler_select_options: array(Ui.Select.select_option) = [|
      to_select_option(Vite),
      to_select_option(Webpack),
      to_select_option(None),
    |];

    [@react.component]
    let make = (~onChange) => {
      <Box flexDirection=`column gap=1>
        <Ui.Select options=bundler_select_options onChange />
      </Box>;
    };
  };

  [@react.component]
  let make = (~name: option(string)) => {
    let (name, set_name) = React.useState(() => name);
    let (bundler, set_bundler) = React.useState(() => None);

    let onSubmitName = (new_name: string) => {
      set_name(_ => Some(new_name));
    };

    let onSubmitBundler = new_bundler => {
      set_bundler(_ => Some(new_bundler));
    };

    <Box flexDirection=`column gap=1>
      {switch (name, bundler) {
       | (None, _) => <Name onSubmit=onSubmitName />
       | (Some(_name), None) =>
         <>
           <Name onSubmit=onSubmitName />
           <Bundler onChange=onSubmitBundler />
         </>
       | (Some(name), Some(bundler)) =>
         <Text>
           {React.string("Name: " ++ name ++ ", bundler: " ++ bundler)}
         </Text>
       }}
    </Box>;
  };
};

type env_check_result =
  result(
    (Env_check.Dependency.Node.t, Env_check.Dependency.Opam.t),
    (string, string),
  );

[@react.component]
let make = (~name) => {
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
      <Wizard name />
    </>
  | _ =>
    <>
      <Gradient name=`Retro> <Banner /> </Gradient>
      <Env_check.Component on_env_check />
    </>
  };
};

//<Box flexDirection=`column gap=1>
//  <Ui.Text_input
//    placeholder="Start typing..."
//    onChange={new_value => set_value(_ => new_value)}
//  />
//  <Text> {React.string("Value: " ++ value)} </Text>
//</Box>;

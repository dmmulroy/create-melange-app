open Ink;

type bundler =
  | Vite
  | Webpack
  | None;

let bundler_to_string =
  fun
  | Vite => "vite"
  | Webpack => "webpack"
  | None => "none";

let bundler_of_string =
  fun
  | "vite" => Vite
  | "webpack" => Webpack
  | _ => None;

type partial_configuration = {
  name: option(string),
  bundler: option(bundler),
};

type configuration = {
  name: string,
  bundler,
};

let configuration_to_string = config => {
  "name: " ++ config.name ++ " bundler: " ++ bundler_to_string(config.bundler);
};

module Step = {
  [@react.component]
  let make = (~visible, ~children) => {
    let display =
      if (visible == true) {
        `flex;
      } else {
        `none;
      };
    <Box display> children </Box>;
  };
};

module Name = {
  [@react.component]
  let make = (~onSubmit, ~disabled) => {
    <Box flexDirection=`column gap=1>
      <Spacer />
      <Box flexDirection=`row gap=1>
        <Text> {React.string("What will your project be called?")} </Text>
        <Ui.Text_input onSubmit isDisabled=disabled />
      </Box>
    </Box>;
  };
};

module Bundler = {
  type t = bundler;

  let to_select_option = bundler =>
    Ui.Select.{
      value: bundler_to_string(bundler),
      label: bundler_to_string(bundler) |> String.capitalize_ascii,
    };

  let bundler_select_options: array(Ui.Select.select_option) = [|
    to_select_option(Vite),
    to_select_option(Webpack),
    to_select_option(None),
  |];

  [@react.component]
  let make = (~onSubmit as onChange, ~disabled as _disabled) => {
    <Box flexDirection=`column gap=1>
      <Text> {React.string("Which bundler would you like to use?")} </Text>
      <Ui.Select options=bundler_select_options onChange />
    </Box>;
  };
};

type step =
  | Name
  | Bundler;

[@react.component]
let make = (~name as initial_name, ~onComplete) => {
  let (active_step, set_active_step) =
    React.useState(() =>
      if (Option.is_none(initial_name)) {
        Name;
      } else {
        Bundler;
      }
    );
  let (name, set_name) = React.useState(() => initial_name);
  let (_bundler, set_bundler) = React.useState(() => (None: option(string)));

  let onSubmitName = (new_name: string) => {
    set_name(_ => Some(new_name));
    set_active_step(_ => Bundler);
  };

  let onSubmitBundler =
    React.useCallback1(
      (new_bundler: string) => {
        set_bundler(_ => Some(new_bundler));

        switch (name, new_bundler) {
        | (Some(name), _) =>
          onComplete({name, bundler: bundler_of_string(new_bundler)})
        | _ => ()
        };
      },
      [|name|],
    );

  let show_name_step = Option.is_none(initial_name);
  let show_bundler_step = Option.is_some(name);

  <Box flexDirection=`column gap=1>
    <Step visible=show_name_step>
      <Name onSubmit=onSubmitName disabled={active_step != Name} />
    </Step>
    <Step visible=show_bundler_step>
      <Bundler onSubmit=onSubmitBundler disabled={active_step != Bundler} />
    </Step>
  </Box>;
};

open Ink;

module Step = {
  [@react.component]
  let make = (~visible, ~children) => {
    let display =
      if (visible == true) {
        `flex;
      } else {
        `none;
      };
    <> <Box display> children </Box> <Spacer /> </>;
  };
};

module Name = {
  let is_empty = name => String.length(name) == 0;
  let validate = name => {
    let re = [%re "/[a-z0-9_]/"];
    let _ = Js.Re.test_(re, name) == false;
    if (is_empty(name)) {
      Error("Name cannot be empty");
    } else if (Js.Re.test_(re, name) == false) {
      Error("Name must be lowercase and only contain letters, numbers, or _");
    } else {
      Ok(name);
    };
  };

  [@react.component]
  let make = (~onSubmit, ~isDisabled) => {
    let (value, set_value) = React.useState(() => "");
    let (error, set_error) = React.useState(() => None);

    let handleOnChange = name => {
      set_value(_ => name);
      set_error(_ => None);
    };

    let handleOnSubmit = name =>
      switch (validate(name)) {
      | Ok(name) => onSubmit(name)
      | Error(error) => set_error(_ => Some(error))
      };

    <Box flexDirection=`column>
      <Spacer />
      <Box flexDirection=`row>
        <Common.Prefix>
          {React.string("What will your project be called? ")}
        </Common.Prefix>
        <Ui.Text_input
          value
          isDisabled
          onChange=handleOnChange
          onSubmit=handleOnSubmit
        />
        {switch (error) {
         | Some(error) =>
           <Ui.Badge color=`red> {React.string(error)} </Ui.Badge>
         | None => React.null
         }}
      </Box>
    </Box>;
  };
};

module Bundler = {
  let to_select_option = bundler =>
    Ui.Select.{
      value: Core.Bundler.to_string(bundler),
      label: Core.Bundler.to_string(bundler) |> String.capitalize_ascii,
    };

  let bundler_select_options: array(Ui.Select.select_option) = [|
    to_select_option(Vite),
    to_select_option(Webpack),
    to_select_option(None),
  |];

  [@react.component]
  let make = (~onSubmit, ~isDisabled) => {
    let onChange = (bundler_str: string) => {
      onSubmit(Core.Bundler.of_string(bundler_str));
    };

    <Box flexDirection=`column>
      <Common.Prefix>
        {React.string("Which bundler would you like to use?")}
      </Common.Prefix>
      <Ui.Select options=bundler_select_options onChange isDisabled />
    </Box>;
  };
};

module Git = {
  let git_select_options: array(Ui.Select.select_option) = [|
    Ui.Select.{value: "yes", label: "Yes"},
    Ui.Select.{value: "no", label: "No"},
  |];

  [@react.component]
  let make = (~onSubmit, ~isDisabled) => {
    let onChange =
      React.useCallback1(
        (value: string) => {
          switch (value) {
          | "yes" => onSubmit(true)
          | _ => onSubmit(false)
          }
        },
        [|onSubmit|],
      );
    <Box flexDirection=`column>
      <Common.Prefix>
        {React.string(
           "Should we initialize a Git repository and stage the changes?",
         )}
      </Common.Prefix>
      <Ui.Select options=git_select_options onChange isDisabled />
    </Box>;
  };
};

module Npm = {
  let git_select_options: array(Ui.Select.select_option) = [|
    Ui.Select.{value: "yes", label: "Yes"},
    Ui.Select.{value: "no", label: "No"},
  |];

  [@react.component]
  let make = (~onSubmit, ~isDisabled) => {
    let onChange =
      React.useCallback1(
        (value: string) => {
          switch (value) {
          | "yes" => onSubmit(true)
          | _ => onSubmit(false)
          }
        },
        [|onSubmit|],
      );

    let pkg_manager = Nodejs.Process.npm_config_user_agent;

    <Box flexDirection=`column>
      <Common.Prefix>
        {React.string(
           "Should we run '"
           ++ Nodejs.Process.npm_user_agent_to_string(pkg_manager)
           ++ " install' for you?",
         )}
      </Common.Prefix>
      <Ui.Select options=git_select_options onChange isDisabled />
    </Box>;
  };
};

type step =
  | Name
  | Bundler
  | Git
  | Npm
  | Complete;

let step_to_string =
  fun
  | Name => "Name"
  | Bundler => "Bundler"
  | Git => "Git"
  | Npm => "Npm"
  | Complete => "Complete";

[@react.component]
let make = (~name as initial_name, ~onComplete, ~should_prompt_git) => {
  let (active_step, set_active_step) =
    React.useState(() =>
      if (Option.is_none(initial_name)) {
        Name;
      } else {
        Bundler;
      }
    );
  let (name, set_name) = React.useState(() => initial_name);
  let (bundler, set_bundler) =
    React.useState(() => (None: option(Core.Bundler.t)));
  let (initialize_git, set_initialize_git) =
    React.useState(() => (None: option(bool)));
  let (_initialize_npm, set_initialize_npm) =
    React.useState(() => (None: option(bool)));

  let onSubmitName = (new_name: string) =>
    if (active_step == Name) {
      set_name(_ => Some(new_name));
      set_active_step(_ => Bundler);
    };

  let onSubmitBundler =
    React.useCallback1(
      (new_bundler: Core.Bundler.t) =>
        if (active_step == Bundler) {
          set_bundler(_ => Some(new_bundler));

          let next_step = if (should_prompt_git) {Git} else {Npm};

          set_active_step(_ => next_step);
        },
      [|active_step|],
    );

  let onSubmitGit =
    React.useCallback1(
      value =>
        if (active_step == Git) {
          set_initialize_git(_ => Some(value));
          set_active_step(_ => Npm);
        },
      [|active_step|],
    );

  let onSubmitNpm =
    React.useCallback3(
      value => {
        set_initialize_npm(_ => Some(value));
        switch (name, bundler) {
        | (Some(name), Some(bundler)) =>
          set_active_step(_ => Complete);
          onComplete(
            Core.Configuration.make(
              ~name,
              ~bundler,
              ~initialize_git={
                Option.value(~default=false, initialize_git);
              },
              ~initialize_npm=value,
              ~overwrite=None,
            ),
          );
        | _ => ()
        };
      },
      (name, bundler, initialize_git),
    );

  let show_name_step = Option.is_none(initial_name);
  let show_bundler_step = Option.is_some(name);
  let show_git_step = Option.is_some(bundler) && should_prompt_git;
  let show_npm_step =
    Option.is_some(initialize_git)
    || Option.is_some(bundler)
    && !should_prompt_git;

  <Box flexDirection=`column gap=1>
    <Step visible=show_name_step>
      <Name onSubmit=onSubmitName isDisabled={active_step != Name} />
    </Step>
    <Step visible=show_bundler_step>
      <Bundler onSubmit=onSubmitBundler isDisabled={active_step != Bundler} />
    </Step>
    <Step visible=show_git_step>
      <Git onSubmit=onSubmitGit isDisabled={active_step != Git} />
    </Step>
    <Step visible=show_npm_step>
      <Npm onSubmit=onSubmitNpm isDisabled={active_step != Npm} />
    </Step>
  </Box>;
};

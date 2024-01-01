[@ocaml.warning "-26-27"];
open Bindings;
open Ink;
open Ui;
open Core;

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
  [@react.component]
  let make = (~onSubmit, ~isDisabled) => {
    let (value, set_value) = React.useState(() => "");
    let (error, set_error) = React.useState(() => None);

    let handleOnChange = new_value =>
      if (String.equal(value, new_value)) {
        ();
      } else {
        set_value(_ => new_value);
        set_error(_ => None);
      };

    let handleOnSubmit = name => {
      let (name, directory) = Core.Fs.parse_project_name_and_dir(name);
      switch (Core.Validation.Project_name.validate(name)) {
      | Ok(name) => onSubmit((name, directory))
      | Error(`Msg(error)) => set_error(_ => Some(error))
      };
    };

    <Box flexDirection=`column gap=1>
      <Spacer />
      <Box flexDirection=`row>
        <Text> {React.string("What will your project be called? ")} </Text>
        <Ui.Text_input
          value
          isDisabled
          onChange=handleOnChange
          onSubmit=handleOnSubmit
        />
      </Box>
      {switch (error) {
       | Some(error) =>
         <Box>
           <Ui.Badge color=`red> {React.string("Invalid:")} </Ui.Badge>
           <Text> {React.string(" " ++ error)} </Text>
         </Box>
       | None => React.null
       }}
    </Box>;
  };
};

module Syntax = {
  let options: array(Ui.Select.select_option) = [|
    Ui.Select.{
      value: "reasonml",
      label: "ReasonML (recommended if you're new to OCaml/ReasonML)",
    },
    Ui.Select.{value: "ocaml", label: "OCaml"},
  |];

  [@react.component]
  let make = (~onSubmit, ~isDisabled) => {
    let onChange =
      React.useCallback1(
        (value: string) => {
          onSubmit(Core.Configuration.syntax_preference_of_string(value))
        },
        [|onSubmit|],
      );
    <Box flexDirection=`column>
      <Text> {React.string("Which syntax do your prefer?")} </Text>
      <Ui.Select options onChange isDisabled />
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
      <Text> {React.string("Which bundler would you like to use?")} </Text>
      <Ui.Select options=bundler_select_options onChange isDisabled />
    </Box>;
  };
};

module React_app = {
  let options: array(Ui.Select.select_option) = [|
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
      <Text> {React.string("Will this be a React app?")} </Text>
      <Ui.Select options onChange isDisabled />
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
      <Text>
        {React.string(
           "Should we initialize a Git repository and stage the changes?",
         )}
      </Text>
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
      <Text>
        {React.string(
           "Should we run '"
           ++ Nodejs.Process.npm_user_agent_to_string(pkg_manager)
           ++ " install' for you?",
         )}
      </Text>
      <Ui.Select options=git_select_options onChange isDisabled />
    </Box>;
  };
};

module OCaml_toolchain = {
  let options: array(Ui.Select.select_option) = [|
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
      <Text>
        {React.string("Should we initialize the OCaml toolchain for you?")}
      </Text>
      <Ui.Select options onChange isDisabled />
    </Box>;
  };
};

module Overwrite_preference = {
  open Ui;

  let options: array(Select.select_option) = [|
    {value: "abort", label: "Abort installation"},
    {value: "clear", label: "Clear the directory and continue installation"},
    {
      value: "overwrite",
      label: "Continue installation and overwrite conflicting files",
    },
  |];

  let overwrite_preference_of_string = str =>
    switch (str) {
    | "abort" => `Abort
    | "clear" => `Clear
    | "overwrite" => `Overwrite
    | _ => `Abort
    };

  [@react.component]
  let make = (~name, ~onSubmit as onChange, ~isDisabled) => {
    <Box flexDirection=`column gap=1>
      <Box flexDirection=`row gap=1>
        <Badge color=`yellow> {React.string("Warning")} </Badge>
        <Text>
          {React.string(
             name
             ++ " already exists and isn't empty. How would you like to proceed?",
           )}
        </Text>
      </Box>
      <Select options onChange isDisabled />
    </Box>;
  };
};

type step =
  | Name
  | Syntax_preference
  | React_app
  | Bundler
  | Git
  | Npm
  | OCaml_toolchain
  | Overwrite_preference
  | Complete;

let step_to_string =
  fun
  | Name => "Name"
  | Syntax_preference => "Syntax_preference"
  | React_app => "React_app"
  | Bundler => "Bundler"
  | Git => "Git"
  | Npm => "Npm"
  | OCaml_toolchain => "OCaml_toolchain"
  | Overwrite_preference => "Overwrite_preference"
  | Complete => "Complete";

[@react.component]
let make =
    (
      ~initial_configuration: Configuration.partial,
      ~onComplete,
      ~should_prompt_git,
    ) => {
  let (active_step, set_active_step) =
    React.useState(() =>
      if (Option.is_none(initial_configuration.name)) {
        Name;
      } else {
        Syntax_preference;
      }
    );
  let (name, set_name) = React.useState(() => initial_configuration.name);
  let (directory, set_directory) =
    React.useState(() => initial_configuration.directory);
  let (syntax_preference, set_syntax_preference) =
    React.useState(() => (None: option(Configuration.syntax_preference)));
  let (is_react_app, set_is_react_app) =
    React.useState(() => (None: option(bool)));
  let (bundler, set_bundler) =
    React.useState(() => (None: option(Core.Bundler.t)));
  let (initialize_git, set_initialize_git) =
    React.useState(() => (None: option(bool)));
  let (initialize_npm, set_initialize_npm) =
    React.useState(() => (None: option(bool)));
  let (initialize_ocaml_toolchain, set_initialize_ocaml_toolchain) =
    React.useState(() => (None: option(bool)));
  let (overwrite_preference, set_overwrite_preference) =
    React.useState(() => (None: option([ | `Clear | `Overwrite])));
  let (error, set_error) = React.useState(() => None);

  let onSubmitName =
    React.useCallback1(
      ((name, directory)) =>
        if (active_step == Name) {
          set_name(_ => Some(name));
          set_directory(_ => Some(directory));
          set_active_step(_ => Syntax_preference);
        },
      [|active_step|],
    );

  let onSubmitSyntaxPreference =
    React.useCallback1(
      (syntax_preference: Configuration.syntax_preference) =>
        if (active_step == Syntax_preference) {
          set_syntax_preference(_ => Some(syntax_preference));
          set_active_step(_ => React_app);
        },
      [|active_step|],
    );

  let onSubmitReact =
    React.useCallback1(
      (is_react_app: bool) =>
        if (active_step == React_app) {
          set_is_react_app(_ => Some(is_react_app));

          set_active_step(_ => Bundler);
        },
      [|active_step|],
    );

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
    React.useCallback1(
      value =>
        if (active_step == Npm) {
          set_initialize_npm(_ => Some(value));
          set_active_step(_ => OCaml_toolchain);
        },
      [|active_step|],
    );

  let onSubmitOcamlToolchain =
    React.useCallback1(
      value => {
        set_initialize_ocaml_toolchain(_ => Some(value));
        Option.get(directory)
        |> Engine.V2.directory_exists
        |> Promise_result.perform(result =>
             switch (result) {
             | Ok(true) => set_active_step(_ => Overwrite_preference)
             | Ok(false) => set_active_step(_ => Complete)
             | Error(error) => set_error(_ => Some(error))
             }
           );
      },
      [|directory|],
    );

  let onSubmitOverwrite_preference =
    React.useCallback0(value => {
      let preference =
        Overwrite_preference.overwrite_preference_of_string(value);
      switch (preference) {
      | `Abort => Node.Process.exit(0)
      | `Clear as preference
      | `Overwrite as preference =>
        set_overwrite_preference(_ => Some(preference));
        set_active_step(_ => Complete);
      };
    });

  React.useEffect1(
    () => {
      if (active_step == Complete) {
        onComplete(
          Core.Configuration.make(
            ~name={
              Option.get(name);
            },
            ~directory={
              Option.get(directory);
            },
            ~syntax_preference={
              Option.get(syntax_preference);
            },
            ~bundler={
              Option.get(bundler);
            },
            ~is_react_app={
              Option.value(~default=false, is_react_app);
            },
            ~initialize_git={
              Option.value(~default=false, initialize_git);
            },
            ~initialize_npm={
              Option.value(~default=false, initialize_npm);
            },
            ~initialize_ocaml_toolchain={
              Option.value(~default=false, initialize_ocaml_toolchain);
            },
            ~overwrite={
              overwrite_preference;
            },
          ),
        );
      };

      None;
    },
    [|active_step|],
  );

  let show_name_step = Option.is_none(initial_configuration.name);
  let show_syntax_preference_step = Option.is_some(name);
  let show_react_step = Option.is_some(syntax_preference);
  let show_bundler_step = Option.is_some(is_react_app);
  let show_git_step = Option.is_some(bundler) && should_prompt_git;
  let show_npm_step =
    Option.is_some(initialize_git)
    || Option.is_some(bundler)
    && !should_prompt_git;
  let show_ocaml_toolchain_step = Option.is_some(initialize_npm);
  let show_overwrite_step =
    Option.is_some(initialize_ocaml_toolchain)
    && (
      active_step == Overwrite_preference
      || active_step == Complete
      && Option.is_some(overwrite_preference)
    );

  <Box flexDirection=`column gap=1>
    <Step visible=show_name_step>
      <Name onSubmit=onSubmitName isDisabled={active_step != Name} />
    </Step>
    <Step visible=show_syntax_preference_step>
      <Syntax
        onSubmit=onSubmitSyntaxPreference
        isDisabled={active_step != Syntax_preference}
      />
    </Step>
    <Step visible=show_react_step>
      <React_app
        onSubmit=onSubmitReact
        isDisabled={active_step != React_app}
      />
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
    <Step visible=show_ocaml_toolchain_step>
      <OCaml_toolchain
        onSubmit=onSubmitOcamlToolchain
        isDisabled={active_step != OCaml_toolchain}
      />
    </Step>
    {Option.is_some(name)
       ? <Step visible=show_overwrite_step>
           <Overwrite_preference
             name={Option.get(name)}
             onSubmit=onSubmitOverwrite_preference
             isDisabled={active_step != Overwrite_preference}
           />
         </Step>
       : React.null}
    {switch (error) {
     | Some(error) =>
       <Box display=`flex>
         <Box flexDirection=`row gap=1>
           <Badge color=`red> {React.string("Error")} </Badge>
           <Text> {React.string(error)} </Text>
         </Box>
         <Spacer />
       </Box>
     | None => React.null
     }}
  </Box>;
};

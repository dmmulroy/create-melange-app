[@ocaml.warning "-26-27"];
open Bindings;
open Ink;
open Ui;
open Core;

/* Prevents flickering in Ink by deferring onSubmit to useEffect instead of calling it directly in onChange */
module StableSelect = {
  [@react.component]
  let make =
      (~options: array(Ui.Select.select_option), ~isDisabled, ~onSubmit) => {
    let (state, set_state) = React.useState(() => None);

    React.useEffect1(
      () => {
        switch (state) {
        | Some(v) => onSubmit(v)
        | None => ()
        };

        None;
      },
      [|state|],
    );
    <Ui.Select options onChange={v => set_state(_ => Some(v))} isDisabled />;
  };
};

module Step = {
  [@react.component]
  let make = (~visible, ~children) => {
    visible
      ? <Box flexDirection=`column> <Spacer /> children <Spacer /> </Box>
      : React.null;
  };
};

module Name = {
  [@react.component]
  let make = (~onSubmit, ~isDisabled) => {
    let (value, set_value) = React.useState(() => "");
    let (error, set_error) = React.useState(() => None);

    let handleOnChange =
      React.useCallback1(
        new_value =>
          if (String.equal(value, new_value)) {
            ();
          } else {
            set_value(_ => new_value);
            set_error(_ => None);
          },
        [|value|],
      );

    let handleOnSubmit =
      React.useCallback(name => {
        switch (Core.Fs.parse_project_name_and_dir(name)) {
        | Ok((parsed_name, directory)) =>
          switch (Core.Validation.Project_name.validate(parsed_name)) {
          | Ok(validated_name) => onSubmit((validated_name, directory))
          | Error(`Msg(error)) => set_error(_ => Some(error))
          }
        | Error(`Msg(error)) => set_error(_ => Some(error))
        }
      });

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

module YesNoSelector = {
  let options: array(Ui.Select.select_option) = [|
    Ui.Select.{
      value: "yes",
      label: "Yes",
    },
    Ui.Select.{
      value: "no",
      label: "No",
    },
  |];

  [@react.component]
  let make = (~label, ~isDisabled, ~onSubmit) => {
    <Box flexDirection=`column>
      <Text> {React.string(label)} </Text>
      <StableSelect
        options
        isDisabled
        onSubmit={value =>
          onSubmit(
            switch (value) {
            | "yes" => true
            | "no" => false
            | _ => failwith("Invalid value")
            },
          )
        }
      />
    </Box>;
  };
};

module Syntax = {
  let options: array(Ui.Select.select_option) = [|
    Ui.Select.{
      value: "reasonml",
      label: "ReasonML (recommended if you're new to OCaml/ReasonML)",
    },
    Ui.Select.{
      value: "ocaml",
      label: "OCaml",
    },
  |];

  [@react.component]
  let make = (~onSubmit, ~isDisabled) => {
    <Box flexDirection=`column>
      <Text> {React.string("Which syntax do your prefer?")} </Text>
      <StableSelect
        options
        onSubmit={(value: string) => {
          onSubmit(Core.Configuration.syntax_preference_of_string(value))
        }}
        isDisabled
      />
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
    to_select_option(Esbuild),
  |];

  [@react.component]
  let make = (~onSubmit, ~isDisabled) => {
    <Box flexDirection=`column>
      <Text> {React.string("Which bundler would you like to use?")} </Text>
      <StableSelect
        options=bundler_select_options
        onSubmit={value => {onSubmit(Core.Bundler.of_string(value))}}
        isDisabled
      />
    </Box>;
  };
};

module React_app = {
  let make = YesNoSelector.make;
  let makeProps = YesNoSelector.makeProps(~label="Will this be a React app?");
};

module Git = {
  let make = YesNoSelector.make;
  let makeProps =
    YesNoSelector.makeProps(
      ~label="Should we initialize a Git repository and stage the changes?",
    );
};

module Npm = {
  let pkg_manager = Nodejs.Process.npm_config_user_agent;
  let make = YesNoSelector.make;
  let makeProps =
    YesNoSelector.makeProps(
      ~label=
        "Should we run '"
        ++ Nodejs.Process.npm_user_agent_to_string(pkg_manager)
        ++ " install' for you?",
    );
};

module OCaml_toolchain = {
  let make = YesNoSelector.make;
  let makeProps =
    YesNoSelector.makeProps(
      ~label="Should we initialize the OCaml toolchain for you?",
    );
};

module Tests = {
  let make = YesNoSelector.make;
  let makeProps =
    YesNoSelector.makeProps(
      ~label="Do you want to add tests with melange-fest?",
    );
};

module Overwrite_preference = {
  let options: array(Select.select_option) = [|
    {
      value: "abort",
      label: "Abort installation",
    },
    {
      value: "clear",
      label: "Clear the directory and continue installation",
    },
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
  | Tests
  | Bundler
  | Git
  | Npm
  | OCaml_toolchain
  | Overwrite_preference
  | Complete;

let step_to_int = step =>
  switch (step) {
  | Name => 0
  | Syntax_preference => 1
  | React_app => 2
  | Tests => 3
  | Bundler => 4
  | Git => 5
  | Npm => 6
  | OCaml_toolchain => 7
  | Overwrite_preference => 8
  | Complete => 9
  };

[@react.component]
let make =
    (
      ~initial_configuration: Configuration.partial,
      ~onComplete: Configuration.t => unit,
      ~should_prompt_git,
    ) => {
  let (configuration, setConfiguration) =
    React.useState(() => initial_configuration);

  let (active_step, set_active_step) =
    React.useState(() =>
      switch (initial_configuration.name) {
      | Some(_) => Syntax_preference
      | None => Name
      }
    );

  let (overwrite_preference, set_overwrite_preference) =
    React.useState(_ => None);

  let (error, set_error) = React.useState(() => None);

  let onSubmitName = ((name, directory)) => {
    setConfiguration(_ =>
      {
        ...configuration,
        name: Some(name),
        directory: Some(directory),
      }
    );
    set_active_step(_ => Syntax_preference);
  };

  let onSubmitSyntaxPreference =
      (syntax_preference: Configuration.syntax_preference) => {
    setConfiguration(_ =>
      {
        ...configuration,
        syntax_preference: Some(syntax_preference),
      }
    );
    set_active_step(_ => React_app);
  };

  let onSubmitReact = (is_react_app: bool) => {
    setConfiguration(_ =>
      {
        ...configuration,
        is_react_app: Some(is_react_app),
      }
    );
    set_active_step(_ => Tests);
  };

  let onSubnitHasTests = (should_add_tests: bool) => {
    setConfiguration(_ =>
      {
        ...configuration,
        has_tests: Some(should_add_tests),
      }
    );
    set_active_step(_ => Bundler);
  };

  let onSubmitBundler = (new_bundler: Core.Bundler.t) => {
    setConfiguration(_ =>
      {
        ...configuration,
        bundler: Some(new_bundler),
      }
    );
    set_active_step(_ => should_prompt_git ? Git : Npm);
  };

  let onSubmitGit = value => {
    setConfiguration(_ =>
      {
        ...configuration,
        initialize_git: Some(value),
      }
    );
    set_active_step(_ => Npm);
  };

  let onSubmitNpm = value =>
    if (active_step == Npm) {
      setConfiguration(_ =>
        {
          ...configuration,
          initialize_npm: Some(value),
        }
      );
      set_active_step(_ => OCaml_toolchain);
    };

  let onSubmitOcamlToolchain = value => {
    setConfiguration(_ =>
      {
        ...configuration,
        initialize_ocaml_toolchain: Some(value),
      }
    );

    Option.get(configuration.directory)
    |> Engine.directory_exists
    |> Promise_result.perform(result =>
         switch (result) {
         | Ok(true) => set_active_step(_ => Overwrite_preference)
         | Ok(false) => set_active_step(_ => Complete)
         | Error(error) => set_error(_ => Some(error))
         }
       );
  };

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
        Core.Configuration.make(
          ~name={
            Option.get(configuration.name);
          },
          ~directory={
            Option.get(configuration.directory);
          },
          ~syntax_preference={
            Option.get(configuration.syntax_preference);
          },
          ~bundler={
            Option.get(configuration.bundler);
          },
          ~is_react_app={
            Option.get(configuration.is_react_app);
          },
          ~has_tests=Option.get(configuration.has_tests),
          ~initialize_git={
            Option.get(configuration.initialize_git);
          },
          ~initialize_npm={
            Option.get(configuration.initialize_npm);
          },
          ~initialize_ocaml_toolchain={
            Option.get(configuration.initialize_ocaml_toolchain);
          },
          ~overwrite={
            overwrite_preference;
          },
        )
        ->onComplete;
      };

      None;
    },
    [|active_step|],
  );

  let show_step = step => step_to_int(step) <= step_to_int(active_step);

  <Box overflow=`hidden flexDirection=`column gap=2>
    <Step visible={show_step(Name)}>
      <Name onSubmit=onSubmitName isDisabled={active_step != Name} />
    </Step>
    <Step visible={show_step(Syntax_preference)}>
      <Syntax
        onSubmit=onSubmitSyntaxPreference
        isDisabled={active_step != Syntax_preference}
      />
    </Step>
    <Step visible={show_step(React_app)}>
      <React_app
        onSubmit=onSubmitReact
        isDisabled={active_step != React_app}
      />
    </Step>
    <Step visible={show_step(Tests)}>
      <Tests onSubmit=onSubnitHasTests isDisabled={active_step != Tests} />
    </Step>
    <Step visible={show_step(Bundler)}>
      <Bundler onSubmit=onSubmitBundler isDisabled={active_step != Bundler} />
    </Step>
    <Step visible={show_step(Git)}>
      <Git onSubmit=onSubmitGit isDisabled={active_step != Git} />
    </Step>
    <Step visible={show_step(Npm)}>
      <Npm onSubmit=onSubmitNpm isDisabled={active_step != Npm} />
    </Step>
    <Step visible={show_step(OCaml_toolchain)}>
      <OCaml_toolchain
        onSubmit=onSubmitOcamlToolchain
        isDisabled={active_step != OCaml_toolchain}
      />
    </Step>
    <Step visible={show_step(Overwrite_preference)}>
      {switch (configuration.name) {
       | Some(name) =>
         <Overwrite_preference
           name
           onSubmit=onSubmitOverwrite_preference
           isDisabled={active_step != Overwrite_preference}
         />
       | None => React.null
       }}
    </Step>
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

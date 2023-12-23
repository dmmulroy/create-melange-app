open Bindings;
open Ink;
open Ui;

open Core;

module Overwrite_input = {
  let options: array(Select.select_option) = [|
    {value: "abort", label: "Abort installation"},
    {value: "clear", label: "Clear the directory and continue installation"},
    {
      value: "overwrite",
      label: "Continue installation and overwrite conflicting files",
    },
  |];

  let overwrite_of_string = str =>
    switch (str) {
    | "abort" => `Abort
    | "clear" => `Clear
    | "overwrite" => `Overwrite
    | _ => `Abort
    };

  [@react.component]
  let make =
      (~configuration: Configuration.t, ~onSubmit as onChange, ~isDisabled) => {
    <Box flexDirection=`column gap=1>
      // TODO: colorize this warning

        <Common.Prefix>
          {React.string(
             "Warning: "
             ++ configuration.name
             ++ " already exists and isn't empty. How would you like to proceed?",
           )}
        </Common.Prefix>
        <Select options onChange isDisabled />
      </Box>;
  };
};

module Compile_templates = {
  open Ui;
  [@react.component]
  let make = (~configuration: Configuration.t, ~onComplete) => {
    let (compilation_result, set_compilation_result) =
      React.useState(() => None);

    React.useEffect0(() => {
      Engine.run(configuration)
      |> Js.Promise.then_(result => {
           set_compilation_result(curr =>
             if (Option.is_none(curr)) {
               Some(result);
             } else {
               curr;
             }
           )
           |> Js.Promise.resolve
         })
      |> Js.Promise.catch(_ => {
           Js.log("Something went wrong");
           set_compilation_result(_ => Some(Error("Something went wrong")));
           Js.Promise.resolve();
         })
      |> ignore;

      None;
    });

    React.useEffect1(
      () => {
        switch (compilation_result) {
        | Some(_) => onComplete()
        | _ => ()
        };
        None;
      },
      [|compilation_result|],
    );

    <Box>
      {switch (compilation_result) {
       | None => <Spinner label="Compiling templates" />
       | Some(result) =>
         switch (result) {
         | Ok(_) =>
           <Text> {React.string("Compiling templates complete")} </Text>
         | Error(err) => <Text> {React.string(err)} </Text>
         }
       }}
    </Box>;
  };
};

module Copy_template = {
  open Ui;
  [@react.component]
  let make = (~configuration: Configuration.t, ~onComplete) => {
    let (copy_complete, set_copy_complete) = React.useState(() => false);
    let (error, set_error) = React.useState(() => None);

    React.useEffect0(() => {
      let result =
        Fs.create_dir(
          ~overwrite=?configuration.overwrite,
          configuration.directory,
        );

      switch (result) {
      | Ok(_) => set_copy_complete(_ => true)
      | Error(err) =>
        set_error(_ => Some(err));
        ();
      };

      None;
    });

    <Box flexDirection=`column gap=1>
      {switch (error) {
       | Some(err) => <Text> {React.string(err)} </Text>
       | None =>
         copy_complete
           ? <Compile_templates configuration onComplete />
           : <Spinner label="Copying template files" />
       }}
    </Box>;
  };
};

[@react.component]
let make =
    (~configuration as initial_configuration: Configuration.t, ~onComplete) => {
  let (configuration, set_configuration) =
    React.useState(() => initial_configuration);
  let (project_dir_exists, _set_project_dir_exists) =
    React.useState(() =>
      Fs.existsSync(configuration.directory)
      && !Fs.dir_is_empty(configuration.directory)
    );

  let onSubmit =
    React.useCallback0((value: string) => {
      let overwrite = Overwrite_input.overwrite_of_string(value);

      if (overwrite == `Abort) {
        exit(1);
      };

      let overwrite =
        switch (overwrite) {
        | `Clear => Some(`Clear)
        | `Overwrite => Some(`Overwrite)
        | _ => assert(false)
        };

      set_configuration(prev_config => {...prev_config, overwrite});
    });

  // TODO: Clean this up, move Compile out of Copy_template
  <Box flexDirection=`column gap=1>
    {switch (project_dir_exists, configuration.overwrite) {
     | (true, None) =>
       <Overwrite_input configuration onSubmit isDisabled=false />
     | (true, Some(`Overwrite))
     | (true, Some(`Clear)) =>
       <>
         <Overwrite_input configuration onSubmit isDisabled=true />
         <Copy_template configuration onComplete />
       </>
     | _ => <Copy_template configuration onComplete />
     }}
  </Box>;
};

module V2 = {
  type step =
    | Create_dir
    | Bundler
    | Node_pkg_manager
    | Git
    | Opam_create_switch
    | Opam_install_deps
    | Opam_install_dev_deps
    | Dune_build
    | Finished;

  let step_to_string = step =>
    switch (step) {
    | Create_dir => "Create_dir"
    | Bundler => "Bundler"
    | Node_pkg_manager => "Node_pkg_manager"
    | Git => "Git"
    | Opam_create_switch => "Opam_create_switch"
    | Opam_install_deps => "Opam_install_deps"
    | Opam_install_dev_deps => "Opam_install_dev_deps"
    | Dune_build => "Dune_build"
    | Finished => "Finished"
    };

  let step_to_int = step =>
    switch (step) {
    | Create_dir => 0
    | Bundler => 1
    | Node_pkg_manager => 2
    | Git => 3
    | Opam_create_switch => 4
    | Opam_install_deps => 5
    | Opam_install_dev_deps => 6
    | Dune_build => 7
    | Finished => 8
    };

  type model = {
    configuration: Configuration.t,
    context: Context.t,
    step,
    error: option(string),
  };

  type event =
    | Complete_create_dir
    | Complete_bundler
    | Complete_node_pkg_manager
    | Complete_git
    | Complete_opam_create_switch
    | Complete_opam_install_deps
    | Complete_opam_install_dev_deps
    | Complete_dune_build
    | Set_overwrite_configuration(Configuration.overwrite_preference);

  let event_to_string = event =>
    switch (event) {
    | Complete_create_dir => "Complete_create_dir"
    | Complete_bundler => "Complete_bundler"
    | Complete_node_pkg_manager => "Complete_node_pkg_manager"
    | Complete_git => "Complete_git"
    | Complete_opam_create_switch => "Complete_opam_create_switch"
    | Complete_opam_install_deps => "Complete_opam_install_deps"
    | Complete_opam_install_dev_deps => "Complete_opam_install_dev_deps"
    | Complete_dune_build => "Complete_dune_build"
    | Set_overwrite_configuration(overwrite) =>
      Printf.sprintf(
        "Set_overwrite_configuration(%s)",
        Configuration.overwrite_preference_to_string(overwrite),
      )
    };

  let update = (model, event) =>
    switch (model.step, event) {
    | (Create_dir, Complete_create_dir) => {...model, step: Bundler}
    | (Bundler, Complete_bundler) => {...model, step: Node_pkg_manager}
    | (Node_pkg_manager, Complete_node_pkg_manager) => {...model, step: Git}
    | (Git, Complete_git) => {...model, step: Opam_create_switch}
    | (Opam_create_switch, Complete_opam_create_switch) => {
        ...model,
        step: Opam_install_deps,
      }
    | (Opam_install_deps, Complete_opam_install_deps) => {
        ...model,
        step: Opam_install_dev_deps,
      }
    | (Opam_install_dev_deps, Complete_opam_install_dev_deps) => {
        ...model,
        step: Dune_build,
      }
    | (Dune_build, Complete_dune_build) => {...model, step: Finished}
    | (_, Set_overwrite_configuration(overwrite)) => {
        ...model,
        configuration: {
          ...model.configuration,
          overwrite: Some(overwrite),
        },
      }
    | _ => {
        ...model,
        error:
          Some(
            Printf.sprintf(
              "Invalid event: %s at step: %s\n",
              event_to_string(event),
              step_to_string(model.step),
            ),
          ),
      }
    };

  module Create_dir = {
    module Overwrite_input = {
      open Ui;

      let options: array(Select.select_option) = [|
        {value: "abort", label: "Abort installation"},
        {
          value: "clear",
          label: "Clear the directory and continue installation",
        },
        {
          value: "overwrite",
          label: "Continue installation and overwrite conflicting files",
        },
      |];

      let overwrite_of_string = str =>
        switch (str) {
        | "abort" => `Abort
        | "clear" => `Clear
        | "overwrite" => `Overwrite
        | _ => `Abort
        };

      [@react.component]
      let make = (~context: Context.t, ~onSubmit as onChange, ~isDisabled) => {
        <Box flexDirection=`column gap=1>
          <Box flexDirection=`row>
            <Badge color=`yellow> {React.string("Warning: ")} </Badge>
            <Text>
              {React.string(
                 context.configuration.name
                 ++ " already exists and isn't empty. How would you like to proceed?",
               )}
            </Text>
          </Box>
          <Select options onChange isDisabled />
        </Box>;
      };
    };

    module Create = {
      open Ui;
      [@react.component]
      let make = (~context: Context.t, ~onComplete as _) => {
        let (copy_complete, _set_copy_complete) = React.useState(() => false);
        let (error, _set_error) = React.useState(() => None);

        React.useEffect0(() => {
          context.configuration.directory
          |> Engine.V2.create_project_directory(
               ~overwrite=?context.configuration.overwrite,
             )
          |> ignore;

          None;
        });

        <Box flexDirection=`column gap=1>
          {switch (error) {
           | Some(err) => <Text> {React.string(err)} </Text>
           | None =>
             copy_complete
               ? <Text>
                   {React.string("Copying template files complete")}
                 </Text>
               : <Spinner label="Copying template files" />
           }}
        </Box>;
      };
    };

    [@react.component]
    let make = (~context: Context.t) => {
      let (project_dir_exists, set_project_dir_exists) =
        React.useState(() => None);
      let (error, set_error) = React.useState(() => None);

      React.useEffect0(() => {
        context.configuration.directory
        |> Engine.V2.directory_exists
        |> Promise_result.tap(result =>
             switch (result) {
             | Ok(value) => set_project_dir_exists(_ => Some(value))
             | Error(err) => set_error(_ => Some(err))
             }
           )
        |> ignore;
        None;
      });

      React.useEffect1(
        () => {
          switch (error) {
          | Some(_err) => () // TODO: onError(err)
          | None => ()
          };
          None;
        },
        [|error|],
      );

      switch (project_dir_exists, context.configuration.overwrite) {
      | (None, _) => <Spinner label="Checking if project directory exists" />
      | (Some(true), None) =>
        <Overwrite_input context onSubmit={_ => ()} isDisabled=false />
      | (Some(true), Some(_overwrite)) =>
        <>
          <Overwrite_input context onSubmit={_ => ()} isDisabled=true />
          <Create context onComplete={_ => ()} />
        </>
      | (Some(false), _) => <Spinner label="Creating project directory" />
      };
    };
  };

  module Bundler = {};
  module Node_pkg_manager = {};
  module Git = {};
  module Opam = {
    module Create_switch = {};
    module Install_deps = {};
    module Install_dev_deps = {};
  };
  module Dune_build = {};
  module Scaffold = {
    [@react.component]
    let make =
        (
          ~configuration as initial_configuration: Configuration.t,
          ~onComplete as _onComplete,
        ) => {
      let (_model, _dispatch) =
        React.useReducer(
          update,
          {
            configuration: initial_configuration,
            context: Context.make(~configuration=initial_configuration, ()),
            step: Create_dir,
            error: None,
          },
        );
      <> </>;
    };
  };
};

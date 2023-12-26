open Bindings;
open Ink;
open Ui;

open Core;

module V2 = {
  type step =
    | Create_dir
    | Copy_base_templates
    | Bundler_copy_files
    | Bundler_extend_package_json
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
    | Copy_base_templates => "Copy_base_templates"
    | Bundler_copy_files => "Bundler_copy_files"
    | Bundler_extend_package_json => "Bundler_extend_package_json"
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
    | Copy_base_templates => 1
    | Bundler_copy_files => 2
    | Bundler_extend_package_json => 3
    | Node_pkg_manager => 5
    | Git => 6
    | Opam_create_switch => 7
    | Opam_install_deps => 8
    | Opam_install_dev_deps => 9
    | Dune_build => 10
    | Finished => 11
    };

  type model = {
    context: Context.t,
    step,
    error: option(string),
  };

  type event =
    | Complete_create_dir
    | Complete_copy_base_project
    | Complete_bundler_copy_files
    | Complete_bundler_extend_package_json
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
    | Complete_copy_base_project => "Complete_copy_base_project"
    | Complete_bundler_copy_files => "Complete_bundler_copy_files"
    | Complete_bundler_extend_package_json => "Complete_bundler_extend_package_json"
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
    | (Create_dir, Complete_create_dir) => {
        ...model,
        step: Copy_base_templates,
      }
    | (Copy_base_templates, Complete_copy_base_project) => {
        ...model,
        step: Bundler_copy_files,
      }
    | (Bundler_copy_files, Complete_bundler_copy_files) => {
        ...model,
        step: Bundler_extend_package_json,
      }
    | (Bundler_extend_package_json, Complete_bundler_extend_package_json) => {
        ...model,
        step: Node_pkg_manager,
      }
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
        context: {
          ...model.context,
          configuration: {
            ...model.context.configuration,
            overwrite: Some(overwrite),
          },
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
      let make = (~context: Context.t, ~onComplete, ~onError) => {
        let (create_complete, set_create_complete) =
          React.useState(() => false);

        let handleOnComplete = () => {
          set_create_complete(_ => true);
          onComplete();
        };

        React.useEffect0(() => {
          context.configuration.directory
          |> Engine.V2.create_project_directory(
               ~overwrite=?context.configuration.overwrite,
             )
          |> Promise_result.perform(result =>
               switch (result) {
               | Ok(res) => handleOnComplete(res)
               | Error(err) => onError(err)
               }
             );

          None;
        });

        <Box flexDirection=`column gap=1>
          {create_complete
             ? <Text>
                 {React.string("Creating project directory complete")}
               </Text>
             : <Spinner label="Creating project directory" />}
        </Box>;
      };
    };

    [@react.component]
    let make = (~isActive, ~context: Context.t, ~onComplete, ~onError) => {
      let (project_dir_exists, set_project_dir_exists) =
        React.useState(() => None);

      React.useEffect1(
        () => {
          if (isActive) {
            context.configuration.directory
            |> Engine.V2.directory_exists
            |> Promise_result.perform(result =>
                 switch (result) {
                 | Ok(exists) => set_project_dir_exists(_ => Some(exists))
                 | Error(err) => onError(err)
                 }
               );
          };
          None;
        },
        [|isActive|],
      );

      switch (project_dir_exists, context.configuration.overwrite) {
      | (None, _) => <Spinner label="Checking if project directory exists" />
      | (Some(true), None) =>
        <Overwrite_input context onSubmit={_ => ()} isDisabled=false />
      | (Some(true), Some(_overwrite)) =>
        <>
          <Overwrite_input context onSubmit={_ => ()} isDisabled=true />
          <Create context onComplete onError />
        </>
      | (Some(false), _) => <Create context onComplete onError />
      };
    };
  };

  module Copy_base_templates = {
    open Ui;
    [@react.component]
    let make = (~isActive, ~context: Context.t, ~onComplete, ~onError) => {
      let (copy_complete, set_copy_complete) = React.useState(() => false);

      let handleOnComplete = () => {
        set_copy_complete(_ => true);
        onComplete();
      };

      React.useEffect1(
        () => {
          if (isActive) {
            context.configuration.directory
            |> Engine.V2.copy_base_project
            |> Promise_result.perform(result =>
                 switch (result) {
                 | Ok(res) => handleOnComplete(res)
                 | Error(err) => onError(err)
                 }
               );
          };

          None;
        },
        [|isActive|],
      );

      <Box flexDirection=`column gap=1>
        {copy_complete
           ? <Text> {React.string("Copying base templates complete")} </Text>
           : <Spinner label="Copying base templates" />}
      </Box>;
    };
  };

  module Bundler = {
    module Copy_files = {
      open Ui;
      [@react.component]
      let make = (~isActive, ~context: Context.t, ~onComplete, ~onError) => {
        let (copy_complete, set_copy_complete) = React.useState(() => false);

        let handleOnComplete = () => {
          set_copy_complete(_ => true);
          onComplete();
        };

        React.useEffect1(
          () => {
            if (isActive) {
              context.configuration.directory
              |> Engine.V2.copy_bundler_files(
                   ~bundler=context.configuration.bundler,
                 )
              |> Promise_result.perform(result =>
                   switch (result) {
                   | Ok(res) => handleOnComplete(res)
                   | Error(err) => onError(err)
                   }
                 );
            };

            None;
          },
          [|isActive|],
        );

        let bundler_name =
          context.configuration.bundler
          |> Core.Bundler.to_string
          |> String.capitalize_ascii;

        <Box flexDirection=`column gap=1>
          {copy_complete
             ? <Text>
                 {React.string(
                    "Copying " ++ bundler_name ++ " files complete",
                  )}
               </Text>
             : <Spinner label={"Copying " ++ bundler_name ++ " files"} />}
        </Box>;
      };
    };

    module Extend_package_json = {
      [@react.component]
      let make =
          (~isActive as _, ~context as _, ~onComplete as _, ~onError as _) => {
        <Text> {React.string("Bundler")} </Text>;
      };
    };

    [@react.component]
    let make =
        (~isActive as _, ~context as _, ~onComplete as _, ~onError as _) => {
      <Text> {React.string("Bundler")} </Text>;
    };
  };
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
    let make = (~configuration: Configuration.t, ~onComplete) => {
      let (model, dispatch) =
        React.useReducer(
          update,
          {
            context: Context.of_configuration(configuration),
            step: Create_dir,
            error: None,
          },
        );
      let (error, set_error) = React.useState(() => None);

      let onError = err => {
        set_error(_ => Some(err));
      };

      React.useEffect1(
        () => {
          if (model.step == Node_pkg_manager) {
            onComplete();
          };
          None;
        },
        [|model.step|],
      );

      switch (error) {
      | Some(err) => <Text> {React.string(err)} </Text>
      | None =>
        <Box flexDirection=`column gap=1>
          <Create_dir
            isActive={model.step == Create_dir}
            context={model.context}
            onComplete={() => dispatch(Complete_create_dir)}
            onError
          />
          <Copy_base_templates
            isActive={model.step == Copy_base_templates}
            context={model.context}
            onComplete={() => dispatch(Complete_copy_base_project)}
            onError
          />
          <Bundler.Copy_files
            isActive={model.step == Bundler_copy_files}
            context={model.context}
            onComplete={() => dispatch(Complete_bundler_copy_files)}
            onError
          />
          <Bundler.Extend_package_json
            isActive={model.step == Bundler_extend_package_json}
            context={model.context}
            onComplete={() => dispatch(Complete_bundler_extend_package_json)}
            onError
          />
        </Box>
      };
    };
  };
};

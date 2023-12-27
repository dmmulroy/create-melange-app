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
    | Node_pkg_manager => 4
    | Git => 5
    | Opam_create_switch => 6
    | Opam_install_deps => 7
    | Opam_install_dev_deps => 8
    | Dune_build => 9
    | Finished => 10
    };

  type state = {
    configuration: Configuration.t,
    pkg_json: Template_v2.t(Package_json.t),
    dune_project: Template_v2.t(Dune_project.t),
    step,
    error: option(string),
  };

  module Create_dir = {
    open Ui;
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let (create_complete, set_create_complete) =
        React.useState(() => false);

      let handleOnComplete = () => {
        set_create_complete(_ => true);
        onComplete();
      };

      let is_active = state.step == Create_dir;
      let is_visible = step_to_int(state.step) >= step_to_int(Create_dir);

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
            |> Engine.V2.create_project_directory(
                 ~overwrite=?state.configuration.overwrite,
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
        [|is_active|],
      );

      if (!is_visible) {
        React.null;
      } else {
        switch (is_visible) {
        | false => React.null
        | true =>
          <Box flexDirection=`column gap=1>
            {create_complete
               ? <Box flexDirection=`row gap=1>
                   <Badge color=`green> {React.string("COMPLETE")} </Badge>
                   <Text> {React.string("Creating project directory")} </Text>
                 </Box>
               : <Spinner label="Creating project directory" />}
          </Box>
        };
      };
    };
  };

  module Copy_base_templates = {
    open Ui;
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let (copy_complete, set_copy_complete) = React.useState(() => false);

      let is_active = state.step == Copy_base_templates;
      let is_visible =
        step_to_int(state.step) >= step_to_int(Copy_base_templates);

      let handleOnComplete = () => {
        set_copy_complete(_ => true);
        onComplete();
      };

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
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
        [|is_active|],
      );

      if (!is_visible) {
        React.null;
      } else {
        <Box flexDirection=`column gap=1>
          {copy_complete
             ? <Box flexDirection=`row gap=1>
                 <Badge color=`green> {React.string("COMPLETE")} </Badge>
                 <Text> {React.string("Copying base templates")} </Text>
               </Box>
             : <Spinner label="Copying base templates" />}
        </Box>;
      };
    };
  };

  module Bundler = {
    module Copy_files = {
      open Ui;
      [@react.component]
      let make = (~state, ~onComplete, ~onError) => {
        let (copy_complete, set_copy_complete) = React.useState(() => false);

        let handleOnComplete = () => {
          set_copy_complete(_ => true);
          onComplete();
        };

        let is_active = state.step == Copy_base_templates;
        let is_visible =
          step_to_int(state.step) >= step_to_int(Copy_base_templates);

        React.useEffect1(
          () => {
            if (is_active) {
              state.configuration.directory
              |> Engine.V2.copy_bundler_files(
                   ~bundler=state.configuration.bundler,
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
          [|is_active|],
        );

        let bundler_name =
          state.configuration.bundler
          |> Bundler.to_string
          |> String.capitalize_ascii;

        if (!is_visible) {
          React.null;
        } else {
          <Box flexDirection=`column gap=1>
            {copy_complete
               ? <Box flexDirection=`row gap=1>
                   <Badge color=`green> {React.string("COMPLETE")} </Badge>
                   <Text>
                     {React.string(
                        "Copying " ++ bundler_name ++ " files complete",
                      )}
                   </Text>
                 </Box>
               : <Spinner label={"Copying " ++ bundler_name ++ " files"} />}
          </Box>;
        };
      };
    };

    module Extend_package_json = {
      [@react.component]
      let make = (~isActive, ~state, ~onComplete, ~onError) => {
        let (complete, set_complete) = React.useState(() => false);

        let handleOnComplete = () => {
          set_complete(_ => true);
          onComplete();
        };

        React.useEffect1(
          () => {
            if (isActive) {
              state.configuration.directory
              |> Engine.V2.copy_bundler_files(
                   ~bundler=state.configuration.bundler,
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
          state.configuration.bundler
          |> Bundler.to_string
          |> String.capitalize_ascii;

        <Box flexDirection=`column gap=1>
          {complete
             ? <Text>
                 {React.string(
                    "Copying " ++ bundler_name ++ " files complete",
                  )}
               </Text>
             : <Spinner label={"Copying " ++ bundler_name ++ " files"} />}
        </Box>;
      };
    };

    [@react.component]
    let make = (~configuration as _, ~onComplete as _, ~onError as _) => {
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
      let (state, set_state) =
        React.useState(_ =>
          {
            configuration,
            step: Create_dir,
            pkg_json: Package_json.template(configuration.name),
            dune_project: Dune_project.template(configuration.name),
            error: None,
          }
        );

      let onError = err => set_state(_ => {...state, error: Some(err)});

      React.useEffect1(
        () => {
          if (state.step == Node_pkg_manager) {
            onComplete();
          };
          None;
        },
        [|state.step|],
      );

      switch (state.error) {
      | Some(err) => <Text> {React.string(err)} </Text>
      | None =>
        <Box flexDirection=`column gap=1>
          <Create_dir
            state
            onComplete={() =>
              set_state(_ => {...state, step: Copy_base_templates})
            }
            onError
          />
          <Copy_base_templates
            state
            onComplete={() =>
              set_state(state => {...state, step: Bundler_copy_files})
            }
            onError
          />
          <Bundler.Copy_files
            state
            onComplete={() =>
              set_state(state =>
                {...state, step: Bundler_extend_package_json}
              )
            }
            onError
          />
        </Box>
      };
    };
  };
};
//<Bundler.Extend_package_json
//  state
//  onComplete={() => set_state(state => {...state, step: Git})}
//  onError
///>

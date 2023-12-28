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
    | Compile_package_json
    | Compile_dune_project
    | Node_pkg_manager_install
    | Git_copy_ignore_file
    | Git_init_and_stage
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
    | Compile_package_json => "Compile_package_json"
    | Compile_dune_project => "Compile_dune_project"
    | Node_pkg_manager_install => "Node_pkg_manager_install"
    | Git_copy_ignore_file => "Git_copy_ignore_file"
    | Git_init_and_stage => "Git_init_and_stage"
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
    | Compile_package_json => 4
    | Compile_dune_project => 5
    | Node_pkg_manager_install => 6
    | Git_copy_ignore_file => 7
    | Git_init_and_stage => 8
    | Opam_create_switch => 9
    | Opam_install_deps => 10
    | Opam_install_dev_deps => 11
    | Dune_build => 12
    | Finished => 13
    };

  type state = {
    configuration: Configuration.t,
    pkg_json: Template.t(Package_json.t),
    dune_project: Template.t(Dune_project.t),
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
                   <Badge color=`green> {React.string("Complete")} </Badge>
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
                 <Badge color=`green> {React.string("Complete")} </Badge>
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

        let is_active = state.step == Bundler_copy_files;
        let is_visible =
          step_to_int(state.step) >= step_to_int(Bundler_copy_files);

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
                   <Badge color=`green> {React.string("Complete")} </Badge>
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
      let make = (~state, ~onComplete, ~onError as _) => {
        let (complete, set_complete) = React.useState(() => false);

        let is_active = state.step == Bundler_extend_package_json;
        let is_visible =
          step_to_int(state.step) >= step_to_int(Bundler_extend_package_json);

        React.useEffect1(
          () => {
            if (is_active) {
              let updated_pkg_json =
                state.pkg_json
                |> Engine.V2.extend_package_json_with_bundler(
                     ~bundler=state.configuration.bundler,
                   );

              set_complete(_ => true);
              onComplete({...state, pkg_json: updated_pkg_json});
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
            {complete
               ? <Box flexDirection=`row gap=1>
                   <Badge color=`green> {React.string("Complete")} </Badge>
                   <Text>
                     {React.string(
                        "Extending package.json with "
                        ++ bundler_name
                        ++ "scripts and dependencies complete",
                      )}
                   </Text>
                 </Box>
               : <Spinner
                   label={"Extending package.json with " ++ bundler_name}
                 />}
          </Box>;
        };
      };
    };
  };

  module Compile = {
    module Compile_package_json = {
      open Ui;
      [@react.component]
      let make = (~state, ~onComplete, ~onError) => {
        let (copy_complete, set_copy_complete) = React.useState(() => false);

        let is_active = state.step == Compile_package_json;
        let is_visible =
          step_to_int(state.step) >= step_to_int(Compile_package_json);

        React.useEffect1(
          () => {
            if (is_active) {
              state.pkg_json
              |> Engine.V2.compile
              |> Promise_result.perform(result =>
                   switch (result) {
                   | Ok(res) =>
                     set_copy_complete(_ => true);
                     onComplete({...state, pkg_json: res});
                   | Error(err) => onError(err)
                   }
                 );
              ();
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
                   <Badge color=`green> {React.string("Complete")} </Badge>
                   <Text>
                     {React.string("Compiling package.json template complete")}
                   </Text>
                 </Box>
               : <Spinner label="Copying package.json template" />}
          </Box>;
        };
      };
    };
    module Compile_dune_project = {
      open Ui;
      [@react.component]
      let make = (~state, ~onComplete, ~onError) => {
        let (copy_complete, set_copy_complete) = React.useState(() => false);

        let is_active = state.step == Compile_dune_project;
        let is_visible =
          step_to_int(state.step) >= step_to_int(Compile_dune_project);

        React.useEffect1(
          () => {
            if (is_active) {
              state.dune_project
              |> Engine.V2.compile
              |> Promise_result.perform(result =>
                   switch (result) {
                   | Ok(res) =>
                     set_copy_complete(_ => true);
                     onComplete({...state, dune_project: res});
                   | Error(err) => onError(err)
                   }
                 );
              ();
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
                   <Badge color=`green> {React.string("Complete")} </Badge>
                   <Text>
                     {React.string("Compiling dune_project template complete")}
                   </Text>
                 </Box>
               : <Spinner label="Copying dune_project template" />}
          </Box>;
        };
      };
    };
  };

  module Node_pkg_manager_install = {
    open Ui;
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let (copy_complete, set_copy_complete) = React.useState(() => false);

      let is_active = state.step == Node_pkg_manager_install;
      let is_visible =
        step_to_int(state.step) >= step_to_int(Node_pkg_manager_install);

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
            |> Engine.V2.node_pkg_manager_install
            |> Promise_result.perform(result =>
                 switch (result) {
                 | Ok(_) =>
                   set_copy_complete(_ => true);
                   onComplete();
                 | Error(err) => onError(err)
                 }
               );
            ();
          };

          None;
        },
        [|is_active|],
      );

      let pkg_manger =
        Nodejs.Process.npm_config_user_agent
        |> Nodejs.Process.npm_user_agent_to_string;

      if (!is_visible) {
        React.null;
      } else {
        <Box flexDirection=`column gap=1>
          {copy_complete
             ? <Box flexDirection=`row gap=1>
                 <Badge color=`green> {React.string("Complete")} </Badge>
                 <Text>
                   {React.string(
                      "Installing npm dependncies with "
                      ++ pkg_manger
                      ++ " complete",
                    )}
                 </Text>
               </Box>
             : <Spinner
                 label={"Installing npm dependncies with " ++ pkg_manger}
               />}
        </Box>;
      };
    };
  };

  module Git = {
    module Copy_ignore_file = {
      open Ui;
      [@react.component]
      let make = (~state, ~onComplete, ~onError) => {
        let (copy_complete, set_copy_complete) = React.useState(() => false);

        let is_active = state.step == Git_copy_ignore_file;
        let is_visible =
          step_to_int(state.step) >= step_to_int(Git_copy_ignore_file);

        React.useEffect1(
          () => {
            if (is_active) {
              state.configuration.directory
              |> Engine.V2.copy_git_ignore
              |> Promise_result.perform(result =>
                   switch (result) {
                   | Ok(_) =>
                     set_copy_complete(_ => true);
                     onComplete();
                   | Error(err) => onError(err)
                   }
                 );
              ();
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
                   <Badge color=`green> {React.string("Complete")} </Badge>
                   <Text>
                     {React.string("Copying .gitignore file complete")}
                   </Text>
                 </Box>
               : <Spinner label="Copying .gitignore file" />}
          </Box>;
        };
      };
    };

    module Init_and_stage = {
      open Ui;
      [@react.component]
      let make = (~state, ~onComplete, ~onError) => {
        let (copy_complete, set_copy_complete) = React.useState(() => false);

        let is_active = state.step == Git_init_and_stage;
        let is_visible =
          step_to_int(state.step) >= step_to_int(Git_init_and_stage);

        React.useEffect1(
          () => {
            if (is_active) {
              state.configuration.directory
              |> Engine.V2.git_init_and_stage
              |> Promise_result.perform(result =>
                   switch (result) {
                   | Ok(_) =>
                     set_copy_complete(_ => true);
                     onComplete();
                   | Error(err) => onError(err)
                   }
                 );
              ();
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
                   <Badge color=`green> {React.string("Complete")} </Badge>
                   <Text>
                     {React.string("Initializing git repository complete")}
                   </Text>
                 </Box>
               : <Spinner label="Initializing git repository" />}
          </Box>;
        };
      };
    };
  };

  module Opam = {
    module Create_switch = {
      open Ui;
      [@react.component]
      let make = (~state, ~onComplete, ~onError) => {
        let (copy_complete, set_copy_complete) = React.useState(() => false);

        let is_active = state.step == Opam_create_switch;
        let is_visible =
          step_to_int(state.step) >= step_to_int(Opam_create_switch);

        React.useEffect1(
          () => {
            if (is_active) {
              state.configuration.directory
              |> Engine.V2.opam_create_switch
              |> Promise_result.perform(result =>
                   switch (result) {
                   | Ok(_) =>
                     set_copy_complete(_ => true);
                     onComplete();
                   | Error(err) => onError(err)
                   }
                 );
              ();
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
                   <Badge color=`green> {React.string("Complete")} </Badge>
                   <Text>
                     {React.string("Creating opam switch complete")}
                   </Text>
                 </Box>
               : <Spinner
                   label="Creating opam switch, this may take a few minutes"
                 />}
          </Box>;
        };
      };
    };
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
            pkg_json:
              Package_json.template(
                ~project_name=configuration.name,
                ~project_directory=configuration.directory,
              ),
            dune_project:
              Dune_project.template(
                ~project_name=configuration.name,
                ~project_directory=configuration.directory,
              ),
            error: None,
          }
        );
      let (step_transitions, set_step_transitions) = React.useState(() => []);

      let onError = err => set_state(_ => {...state, error: Some(err)});

      React.useEffect1(
        () => {
          if (state.step == Finished) {
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
            onComplete={() => {
              set_state(_ => {...state, step: Copy_base_templates});
              set_step_transitions((prev: list(step)) =>
                prev @ [Copy_base_templates]
              );
            }}
            onError
          />
          <Copy_base_templates
            state
            onComplete={() => {
              set_state(state => {...state, step: Bundler_copy_files});

              set_step_transitions((prev: list(step)) =>
                prev @ [Bundler_copy_files]
              );
            }}
            onError
          />
          <Bundler.Copy_files
            state
            onComplete={() => {
              set_state(state =>
                {...state, step: Bundler_extend_package_json}
              );
              set_step_transitions((prev: list(step)) =>
                prev @ [Bundler_extend_package_json]
              );
            }}
            onError
          />
          <Bundler.Extend_package_json
            state
            onComplete={(updated_state: state) => {
              set_state(_ => {...updated_state, step: Compile_package_json});

              set_step_transitions((prev: list(step)) =>
                prev @ [Compile_package_json]
              );
            }}
            onError
          />
          <Compile.Compile_package_json
            state
            onComplete={updated_state => {
              set_state(_ => {...updated_state, step: Compile_dune_project});

              set_step_transitions((prev: list(step)) =>
                prev @ [Compile_dune_project]
              );
            }}
            onError
          />
          <Compile.Compile_dune_project
            state
            onComplete={updated_state => {
              set_state(_ =>
                {...updated_state, step: Node_pkg_manager_install}
              );

              set_step_transitions((prev: list(step)) =>
                prev @ [Node_pkg_manager_install]
              );
            }}
            onError
          />
          <Node_pkg_manager_install
            state
            onComplete={() => {
              set_state(_ => {...state, step: Git_copy_ignore_file});

              set_step_transitions((prev: list(step)) =>
                prev @ [Git_copy_ignore_file]
              );
            }}
            onError
          />
          <Git.Copy_ignore_file
            state
            onComplete={() => {
              set_state(_ => {...state, step: Git_init_and_stage});

              set_step_transitions((prev: list(step)) =>
                prev @ [Git_init_and_stage]
              );
            }}
            onError
          />
          <Git.Init_and_stage
            state
            onComplete={() => {
              set_state(_ => {...state, step: Opam_create_switch});

              set_step_transitions((prev: list(step)) =>
                prev @ [Opam_create_switch]
              );
            }}
            onError
          />
          <Opam.Create_switch
            state
            onComplete={() => {
              set_state(_ => {...state, step: Opam_install_deps});

              set_step_transitions((prev: list(step)) =>
                prev @ [Opam_install_deps]
              );
            }}
            onError
          />
          <Text> {React.string("Transitions:")} </Text>
          {step_transitions
           |> List.map(step =>
                <Text key={step_to_string(step)}>
                  {React.string(step_to_string(step))}
                </Text>
              )
           |> Array.of_list
           |> React.array}
        </Box>
      };
    };
  };
};

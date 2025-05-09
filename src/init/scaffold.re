open Bindings;
open Ink;
open Ui;

open Core;

// For Minttea rewrite:
// This file is a great example of do as I say not as I do. It's a mess and
// I just brute forced it to work w/ lots of copy/paste. I think a better way
// to have done this would have been to create functor to create the steps
type step =
  // Section 1 - Create project directory
  | Create_dir
  | Copy_base_templates
  // Setting 2 - Initialize bundler
  | Bundler_copy_files
  | Bundler_extend_package_json
  // Section 3 - Initialize app files
  | App_copy_files
  | App_extend_package_json
  | App_extend_dune_project
  // Section 4 - Initialize test files
  | Tests_copy_files
  | Tests_extend_package_json
  | Tests_extend_dune_project
  // Section 5 - Compile templates
  | Compile_package_json
  | Compile_dune_project
  | Compile_root_dune_file
  | Compile_app_dune_file
  | Compile_test_dune_file
  | Compile_app_module
  | Compile_readme
  // Section 6 - Optional - Initialize node package manager
  | Node_pkg_manager_install
  // Section 7 - optional - Initialize ocaml toolchain
  | Opam_update
  | Opam_create_switch
  | Opam_install_dune
  | Dune_install
  | Opam_install_dev_deps
  | Opam_install_deps
  | Dune_build
  // Section 8 - optional - Initialize git
  | Git_copy_ignore_file
  | Git_init_and_stage
  | Finished;

let step_to_string = step =>
  switch (step) {
  | Create_dir => "Create_dir"
  | Copy_base_templates => "Copy_base_templates"
  | Bundler_copy_files => "Bundler_copy_files"
  | Bundler_extend_package_json => "Bundler_extend_package_json"
  | App_copy_files => "App_copy_files"
  | App_extend_package_json => "App_extend_package_json"
  | App_extend_dune_project => "App_extend_dune_project"
  | Tests_copy_files => "Tests_copy_files"
  | Tests_extend_package_json => "Tests_extend_package_json"
  | Tests_extend_dune_project => "Tests_extend_dune_project"
  | Compile_package_json => "Compile_package_json"
  | Compile_dune_project => "Compile_dune_project"
  | Compile_root_dune_file => "Compile_root_dune_file"
  | Compile_app_dune_file => "Compile_app_dune_file"
  | Compile_test_dune_file => "Compile_test_dune_file"
  | Compile_app_module => "Compile_app_module"
  | Compile_readme => "Compile_readme"
  | Node_pkg_manager_install => "Node_pkg_manager_install"
  | Opam_update => "Opam_update"
  | Opam_create_switch => "Opam_create_switch"
  | Opam_install_dune => "Opam_install_dune"
  | Dune_install => "Dune_install"
  | Opam_install_dev_deps => "Opam_install_dev_deps"
  | Opam_install_deps => "Opam_install_deps"
  | Dune_build => "Dune_build"
  | Git_copy_ignore_file => "Git_copy_ignore_file"
  | Git_init_and_stage => "Git_init_and_stage"
  | Finished => "Finished"
  };

let step_to_int = step =>
  switch (step) {
  | Create_dir => 0
  | Copy_base_templates => 1
  | Bundler_copy_files => 2
  | Bundler_extend_package_json => 3
  | App_copy_files => 4
  | App_extend_package_json => 5
  | App_extend_dune_project => 6
  | Tests_copy_files => 7
  | Tests_extend_package_json => 8
  | Tests_extend_dune_project => 9
  | Compile_package_json => 10
  | Compile_dune_project => 11
  | Compile_root_dune_file => 12
  | Compile_app_dune_file => 13
  | Compile_test_dune_file => 14
  | Compile_app_module => 15
  | Compile_readme => 16
  | Node_pkg_manager_install => 17
  | Opam_update => 18
  | Opam_create_switch => 19
  | Opam_install_dune => 20
  | Dune_install => 21
  | Opam_install_dev_deps => 22
  | Opam_install_deps => 23
  | Dune_build => 24
  | Git_copy_ignore_file => 25
  | Git_init_and_stage => 26
  | Finished => 27
  };

type state = {
  configuration: Configuration.t,
  pkg_json: Template.t(Package_json.t),
  dune_project: Template.t(Dune.Dune_project.t),
  root_dune_file: Template.t(Dune.Dune_file.t),
  app_dune_file: Template.t(Dune.Dune_file.t),
  test_dune_file: Template.t(Dune.Dune_file.t),
  app_module: Template.t(App_module.t),
  readme: Template.t(Readme.t),
  step,
  error: option(string),
};

type actionType('a, 'b) =
  | Sync(unit => 'a)
  | Async(unit => Promise_result.t('a, 'b));

let useStep =
    (
      ~state,
      ~activeStep: step,
      ~action,
      ~onComplete,
      ~onError=_ => (),
      ~loadingLabel="",
      ~successLabel="",
      (),
    ) => {
  let (complete, set_complete) = React.useState(() => false);
  let is_active = state.step == activeStep;
  let is_visible = step_to_int(state.step) >= step_to_int(activeStep);

  React.useEffect1(
    () => {
      if (is_active) {
        switch (action) {
        | Sync(fn) =>
          let result = fn();
          // TODO: Handle errors
          set_complete(_ => true);
          onComplete(result);
        | Async(fn) =>
          fn()
          |> Promise_result.perform(result =>
               switch (result) {
               | Ok(res) =>
                 set_complete(_ => true);
                 onComplete(res);
               | Error(err) => onError(err)
               }
             )
        };
      };
      None;
    },
    [|is_active|],
  );

  if (!is_visible) {
    React.null;
  } else {
    <Box flexDirection=`column gap=1>
      {complete
         ? <Box flexDirection=`row gap=1>
             <Text color="green"> {React.string(successLabel)} </Text>
           </Box>
         : <Spinner label=loadingLabel />}
    </Box>;
  };
};

module Create_dir = {
  [@react.component]
  let make = (~state, ~onComplete, ~onError) =>
    useStep(
      ~state,
      ~activeStep=Create_dir,
      ~action=
        Async(
          () =>
            state.configuration.directory
            |> Engine.create_project_directory(
                 ~overwrite=?state.configuration.overwrite,
               ),
        ),
      ~onComplete,
      ~onError,
      (),
    );
};

module Copy_base_templates = {
  [@react.component]
  let make = (~state, ~onComplete, ~onError) => {
    useStep(
      ~state,
      ~activeStep=Copy_base_templates,
      ~action=
        Async(
          () => state.configuration.directory |> Engine.copy_base_project,
        ),
      ~onComplete,
      ~onError,
      ~loadingLabel="Creating base project...",
      ~successLabel={j|✔ Successfully created base project!|j},
      (),
    );
  };
};

module Bundler = {
  module Copy_files = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Bundler_copy_files,
        ~action=
          Async(
            () =>
              state.configuration.directory
              |> Engine.copy_bundler_files(
                   ~bundler=state.configuration.bundler,
                   ~is_react_app=state.configuration.is_react_app,
                 ),
          ),
        ~onComplete,
        ~onError,
        (),
      );
  };

  module Extend_package_json = {
    [@react.component]
    let make = (~state, ~onComplete: state => unit, ~onError as _) => {
      let bundler_name =
        state.configuration.bundler
        |> Bundler.to_string
        |> String.capitalize_ascii;
      useStep(
        ~state,
        ~activeStep=Bundler_extend_package_json,
        ~action=
          Sync(
            () => {
              let updated_pkg_json =
                state.pkg_json
                |> Engine.extend_package_json_with_bundler(
                     ~bundler=state.configuration.bundler,
                     ~project_name=state.configuration.name,
                   );
              {
                ...state,
                pkg_json: updated_pkg_json,
              };
            },
          ),
        ~onComplete,
        ~loadingLabel="Initializing bundler: " ++ bundler_name ++ "...",
        ~successLabel=
          {j|✔ Successfully initialized bundler: |j} ++ bundler_name,
        (),
      );
    };
  };
};

module App_files = {
  module Copy_files = {
    // open Ui;
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=App_copy_files,
        ~onComplete,
        ~onError,
        ~action=
          Async(
            () =>
              state.configuration.directory
              |> Engine.copy_app_files(
                   ~syntax_preference=state.configuration.syntax_preference,
                   ~is_react_app=state.configuration.is_react_app,
                 ),
          ),
        (),
      );
  };

  module Extend_package_json = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError as _) =>
      useStep(
        ~state,
        ~activeStep=App_extend_package_json,
        ~action=
          Sync(
            () => {
              let updated_pkg_json =
                state.pkg_json
                |> Engine.extend_package_json_with_app_settings(
                     ~is_react_app=state.configuration.is_react_app,
                   );

              {
                ...state,
                pkg_json: updated_pkg_json,
              };
            },
          ),
        ~onComplete,
        (),
      );
  };

  module Extend_dune_project = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError as _) =>
      useStep(
        ~state,
        ~activeStep=App_extend_dune_project,
        ~onComplete,
        ~loadingLabel="Initializing application files...",
        ~successLabel={j|✔ Successfully initialized application files|j},
        ~action=
          Sync(
            () => {
              let updated_dune_project =
                state.dune_project
                |> Engine.extend_dune_project_with_app_settings(
                     ~is_react_app=state.configuration.is_react_app,
                     ~syntax_preference=state.configuration.syntax_preference,
                     ~project_name=state.configuration.name,
                   );
              {
                ...state,
                dune_project: updated_dune_project,
              };
            },
          ),
        (),
      );
  };
};

module Test_files = {
  module Copy_files = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Tests_copy_files,
        ~action=
          Async(
            () =>
              state.configuration.directory
              |> Engine.copy_test_files(
                   ~syntax_preference=state.configuration.syntax_preference,
                   ~is_react_app=state.configuration.is_react_app,
                 ),
          ),
        ~onComplete,
        ~onError,
        (),
      );
  };

  module Extend_package_json = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError as _) => {
      useStep(
        ~state,
        ~activeStep=Tests_extend_package_json,
        ~onComplete,
        ~action=
          Sync(
            () => {
              let updated_pkg_json =
                state.pkg_json
                |> Engine.extend_package_json_with_tests(
                     ~is_react_app=state.configuration.is_react_app,
                     ~project_name=state.configuration.name,
                   );
              {
                ...state,
                pkg_json: updated_pkg_json,
              };
            },
          ),
        (),
      );
    };
  };

  module Extend_dune_project = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError as _) =>
      useStep(
        ~state,
        ~activeStep=Tests_extend_dune_project,
        ~onComplete,
        ~action=
          Sync(
            () => {
              let updated_dune_project =
                state.dune_project
                |> Engine.extend_dune_project_with_tests(
                     ~is_react_app=state.configuration.is_react_app,
                     ~project_name=state.configuration.name,
                   );
              {
                ...state,
                dune_project: updated_dune_project,
              };
            },
          ),
        ~loadingLabel="Initializing test files...",
        ~successLabel={j|✔ Successfully initialized test files|j},
        (),
      );
  };
};

module Compile = {
  module Compile_package_json = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      useStep(
        ~state,
        ~activeStep=Compile_package_json,
        ~action=Async(() => state.pkg_json |> Engine.compile),
        ~loadingLabel="Compiling package.json...",
        ~onError,
        ~onComplete=
          updated_pkg_json => {
            onComplete({
              ...state,
              pkg_json: updated_pkg_json,
            })
          },
        (),
      );
    };
  };

  module Compile_dune_project = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      useStep(
        ~state,
        ~action=Async(() => state.dune_project |> Engine.compile),
        ~loadingLabel="Compiling templates...",
        ~activeStep=Compile_dune_project,
        ~onError,
        ~onComplete=
          updated_dune_project => {
            onComplete({
              ...state,
              dune_project: updated_dune_project,
            })
          },
        (),
      );
    };
  };

  module Compile_root_dune_file = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Compile_root_dune_file,
        ~action=Async(() => state.root_dune_file |> Engine.compile),
        ~loadingLabel="Compiling templates...",
        ~onComplete=
          res =>
            onComplete({
              ...state,
              root_dune_file: res,
            }),
        ~onError,
        (),
      );
  };

  module Compile_app_dune_file = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Compile_app_dune_file,
        ~action=Async(() => state.app_dune_file |> Engine.compile),
        ~loadingLabel="Compiling templates...",
        ~onComplete=
          res =>
            onComplete({
              ...state,
              app_dune_file: res,
            }),
        ~onError,
        (),
      );
  };

  module Compile_test_dune_file = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Compile_test_dune_file,
        ~action=Async(() => state.test_dune_file |> Engine.compile),
        ~loadingLabel="Compiling templates...",
        ~onComplete=
          res =>
            onComplete({
              ...state,
              test_dune_file: res,
            }),
        ~onError,
        (),
      );
  };

  module Compile_app_module = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Compile_app_module,
        ~action=Async(() => state.app_module |> Engine.compile),
        ~loadingLabel="Compiling templates...",
        ~onComplete=
          res =>
            onComplete({
              ...state,
              app_module: res,
            }),
        ~onError,
        (),
      );
  };

  module Compile_readme = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Compile_readme,
        ~action=Async(() => state.readme |> Engine.compile),
        ~loadingLabel="Compiling templates...",
        ~successLabel={j|✔ Successfully compiled templates!|j},
        ~onComplete=
          res =>
            onComplete({
              ...state,
              readme: res,
            }),
        ~onError,
        (),
      );
  };
};

module Node_pkg_manager_install = {
  open Ui;
  [@react.component]
  let make = (~state, ~onComplete, ~onError) => {
    let (copy_complete, set_copy_complete) = React.useState(() => false);

    let is_active =
      state.step == Node_pkg_manager_install
      && state.configuration.initialize_npm;
    let is_visible =
      state.configuration.initialize_npm
      && step_to_int(state.step) >= step_to_int(Node_pkg_manager_install);

    React.useEffect1(
      () => {
        if (is_active) {
          state.configuration.directory
          |> Engine.node_pkg_manager_install
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
               <Text color="green">
                 {React.string(
                    {j|✔ Successfully installed npm dependencies with |j}
                    ++ pkg_manger,
                  )}
               </Text>
             </Box>
           : <Spinner
               label={"Installing npm dependencies with " ++ pkg_manger}
             />}
      </Box>;
    };
  };
};

module Git = {
  module Copy_ignore_file = {
    // open Ui;
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let is_active =
        state.step == Git_copy_ignore_file
        && state.configuration.initialize_git;

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
            |> Engine.copy_git_ignore
            |> Promise_result.perform(result =>
                 switch (result) {
                 | Ok(_) => onComplete()
                 | Error(err) => onError(err)
                 }
               );
            ();
          };

          None;
        },
        [|is_active|],
      );
      React.null;
    };
  };

  module Init_and_stage = {
    open Ui;
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let (copy_complete, set_copy_complete) = React.useState(() => false);

      let is_active =
        state.step == Git_init_and_stage && state.configuration.initialize_git;
      let is_visible =
        state.configuration.initialize_git
        && step_to_int(state.step) >= step_to_int(Git_init_and_stage);

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
            |> Engine.git_init_and_stage
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
                 <Text color="green">
                   {React.string({j|✔ Successfully initialized git!|j})}
                 </Text>
               </Box>
             : <Spinner label="Initializing git..." />}
        </Box>;
      };
    };
  };
};

module Opam = {
  module Update = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let (complete, set_complete) = React.useState(() => false);

      let is_active =
        state.step == Opam_update
        && state.configuration.initialize_ocaml_toolchain;

      let is_visible =
        state.configuration.initialize_ocaml_toolchain
        && step_to_int(state.step) >= step_to_int(Opam_update);

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
            |> Engine.opam_update
            |> Promise_result.perform(result =>
                 switch (result) {
                 | Ok(_) =>
                   set_complete(_ => true);
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
        complete
          ? React.null
          : <Box flexDirection=`column gap=1>
              <Spinner
                label="Initializing OCaml toolchain, this may take a few minutes..."
              />
            </Box>;
      };
    };
  };

  module Install_dune = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let (complete, set_complete) = React.useState(() => false);

      let is_active =
        state.step == Opam_install_dune
        && state.configuration.initialize_ocaml_toolchain;

      let is_visible =
        state.configuration.initialize_ocaml_toolchain
        && step_to_int(state.step) >= step_to_int(Opam_install_dune);

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
            |> Engine.opam_install_dune
            |> Promise_result.perform(result =>
                 switch (result) {
                 | Ok(_) =>
                   set_complete(_ => true);
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
        complete
          ? React.null
          : <Box flexDirection=`column gap=1>
              <Spinner
                label="Initializing OCaml toolchain, this may take a few minutes..."
              />
            </Box>;
      };
    };
  };

  module Create_switch = {
    open Ui;
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let (complete, set_complete) = React.useState(() => false);

      let is_active =
        state.step == Opam_create_switch
        && state.configuration.initialize_ocaml_toolchain;

      let is_visible =
        state.configuration.initialize_ocaml_toolchain
        && step_to_int(state.step) >= step_to_int(Opam_create_switch);

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
            |> Engine.opam_create_switch
            |> Promise_result.perform(result =>
                 switch (result) {
                 | Ok(_) =>
                   set_complete(_ => true);
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
        complete
          ? React.null
          : <Box flexDirection=`column gap=1>
              <Spinner
                label="Initializing OCaml toolchain, this may take a few minutes..."
              />
            </Box>;
      };
    };
  };

  module Install_dev_deps = {
    open Ui;
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let (complete, set_complete) = React.useState(() => false);

      let is_active =
        state.step == Opam_install_dev_deps
        && state.configuration.initialize_ocaml_toolchain;
      let is_visible =
        state.configuration.initialize_ocaml_toolchain
        && step_to_int(state.step) >= step_to_int(Opam_install_dev_deps);

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
            |> Engine.opam_install_dev_dependencies
            |> Promise_result.perform(result =>
                 switch (result) {
                 | Ok(_) =>
                   set_complete(_ => true);
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
        complete
          ? React.null
          : <Box flexDirection=`column gap=1>
              <Spinner
                label="Initializing OCaml toolchain, this may take a few minutes..."
              />
            </Box>;
      };
    };
  };

  module Install_deps = {
    open Ui;
    [@react.component]
    let make = (~state, ~onComplete, ~onError) => {
      let (complete, set_complete) = React.useState(() => false);

      let is_active =
        state.step == Opam_install_deps
        && state.configuration.initialize_ocaml_toolchain;
      let is_visible =
        state.configuration.initialize_ocaml_toolchain
        && step_to_int(state.step) >= step_to_int(Opam_install_deps);

      React.useEffect1(
        () => {
          if (is_active) {
            state.configuration.directory
            |> Engine.opam_install_dependencies
            |> Promise_result.perform(result =>
                 switch (result) {
                 | Ok(_) =>
                   set_complete(_ => true);
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
        complete
          ? React.null
          : <Box flexDirection=`column gap=1>
              <Spinner
                label="Initializing OCaml toolchain, this may take a few minutes..."
              />
            </Box>;
      };
    };
  };
};

module Dune_install = {
  open Ui;
  [@react.component]
  let make = (~state, ~onComplete, ~onError) => {
    let (complete, set_complete) = React.useState(() => false);

    let is_active =
      state.step == Dune_install
      && state.configuration.initialize_ocaml_toolchain;
    let is_visible =
      state.configuration.initialize_ocaml_toolchain
      && step_to_int(state.step) >= step_to_int(Dune_install);

    React.useEffect1(
      () => {
        if (is_active) {
          state.configuration.directory
          |> Engine.dune_install
          |> Promise_result.perform(result =>
               switch (result) {
               | Ok(_) =>
                 set_complete(_ => true);
                 onComplete();
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
      complete
        ? React.null
        : <Box flexDirection=`column gap=1>
            <Spinner
              label="Initializing OCaml toolchain, this may take a few minutes..."
            />
          </Box>;
    };
  };
};

module Dune_build = {
  open Ui;
  [@react.component]
  let make = (~state, ~onComplete, ~onError) => {
    let (copy_complete, set_copy_complete) = React.useState(() => false);

    let is_active =
      state.step == Dune_build
      && state.configuration.initialize_ocaml_toolchain;

    let is_visible =
      state.configuration.initialize_ocaml_toolchain
      && step_to_int(state.step) >= step_to_int(Dune_build);

    React.useEffect1(
      () => {
        if (is_active) {
          state.configuration.directory
          |> Engine.dune_build
          |> Promise_result.perform(result =>
               switch (result) {
               | Ok(_) =>
                 set_copy_complete(_ => true);
                 onComplete();
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
               <Text color="green">
                 {React.string(
                    {j|✔ Successfully intialized the OCaml toolchain!|j},
                  )}
               </Text>
             </Box>
           : <Spinner
               label="Initializing OCaml toolchain, this may take a few minutes..."
             />}
      </Box>;
    };
  };
};

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
          Dune.Dune_project.template(
            ~project_name=configuration.name,
            ~project_directory=configuration.directory,
            ~is_mlx={
              configuration.syntax_preference == `OCaml
              && configuration.is_react_app;
            },
          ),
        root_dune_file:
          Dune.Dune_file.template(
            ~project_directory=configuration.directory,
            ~template_directory="./",
            Dune.Dune_file.root(configuration),
          ),
        app_dune_file:
          Dune.Dune_file.template(
            ~project_directory=configuration.directory,
            ~template_directory="./src",
            Dune.Dune_file.app_library(configuration),
          ),
        test_dune_file:
          Dune.Dune_file.template(
            ~project_directory=configuration.directory,
            ~template_directory="./test",
            Dune.Dune_file.test_library(configuration),
          ),
        app_module: App_module.template(configuration),
        readme: Readme.template(configuration),
        error: None,
      }
    );

  let onError =
    React.useCallback1(
      err => {onComplete(Result.error(err))},
      [|onComplete|],
    );

  React.useEffect1(
    () => {
      if (state.step == Finished) {
        switch (state.error) {
        | Some(err) => onComplete(Result.error(err))
        | None => onComplete(Result.ok())
        };
      };
      None;
    },
    [|state.step|],
  );

  <Box flexDirection=`column gap=1>
    <Text color="cyan"> {React.string("Scaffolding project...")} </Text>
    <Create_dir
      state
      onComplete={() => {
        set_state(_ =>
          {
            ...state,
            step: Copy_base_templates,
          }
        )
      }}
      onError
    />
    <Copy_base_templates
      state
      onComplete={() => {
        set_state(state =>
          {
            ...state,
            step: Bundler_copy_files,
          }
        )
      }}
      onError
    />
    <Bundler.Copy_files
      state
      onComplete={() => {
        set_state(state =>
          {
            ...state,
            step: Bundler_extend_package_json,
          }
        )
      }}
      onError
    />
    <Bundler.Extend_package_json
      state
      onComplete={(updated_state: state) => {
        set_state(_ =>
          {
            ...updated_state,
            step: App_copy_files,
          }
        )
      }}
      onError
    />
    <App_files.Copy_files
      state
      onComplete={() => {
        set_state(_ =>
          {
            ...state,
            step: App_extend_package_json,
          }
        )
      }}
      onError
    />
    <App_files.Extend_package_json
      state
      onComplete={updated_state => {
        set_state(_ =>
          {
            ...updated_state,
            step: App_extend_dune_project,
          }
        )
      }}
      onError
    />
    <App_files.Extend_dune_project
      state
      onComplete={updated_state => {
        set_state(_ =>
          {
            ...updated_state,
            step:
              configuration.has_tests
                ? Tests_copy_files : Compile_package_json,
          }
        )
      }}
      onError
    />
    {state.configuration.has_tests
       ? <>
           <Test_files.Copy_files
             state
             onComplete={() => {
               set_state(_ =>
                 {
                   ...state,
                   step: Tests_extend_package_json,
                 }
               )
             }}
             onError
           />
           <Test_files.Extend_package_json
             state
             onComplete={updated_state => {
               set_state(_ =>
                 {
                   ...updated_state,
                   step: Tests_extend_dune_project,
                 }
               )
             }}
             onError
           />
           <Test_files.Extend_dune_project
             state
             onComplete={updated_state => {
               set_state(_ =>
                 {
                   ...updated_state,
                   step: Compile_package_json,
                 }
               )
             }}
             onError
           />
         </>
       : React.null}
    <Compile.Compile_package_json
      state
      onComplete={updated_state => {
        set_state(_ =>
          {
            ...updated_state,
            step: Compile_dune_project,
          }
        )
      }}
      onError
    />
    <Compile.Compile_dune_project
      state
      onComplete={updated_state => {
        let next_step = Compile_root_dune_file;
        set_state(_ => {
          {
            ...updated_state,
            step: next_step,
          }
        });
      }}
      onError
    />
    <Compile.Compile_root_dune_file
      state
      onComplete={updated_state => {
        let next_step = Compile_app_dune_file;
        set_state(_ => {
          {
            ...updated_state,
            step: next_step,
          }
        });
      }}
      onError
    />
    <Compile.Compile_app_dune_file
      state
      onComplete={updated_state => {
        let next_step =
          configuration.has_tests
            ? Compile_test_dune_file : Compile_app_module;
        set_state(_ => {
          {
            ...updated_state,
            step: next_step,
          }
        });
      }}
      onError
    />
    {state.configuration.has_tests
       ? <>
           <Compile.Compile_test_dune_file
             state
             onComplete={updated_state => {
               let next_step = Compile_app_module;
               set_state(_ => {
                 {
                   ...updated_state,
                   step: next_step,
                 }
               });
             }}
             onError
           />
         </>
       : React.null}
    <Compile.Compile_app_module
      state
      onComplete={updated_state => {
        let next_step = Compile_readme;
        set_state(_ => {
          {
            ...updated_state,
            step: next_step,
          }
        });
      }}
      onError
    />
    <Compile.Compile_readme
      state
      onComplete={updated_state => {
        let next_step =
          switch (
            configuration.initialize_npm,
            configuration.initialize_git,
            configuration.initialize_ocaml_toolchain,
          ) {
          | (true, _, _) => Node_pkg_manager_install
          | (_, true, _) => Git_copy_ignore_file
          | (_, _, true) => Opam_update
          | _ => Finished
          };
        set_state(_ => {
          {
            ...updated_state,
            step: next_step,
          }
        });
      }}
      onError
    />
    <Node_pkg_manager_install
      state
      onComplete={() => {
        let next_step =
          switch (
            configuration.initialize_git,
            configuration.initialize_ocaml_toolchain,
          ) {
          | (_, true) => Opam_update
          | (true, false) => Git_copy_ignore_file
          | _ => Finished
          };

        set_state(_ => {
          {
            ...state,
            step: next_step,
          }
        });
      }}
      onError
    />
    <Opam.Update
      state
      onComplete={() => {
        set_state(_ =>
          {
            ...state,
            step: Opam_create_switch,
          }
        )
      }}
      onError
    />
    <Opam.Create_switch
      state
      onComplete={() => {
        set_state(_ =>
          {
            ...state,
            step: Opam_install_dune,
          }
        )
      }}
      onError
    />
    <Opam.Install_dune
      state
      onComplete={() => {
        set_state(_ =>
          {
            ...state,
            step: Dune_install,
          }
        )
      }}
      onError
    />
    <Dune_install
      state
      onComplete={() => {
        let next_step = Opam_install_dev_deps;
        set_state(_ =>
          {
            ...state,
            step: next_step,
          }
        );
      }}
      onError
    />
    <Opam.Install_dev_deps
      state
      onComplete={() => {
        set_state(_ =>
          {
            ...state,
            step: Opam_install_deps,
          }
        )
      }}
      onError
    />
    <Opam.Install_deps
      state
      onComplete={() => {
        set_state(_ =>
          {
            ...state,
            step: Dune_build,
          }
        )
      }}
      onError
    />
    <Dune_build
      state
      onComplete={() => {
        let next_step =
          configuration.initialize_git ? Git_copy_ignore_file : Finished;
        set_state(_ =>
          {
            ...state,
            step: next_step,
          }
        );
      }}
      onError
    />
    <Git.Copy_ignore_file
      state
      onComplete={() => {
        let next_step = Git_init_and_stage;

        set_state(_ =>
          {
            ...state,
            step: next_step,
          }
        );
      }}
      onError
    />
    <Git.Init_and_stage
      state
      onComplete={() => {
        set_state(_ =>
          {
            ...state,
            step: Finished,
          }
        )
      }}
      onError
    />
  </Box>;
};

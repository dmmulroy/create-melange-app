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

let res: Promise_result.t(string, int) =
  Js.Promise.make((~resolve, ~reject as _) => {resolve(. "hello")})
  |> Promise_result.of_js_promise;

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

module Progress_display = {
  [@react.component]
  let make =
      (
        ~displayFrom: step,
        ~displayTo: step,
        ~loadingLabel: string,
        ~successLabel: string,
        ~currentStep: step,
      ) => {
    let currentStepIndex = step_to_int(currentStep);

    if (currentStepIndex < step_to_int(displayFrom)) {
      React.null;
    } else if (currentStepIndex < step_to_int(displayTo)) {
      <Box flexDirection=`column gap=1>
        <Text color="cyan"> {React.string(loadingLabel)} </Text>
      </Box>;
    } else {
      <Box flexDirection=`column gap=1>
        <Text color="green"> {React.string(successLabel)} </Text>
      </Box>;
    };
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

  let to_string = Bundler.to_string;
  module Extend_package_json = {
    [@react.component]
    let make = (~state, ~onComplete: state => unit, ~onError as _) => {
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
        (),
      );
    };
  };
};

module App_files = {
  module Copy_files = {
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
  [@react.component]
  let make = (~state, ~onComplete, ~onError) => {
    let pkg_manager =
      Nodejs.Process.npm_config_user_agent
      |> Nodejs.Process.npm_user_agent_to_string;

    useStep(
      ~state,
      ~activeStep=Node_pkg_manager_install,
      ~action=
        Async(
          () =>
            state.configuration.directory |> Engine.node_pkg_manager_install,
        ),
      ~onComplete=_ => onComplete(),
      ~onError,
      ~loadingLabel={
        "Installing npm dependencies with " ++ pkg_manager;
      },
      ~successLabel=
        {j|✔ Successfully installed npm dependencies with |j} ++ pkg_manager,
      (),
    );
  };
};

module Git = {
  module Copy_ignore_file = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Git_copy_ignore_file,
        ~action=
          Async(
            () => state.configuration.directory |> Engine.copy_git_ignore,
          ),
        ~onComplete=_ => onComplete(),
        ~onError,
        (),
      );
  };

  module Init_and_stage = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Git_init_and_stage,
        ~action=
          Async(
            () => state.configuration.directory |> Engine.git_init_and_stage,
          ),
        ~onComplete=_ => onComplete(),
        ~onError,
        ~loadingLabel="Initializing git...",
        ~successLabel={j|✔ Successfully initialized git!|j},
        (),
      );
  };
};

module Opam = {
  module Update = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Opam_update,
        ~action=
          Async(() => state.configuration.directory |> Engine.opam_update),
        ~onComplete=_ => onComplete(),
        ~onError,
        ~loadingLabel=
          "Initializing OCaml toolchain, this may take a few minutes...",
        (),
      );
  };

  module Install_dune = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Opam_install_dune,
        ~action=
          Async(
            () => state.configuration.directory |> Engine.opam_install_dune,
          ),
        ~onComplete=_ => onComplete(),
        ~onError,
        ~loadingLabel=
          "Initializing OCaml toolchain, this may take a few minutes...",
        (),
      );
  };

  module Create_switch = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Opam_create_switch,
        ~action=
          Async(
            () => state.configuration.directory |> Engine.opam_create_switch,
          ),
        ~onComplete=_ => onComplete(),
        ~onError,
        ~loadingLabel=
          "Initializing OCaml toolchain, this may take a few minutes...",
        (),
      );
  };

  module Install_dev_deps = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Opam_install_dev_deps,
        ~action=
          Async(
            () =>
              state.configuration.directory
              |> Engine.opam_install_dev_dependencies,
          ),
        ~onComplete=_ => onComplete(),
        ~onError,
        ~loadingLabel=
          "Initializing OCaml toolchain, this may take a few minutes...",
        (),
      );
  };

  module Install_deps = {
    [@react.component]
    let make = (~state, ~onComplete, ~onError) =>
      useStep(
        ~state,
        ~activeStep=Opam_install_deps,
        ~action=
          Async(
            () =>
              state.configuration.directory |> Engine.opam_install_dependencies,
          ),
        ~onComplete=_ => onComplete(),
        ~onError,
        ~loadingLabel=
          "Initializing OCaml toolchain, this may take a few minutes...",
        (),
      );
  };
};

module Dune_install = {
  [@react.component]
  let make = (~state, ~onComplete, ~onError) =>
    useStep(
      ~state,
      ~activeStep=Dune_install,
      ~action=
        Async(() => state.configuration.directory |> Engine.dune_install),
      ~onComplete=_ => onComplete(),
      ~onError,
      ~loadingLabel=
        "Initializing OCaml toolchain, this may take a few minutes...",
      (),
    );
};

module Dune_build = {
  [@react.component]
  let make = (~state, ~onComplete, ~onError) =>
    useStep(
      ~state,
      ~activeStep=Dune_build,
      ~action=Async(() => state.configuration.directory |> Engine.dune_build),
      ~onComplete=_ => onComplete(),
      ~onError,
      ~loadingLabel=
        "Initializing OCaml toolchain, this may take a few minutes...",
      ~successLabel={j|✔ Successfully intialized the OCaml toolchain!|j},
      (),
    );
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

  let goToNextStep = (step, ()) =>
    set_state(state =>
      {
        ...state,
        step,
      }
    );

  let goToNextStepWithNewState = (step, newState) =>
    set_state(_ =>
      {
        ...newState,
        step,
      }
    );

  <Box flexDirection=`column gap=1>
    <Text color="cyan"> {React.string("Scaffolding project...")} </Text>
    <Progress_display
      displayFrom=Create_dir
      displayTo=Bundler_copy_files
      loadingLabel="Creating base project..."
      successLabel="Successfully created base project!"
      currentStep={state.step}
    />
    <Create_dir
      state
      onComplete={goToNextStep(Copy_base_templates)}
      onError
    />
    // Creating base project
    <Copy_base_templates
      state
      onComplete={goToNextStep(Bundler_copy_files)}
      onError
    />
    {let bundler_name =
       state.configuration.bundler
       |> Bundler.to_string
       |> String.capitalize_ascii;
     <Progress_display
       displayFrom=Bundler_copy_files
       displayTo=App_copy_files
       loadingLabel={"Initializing bundler: " ++ bundler_name ++ "..."}
       successLabel={
         {j|✔ Successfully initialized bundler: |j} ++ bundler_name
       }
       currentStep={state.step}
     />}
    <Bundler.Copy_files
      state
      onComplete={goToNextStep(Bundler_extend_package_json)}
      onError
    />
    <Bundler.Extend_package_json
      state
      onComplete={goToNextStepWithNewState(App_copy_files)}
      onError
    />
    <Progress_display
      displayFrom=App_copy_files
      displayTo=App_extend_package_json
      loadingLabel="Copying application files..."
      successLabel={j|✔ Successfully copied application files!|j}
      currentStep={state.step}
    />
    <App_files.Copy_files
      state
      onComplete={goToNextStep(App_extend_package_json)}
      onError
    />
    <App_files.Extend_package_json
      state
      onComplete={goToNextStepWithNewState(App_extend_dune_project)}
      onError
    />
    // Initializing application files
    <App_files.Extend_dune_project
      state
      onComplete={goToNextStepWithNewState(
        configuration.has_tests ? Tests_copy_files : Compile_package_json,
      )}
      onError
    />
    <Progress_display
      displayFrom=Tests_copy_files
      displayTo=Tests_extend_dune_project
      loadingLabel="Copying test files..."
      successLabel={j|✔ Successfully copied test files!|j}
      currentStep={state.step}
    />
    <Test_files.Copy_files
      state
      onComplete={goToNextStep(Tests_extend_package_json)}
      onError
    />
    <Test_files.Extend_package_json
      state
      onComplete={goToNextStepWithNewState(Tests_extend_dune_project)}
      onError
    />
    // Initializing test files
    <Test_files.Extend_dune_project
      state
      onComplete={goToNextStepWithNewState(Compile_package_json)}
      onError
    />
    <Progress_display
      displayFrom=Compile_package_json
      displayTo=Compile_readme
      loadingLabel="Compiling templates..."
      successLabel={j|✔ Successfully compiled templates!|j}
      currentStep={state.step}
    />
    <Compile.Compile_package_json
      state
      onComplete={goToNextStepWithNewState(Compile_dune_project)}
      onError
    />
    <Compile.Compile_dune_project
      state
      onComplete={goToNextStepWithNewState(Compile_root_dune_file)}
      onError
    />
    <Compile.Compile_root_dune_file
      state
      onComplete={goToNextStepWithNewState(Compile_app_dune_file)}
      onError
    />
    <Compile.Compile_app_dune_file
      state
      onComplete={goToNextStepWithNewState(
        configuration.has_tests ? Compile_test_dune_file : Compile_app_module,
      )}
      onError
    />
    <Compile.Compile_test_dune_file
      state
      onComplete={goToNextStepWithNewState(Compile_app_module)}
      onError
    />
    <Compile.Compile_app_module
      state
      onComplete={goToNextStepWithNewState(Compile_readme)}
      onError
    />
    // Successfully compiled templates
    <Compile.Compile_readme
      state
      onComplete={goToNextStepWithNewState(
        switch (
          configuration.initialize_npm,
          configuration.initialize_git,
          configuration.initialize_ocaml_toolchain,
        ) {
        | (true, _, _) => Node_pkg_manager_install
        | (_, true, _) => Git_copy_ignore_file
        | (_, _, true) => Opam_update
        | _ => Finished
        },
      )}
      onError
    />
    {let pkg_manager =
       Nodejs.Process.npm_config_user_agent
       |> Nodejs.Process.npm_user_agent_to_string;
     <Progress_display
       displayFrom=Node_pkg_manager_install
       displayTo=Opam_update
       loadingLabel={"Installing npm dependencies with " ++ pkg_manager}
       successLabel={
         {j|✔ Successfully installed npm dependencies with |j} ++ pkg_manager
       }
       currentStep={state.step}
     />}
    <Node_pkg_manager_install
      state
      onComplete={goToNextStep(
        switch (
          configuration.initialize_git,
          configuration.initialize_ocaml_toolchain,
        ) {
        | (_, true) => Opam_update
        | (true, false) => Git_copy_ignore_file
        | _ => Finished
        },
      )}
      onError
    />
    <Progress_display
      displayFrom=Opam_update
      displayTo=Git_init_and_stage
      loadingLabel="Initializing OCaml toolchain, this may take a few minutes..."
      successLabel={j|✔ Successfully initialized OCaml toolchain!|j}
      currentStep={state.step}
    />
    <Opam.Update
      state
      onComplete={goToNextStep(Opam_create_switch)}
      onError
    />
    <Opam.Create_switch
      state
      onComplete={goToNextStep(Opam_install_dune)}
      onError
    />
    <Opam.Install_dune
      state
      onComplete={goToNextStep(Dune_install)}
      onError
    />
    <Dune_install
      state
      onComplete={goToNextStep(Opam_install_dev_deps)}
      onError
    />
    <Opam.Install_dev_deps
      state
      onComplete={goToNextStep(Opam_install_deps)}
      onError
    />
    <Opam.Install_deps state onComplete={goToNextStep(Dune_build)} onError />
    <Dune_build
      state
      onComplete={goToNextStep(
        configuration.initialize_git ? Git_copy_ignore_file : Finished,
      )}
      onError
    />
    <Git.Copy_ignore_file
      state
      onComplete={goToNextStep(Git_init_and_stage)}
      onError
    />
    <Git.Init_and_stage state onComplete={goToNextStep(Finished)} onError />
  </Box>;
};

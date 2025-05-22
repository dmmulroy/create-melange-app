open Bindings;
open Ink;
open Core;

type step =
  // Section 1 - Create project directory and base project files
  | Create_base_project
  // Setting 2 - Initialize bundler
  | Initialize_bundler
  // Section 3 - Initialize app files
  | Initialize_app_files
  // Section 4 - Initialize test files
  | Initialize_test_files
  // Section 5 - Compile templates
  | Compile_templates
  // Section 6 - Optional - Initialize node package manager
  | Node_pkg_manager_install
  // Section 7 - Optional - Initialize OCaml toolchain
  | Opam_update
  | Opam_create_switch
  | Opam_install_dune
  | Dune_install
  | Opam_install_dev_deps
  | Opam_install_deps
  | Dune_build
  // Section 8 - Optional - Initialize git
  | Initialize_git
  // Section 9 - Finished
  | Finished;

let step_to_int = step =>
  switch (step) {
  | Create_base_project => 0
  | Initialize_bundler => 1
  | Initialize_app_files => 2
  | Initialize_test_files => 3
  | Compile_templates => 4
  | Node_pkg_manager_install => 5
  | Opam_update => 6
  | Opam_create_switch => 7
  | Opam_install_dune => 8
  | Dune_install => 9
  | Opam_install_dev_deps => 10
  | Opam_install_deps => 11
  | Dune_build => 12
  | Initialize_git => 13
  | Finished => 14
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

module Progress_display = {
  [@react.component]
  let make =
      (
        ~startStep: step,
        ~currentStep: step,
        ~loadingLabel: string,
        ~successLabel: string,
        ~fn: unit => Promise_result.t('a, 'b),
        ~onComplete: 'a => unit,
        ~onError: 'b => unit,
        ~skip=false,
        ~onSkip=() => (),
      ) => {
    let (isLoading, setIsLoading) = React.useState(() => false);
    let currentStepIndex = step_to_int(currentStep);
    let isCurrentStep = currentStep == startStep;

    let fnRef = React.useRef(fn);
    fnRef.current = fn;

    let onSkipRef = React.useRef(onSkip);
    onSkipRef.current = onSkip;

    React.useEffect1(
      () => {
        if (isCurrentStep) {
          if (skip) {
            onSkipRef.current();
          } else {
            setIsLoading(_ => true);
            fnRef.current()
            |> Promise_result.perform(result => {
                 setIsLoading(_ => false);
                 switch (result) {
                 | Ok(res) => onComplete(res)
                 | Error(err) => onError(err)
                 };
               });
          };
        };
        None;
      },
      [|isCurrentStep|],
    );

    if (currentStepIndex < step_to_int(startStep) || skip) {
      React.null;
    } else if (isLoading) {
      <Box flexDirection=`column gap=1>
        <Ui.Spinner label=loadingLabel />
      </Box>;
    } else {
      <Box flexDirection=`column gap=1>
        <Text color="green"> {React.string(successLabel)} </Text>
      </Box>;
    };
  };
};

module Base_project = {
  module Create_dir = {
    let fn = state =>
      state.configuration.directory
      |> Engine.create_project_directory(
           ~overwrite=?state.configuration.overwrite,
         );
  };

  module Copy_base_templates = {
    let fn = state =>
      state.configuration.directory |> Engine.copy_base_project;
  };

  let createBaseProject = state =>
    state
    ->Create_dir.fn
    ->Promise_result.bind(() => Copy_base_templates.fn(state));
};

module Bundler = {
  let to_string = Bundler.to_string;

  module Copy_files = {
    let fn = state =>
      state.configuration.directory
      |> Engine.copy_bundler_files(
           ~bundler=state.configuration.bundler,
           ~is_react_app=state.configuration.is_react_app,
         );
  };

  module Extend_package_json = {
    let fn = state =>
      state.pkg_json
      |> Engine.extend_package_json_with_bundler(
           ~bundler=state.configuration.bundler,
           ~project_name=state.configuration.name,
         );
  };

  let initializeBundler = state =>
    state->Copy_files.fn
    |> Promise_result.map(() =>
         {
           ...state,
           pkg_json: Extend_package_json.fn(state),
         }
       );
};

module App_files = {
  module Copy_files = {
    let fn = state =>
      state.configuration.directory
      |> Engine.copy_app_files(
           ~syntax_preference=state.configuration.syntax_preference,
           ~is_react_app=state.configuration.is_react_app,
         );
  };

  module Extend_package_json = {
    let fn = state =>
      state.pkg_json
      |> Engine.extend_package_json_with_app_settings(
           ~is_react_app=state.configuration.is_react_app,
         );
  };

  module Extend_dune_project = {
    let fn = state =>
      state.dune_project
      |> Engine.extend_dune_project_with_app_settings(
           ~is_react_app=state.configuration.is_react_app,
           ~syntax_preference=state.configuration.syntax_preference,
           ~project_name=state.configuration.name,
         );
  };

  let copyApplicationFiles = state =>
    state->Copy_files.fn
    |> Promise_result.map(() =>
         {
           ...state,
           pkg_json: Extend_package_json.fn(state),
         }
       );
};

module Test_files = {
  module Copy_files = {
    let fn = state =>
      state.configuration.directory
      |> Engine.copy_test_files(
           ~syntax_preference=state.configuration.syntax_preference,
           ~is_react_app=state.configuration.is_react_app,
         );
  };

  module Extend_package_json = {
    let fn = state =>
      state.pkg_json
      |> Engine.extend_package_json_with_tests(
           ~is_react_app=state.configuration.is_react_app,
           ~project_name=state.configuration.name,
         );
  };

  module Extend_dune_project = {
    let fn = state =>
      state.dune_project
      |> Engine.extend_dune_project_with_tests(
           ~is_react_app=state.configuration.is_react_app,
           ~project_name=state.configuration.name,
         );
  };

  let initilizeTestFiles = state =>
    Copy_files.fn(state)
    |> Promise_result.map(() =>
         {
           ...state,
           pkg_json: Extend_package_json.fn(state),
         }
       )
    |> Promise_result.map(state =>
         {
           ...state,
           dune_project: Extend_dune_project.fn(state),
         }
       );
};

module Compile = {
  module Compile_package_json = {
    let fn = state => state.pkg_json |> Engine.compile;
  };

  module Compile_dune_project = {
    let fn = state => state.dune_project |> Engine.compile;
  };

  module Compile_root_dune_file = {
    let fn = state => state.root_dune_file |> Engine.compile;
  };

  module Compile_app_dune_file = {
    let fn = state => state.app_dune_file |> Engine.compile;
  };

  module Compile_test_dune_file = {
    let fn = state => state.test_dune_file |> Engine.compile;
  };

  module Compile_app_module = {
    let fn = state => state.app_module |> Engine.compile;
  };

  module Compile_readme = {
    let fn = state => state.readme |> Engine.compile;
  };

  let compile = state => {
    open Promise_result.Syntax.Let;

    let+ pkg_json = Compile_package_json.fn(state);
    let+ dune_project = Compile_dune_project.fn(state);
    let+ root_dune_file = Compile_root_dune_file.fn(state);
    let+ app_dune_file = Compile_app_dune_file.fn(state);
    let+ test_dune_file = Compile_test_dune_file.fn(state);
    let+ app_module = Compile_app_module.fn(state);
    let+ readme = Compile_readme.fn(state);

    Promise_result.resolve_ok({
      ...state,
      pkg_json,
      dune_project,
      root_dune_file,
      app_dune_file,
      test_dune_file,
      app_module,
      readme,
    });
  };
};

module Node_pkg_manager_install = {
  let fn = state =>
    state.configuration.directory |> Engine.node_pkg_manager_install;
};

module Git = {
  module Copy_ignore_file = {
    let fn = state => state.configuration.directory |> Engine.copy_git_ignore;
  };

  module Init_and_stage = {
    let fn = state =>
      state.configuration.directory |> Engine.git_init_and_stage;
  };

  let initilizeGit = state =>
    Copy_ignore_file.fn(state)
    ->Promise_result.bind(() => Init_and_stage.fn(state));
};

module Opam = {
  module Update = {
    let fn = state => state.configuration.directory |> Engine.opam_update;
  };

  module Install_dune = {
    let fn = state =>
      state.configuration.directory |> Engine.opam_install_dune;
  };

  module Create_switch = {
    let fn = state =>
      state.configuration.directory |> Engine.opam_create_switch;
  };

  module Install_dev_deps = {
    let fn = state =>
      state.configuration.directory |> Engine.opam_install_dev_dependencies;
  };

  module Install_deps = {
    let fn = state =>
      state.configuration.directory |> Engine.opam_install_dependencies;
  };
};

module Dune_install = {
  let fn = state => state.configuration.directory |> Engine.dune_install;
};

module Dune_build = {
  let fn = state => state.configuration.directory |> Engine.dune_build;
};

[@react.component]
let make = (~configuration: Configuration.t, ~onComplete) => {
  let (state, set_state) =
    React.useState(_ =>
      {
        configuration,
        step: Create_base_project,
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
      startStep=Create_base_project
      currentStep={state.step}
      loadingLabel="Creating base project..."
      successLabel="Successfully created base project!"
      onComplete={goToNextStep(Initialize_bundler)}
      onError
      fn={() => Base_project.createBaseProject(state)}
    />
    {let bundler_name =
       state.configuration.bundler
       |> Bundler.to_string
       |> String.capitalize_ascii;
     <Progress_display
       startStep=Initialize_bundler
       currentStep={state.step}
       loadingLabel={"Initializing bundler: " ++ bundler_name ++ "..."}
       successLabel={
         {j|✔ Successfully initialized bundler: |j} ++ bundler_name
       }
       onComplete={goToNextStepWithNewState(Initialize_app_files)}
       onError
       fn={() => Bundler.initializeBundler(state)}
     />}
    <Progress_display
      startStep=Initialize_app_files
      currentStep={state.step}
      loadingLabel="Copying application files..."
      successLabel={j|✔ Successfully copied application files!|j}
      onComplete={goToNextStepWithNewState(
        configuration.has_tests ? Initialize_test_files : Compile_templates,
      )}
      onError
      fn={() => App_files.copyApplicationFiles(state)}
    />
    <Progress_display
      startStep=Initialize_test_files
      loadingLabel="Copying test files"
      successLabel={j|✔ Successfully copied test files!|j}
      currentStep={state.step}
      onComplete={goToNextStepWithNewState(Compile_templates)}
      onError
      fn={() => Test_files.initilizeTestFiles(state)}
    />
    <Progress_display
      startStep=Compile_templates
      loadingLabel="Compiling templates..."
      successLabel={j|✔ Successfully compiled templates!|j}
      currentStep={state.step}
      onComplete={goToNextStepWithNewState(Node_pkg_manager_install)}
      onError
      fn={() => Compile.compile(state)}
    />
    {let pkg_manager =
       Nodejs.Process.npm_config_user_agent
       |> Nodejs.Process.npm_user_agent_to_string;
     <Progress_display
       startStep=Node_pkg_manager_install
       currentStep={state.step}
       loadingLabel={"Installing npm dependencies with " ++ pkg_manager}
       successLabel={
         {j|✔ Successfully installed npm dependencies with |j} ++ pkg_manager
       }
       onComplete={_ => goToNextStep(Opam_update, ())}
       onError
       fn={() => Node_pkg_manager_install.fn(state)}
       skip={!state.configuration.initialize_npm}
       onSkip={() => goToNextStep(Opam_update, ())}
     />}
    <Progress_display
      startStep=Opam_update
      currentStep={state.step}
      loadingLabel="Initializing OCaml toolchain, this may take a few minutes... Step 1/7 (Updating opam)"
      successLabel={j|✔ Successfully updated opam!|j}
      onComplete={_ => goToNextStep(Opam_create_switch, ())}
      onError
      skip={!state.configuration.initialize_ocaml_toolchain}
      onSkip={goToNextStep(Initialize_git)}
      fn={() => Opam.Update.fn(state)}
    />
    <Progress_display
      startStep=Opam_create_switch
      currentStep={state.step}
      loadingLabel="Initializing OCaml toolchain, this may take a few minutes... Step 2/7 (Creating opam switch)"
      successLabel={j|✔ Successfully created opam switch!|j}
      onComplete={_ => goToNextStep(Opam_install_dune, ())}
      onError
      skip={!state.configuration.initialize_ocaml_toolchain}
      fn={() => Opam.Create_switch.fn(state)}
    />
    <Progress_display
      startStep=Opam_install_dune
      currentStep={state.step}
      loadingLabel="Initializing OCaml toolchain, this may take a few minutes... Step 3/7 (Installing dune)"
      successLabel={j|✔ Successfully installed dune!|j}
      onComplete={_ => goToNextStep(Dune_install, ())}
      onError
      skip={!state.configuration.initialize_ocaml_toolchain}
      fn={() => Opam.Install_dune.fn(state)}
    />
    <Progress_display
      startStep=Dune_install
      currentStep={state.step}
      loadingLabel="Initializing OCaml toolchain, this may take a few minutes... Step 4/7 (Running dune install)"
      successLabel={j|✔ Successfully installed dependencies!|j}
      onComplete={_ => goToNextStep(Opam_install_dev_deps, ())}
      onError
      skip={!state.configuration.initialize_ocaml_toolchain}
      fn={() => Dune_install.fn(state)}
    />
    <Progress_display
      startStep=Opam_install_dev_deps
      currentStep={state.step}
      loadingLabel="Initializing OCaml toolchain, this may take a few minutes... Step 5/7 (Installing dev dependencies)"
      successLabel={j|✔ Successfully installed dev dependencies!|j}
      onComplete={_ => goToNextStep(Opam_install_deps, ())}
      onError
      skip={!state.configuration.initialize_ocaml_toolchain}
      fn={() => Opam.Install_dev_deps.fn(state)}
    />
    <Progress_display
      startStep=Opam_install_deps
      currentStep={state.step}
      loadingLabel="Initializing OCaml toolchain, this may take a few minutes... Step 6/7 (Installing dune)"
      successLabel={j|✔ Successfully installed dune!|j}
      onComplete={_ => goToNextStep(Dune_build, ())}
      onError
      skip={!state.configuration.initialize_ocaml_toolchain}
      fn={() => Opam.Install_deps.fn(state)}
    />
    <Progress_display
      startStep=Dune_build
      currentStep={state.step}
      loadingLabel="Initializing OCaml toolchain, this may take a few minutes... Step 7/7 (Building project)"
      successLabel={j|✔ Successfully built project!|j}
      onComplete={_ =>
        goToNextStep(
          configuration.initialize_git ? Initialize_git : Finished,
          (),
        )
      }
      onError
      skip={!state.configuration.initialize_ocaml_toolchain}
      fn={() => Dune_build.fn(state)}
    />
    <Progress_display
      startStep=Initialize_git
      currentStep={state.step}
      loadingLabel="Initializing git..."
      successLabel={j|✔ Successfully initialized git!|j}
      onComplete={_ => goToNextStep(Finished, ())}
      onError
      fn={() => Git.initilizeGit(state)}
      skip={!state.configuration.initialize_git}
      onSkip={goToNextStep(Finished)}
    />
  </Box>;
};

open Bindings;
open Ink;

open Core;

let ( let* ) = Promise_result.bind;
let (let+) = Promise_result.map;

// For Minttea rewrite:
// This file is a great example of do as I say not as I do. It's a mess and
// I just brute forced it to work w/ lots of copy/paste. I think a better way
// to have done this would have been to create functor to create the steps
type step =
  // Section 1 - Create project directory
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
  | Git_copy_ignore_file => 13
  | Git_init_and_stage => 14
  | Finished => 15
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
    (~state, ~activeStep: step, ~action, ~onComplete, ~onError=_ => (), ()) => {
  // let (complete, set_complete) = React.useState(() => false);
  let is_active = state.step == activeStep;
  // let is_visible = step_to_int(state.step) >= step_to_int(activeStep);

  React.useEffect1(
    () => {
      if (is_active) {
        switch (action) {
        | Sync(fn) =>
          let result = fn();
          // TODO: Handle errors
          // set_complete(_ => true);
          onComplete(result);
        | Async(fn) =>
          fn()
          |> Promise_result.perform(result =>
               switch (result) {
               | Ok(res) =>
                 //  set_complete(_ => true);
                 onComplete(res)
               | Error(err) => onError(err)
               }
             )
        };
      };
      None;
    },
    [|is_active|],
  );

  React.null;
  // if (!is_visible) {
  //   React.null;
  // } else {
  //   <Box flexDirection=`column gap=1>
  //     {complete
  //        ? <Box flexDirection=`row gap=1>
  //            <Text color="green"> {React.string(successLabel)} </Text>
  //          </Box>
  //        : <Spinner label=loadingLabel />}
  //   </Box>;
  // };
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
      <Ui.Spinner label=loadingLabel />;
    } else {
      <Box flexDirection=`column gap=1>
        <Text color="green"> {React.string(successLabel)} </Text>
      </Box>;
    };
  };
};

module Progress_display2 = {
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
      ) => {
    let (isLoading, setIsLoading) = React.useState(() => false);
    let currentStepIndex = step_to_int(currentStep);
    let isCurrentStep = currentStep == startStep;

    let fnRef = React.useRef(fn);
    fnRef.current = fn;

    React.useEffect1(
      () => {
        if (isCurrentStep) {
          fnRef.current()
          |> Promise_result.perform(result => {
               setIsLoading(_ => false);
               switch (result) {
               | Ok(res) => onComplete(res)
               | Error(err) => onError(err)
               };
             });
        };
        None;
      },
      [|isCurrentStep|],
    );

    if (currentStepIndex < step_to_int(startStep)) {
      React.null;
    } else if (isLoading) {
      <Ui.Spinner label=loadingLabel />;
    } else {
      <Box flexDirection=`column gap=1>
        <Text color="green"> {React.string(successLabel)} </Text>
      </Box>;
    };
  };
};

module Create_dir = {
  let fn = state =>
    state.configuration.directory
    |> Engine.create_project_directory(
         ~overwrite=?state.configuration.overwrite,
       );
  // [@react.component]
  // let make = (~state, ~onComplete, ~onError) =>
  //   useStep(
  //     ~state,
  //     ~activeStep=Create_dir,
  //     ~action=Async(() => fn(state)),
  //     ~onComplete,
  //     ~onError,
  //     (),
  //   );
};

module Copy_base_templates = {
  let fn = state => state.configuration.directory |> Engine.copy_base_project;
  // [@react.component]
  // let make = (~state, ~onComplete, ~onError) => {
  //   useStep(
  //     ~state,
  //     ~activeStep=Copy_base_templates,
  //     ~action=Async(() => fn(state)),
  //     ~onComplete,
  //     ~onError,
  //     (),
  //   );
  // };
};

module Bundler = {
  module Copy_files = {
    let fn = state =>
      state.configuration.directory
      |> Engine.copy_bundler_files(
           ~bundler=state.configuration.bundler,
           ~is_react_app=state.configuration.is_react_app,
         );
  };

  let to_string = Bundler.to_string;
  module Extend_package_json = {
    let fn = state =>
      state.pkg_json
      |> Engine.extend_package_json_with_bundler(
           ~bundler=state.configuration.bundler,
           ~project_name=state.configuration.name,
         );
  };
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
    let* pkg_json = Compile_package_json.fn(state);
    let* dune_project = Compile_dune_project.fn(state);
    let* root_dune_file = Compile_root_dune_file.fn(state);
    let* app_dune_file = Compile_app_dune_file.fn(state);
    let* test_dune_file = Compile_test_dune_file.fn(state);
    let* app_module = Compile_app_module.fn(state);
    let* readme = Compile_readme.fn(state);

    Promise.resolve(
      Ok({
        ...state,
        pkg_json,
        dune_project,
        root_dune_file,
        app_dune_file,
        test_dune_file,
        app_module,
        readme,
      }),
    );
  };
};

module Node_pkg_manager_install = {
  [@react.component]
  let make = (~state, ~onComplete, ~onError) => {
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
      (),
    );
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
      err => {
        Js.Console.log2("err", err);
        onComplete(Result.error(err));
      },
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

  let bind = Promise_result.bind;
  let map = Promise_result.map;

  let createBaseProject = state =>
    state->Create_dir.fn->bind(() => Copy_base_templates.fn(state));

  let initializeBundler = state =>
    state->Bundler.Copy_files.fn
    |> map(() =>
         {
           ...state,
           pkg_json: Bundler.Extend_package_json.fn(state),
         }
       );

  let copyApplicationFiles = state =>
    state->App_files.Copy_files.fn
    |> map(() =>
         {
           ...state,
           pkg_json: App_files.Extend_package_json.fn(state),
         }
       );

  let el =
    <Box flexDirection=`column gap=1>
      <Text color="cyan"> {React.string("Scaffolding project...")} </Text>
      <Progress_display2
        startStep=Create_base_project
        currentStep={state.step}
        loadingLabel="Creating base project..."
        successLabel="Successfully created base project!"
        onComplete={goToNextStep(Initialize_bundler)}
        onError
        fn={() => createBaseProject(state)}
      />
      {let bundler_name =
         state.configuration.bundler
         |> Bundler.to_string
         |> String.capitalize_ascii;
       <Progress_display2
         startStep=Initialize_bundler
         currentStep={state.step}
         loadingLabel={"Initializing bundler: " ++ bundler_name ++ "..."}
         successLabel={
           {j|✔ Successfully initialized bundler: |j} ++ bundler_name
         }
         onComplete={goToNextStepWithNewState(Initialize_app_files)}
         onError
         fn={() => initializeBundler(state)}
       />}
      <Progress_display2
        startStep=Initialize_app_files
        loadingLabel="Copying application files..."
        successLabel={j|✔ Successfully copied application files!|j}
        currentStep={state.step}
        onComplete={goToNextStepWithNewState(
          configuration.has_tests ? Initialize_test_files : Compile_templates,
        )}
        onError
        fn={() => copyApplicationFiles(state)}
      />
      <Progress_display2
        startStep=Initialize_test_files
        loadingLabel="Copying test files"
        successLabel={j|✔ Successfully copied test files!|j}
        currentStep={state.step}
        onComplete={goToNextStepWithNewState(Compile_templates)}
        onError
        fn={() => Test_files.initilizeTestFiles(state)}
      />
      <Progress_display2
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
         displayFrom=Node_pkg_manager_install
         displayTo=Opam_update
         loadingLabel={"Installing npm dependencies with " ++ pkg_manager}
         successLabel={
           {j|✔ Successfully installed npm dependencies with |j}
           ++ pkg_manager
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
      <Opam.Install_deps
        state
        onComplete={goToNextStep(Dune_build)}
        onError
      />
      <Dune_build
        state
        onComplete={goToNextStep(
          configuration.initialize_git ? Git_copy_ignore_file : Finished,
        )}
        onError
      />
      <Progress_display
        displayFrom=Git_copy_ignore_file
        displayTo=Finished
        loadingLabel="Initializing git..."
        successLabel={j|✔ Successfully initialized git!|j}
        currentStep={state.step}
      />
      <Git.Copy_ignore_file
        state
        onComplete={goToNextStep(Git_init_and_stage)}
        onError
      />
      <Git.Init_and_stage state onComplete={goToNextStep(Finished)} onError />
    </Box>;
  el;
};

[@ocaml.warning "-27-26"];
open Bindings;
open Core;
open Ink;
open Common;
module Scaffold = Scaffold;

let items: array(unit) = [|()|];

let next_steps = (configuration: Configuration.t) => {
  let node_pkg_manager_str =
    configuration.node_package_manager
    |> Nodejs.Process.npm_user_agent_to_string;

  let node_pkg_manager_install_str =
    if (configuration.initialize_npm) {
      "";
    } else {
      node_pkg_manager_str
      |> (
        pkg_manager =>
          if (pkg_manager == "  yarn\n") {
            pkg_manager;
          } else {
            "  " ++ pkg_manager ++ " install\n";
          }
      );
    };

  let directory =
    switch (configuration.directory) {
    | "." => ""
    | directory => Format.sprintf("  cd %s\n", configuration.name)
    };

  let node_pkg_manager_install =
    configuration.initialize_npm
      ? "" : Format.sprintf("  %s\n", node_pkg_manager_install_str);

  let ocaml_toolchain_init =
    configuration.initialize_ocaml_toolchain
      ? ""
      : Format.sprintf(
          "  %s\n  %s\n  %s\n",
          Opam.Create_switch.name,
          Opam.Install_dev_dependencies.name,
          Dune.Build.name,
        );

  let git_init = configuration.initialize_git ? "" : "  git init\n";

  let git_commit = "  git commit -m \"initial commit\"\n";

  let run_app = Format.sprintf("  %s run dev", node_pkg_manager_str);

  {j|Next steps:\n$directory$node_pkg_manager_install_str$ocaml_toolchain_init$git_init$git_commit$run_app\n|j};
};

module Next_steps = {
  [@react.component]
  let make = (~configuration: Configuration.t) => {
    let next_steps = configuration |> next_steps |> React.string;

    <Box flexDirection=`column> <Text color="cyan"> next_steps </Text> </Box>;
  };
};

[@react.component]
let make = (~name as initial_name) => {
  let (is_active, set_is_active) = React.useState(() => Some(true));
  let (env_check_result: option([ | `Pass | `Fail]), set_env_check_result) =
    React.useState(() => None);
  let (should_prompt_git, set_should_prompt_git) =
    React.useState(() => false);
  let (configuration, set_configuration) =
    React.useState(() => (None: option(Core.Configuration.t)));
  let (scaffold_result, set_scaffold_result) =
    React.useState(() => (None: option(result(unit, string))));

  let parsed_name_and_dir =
    React.useMemo1(
      () => Option.map(Core.Fs.parse_project_name_and_dir, initial_name),
      [|initial_name|],
    );

  let initial_name_is_valid =
    React.useMemo1(
      () =>
        parsed_name_and_dir
        |> Option.map(fst)
        |> Option.map(Core.Validation.Project_name.validate),
      [|parsed_name_and_dir|],
    );

  let on_env_check =
    React.useCallback0(result => {
      switch (result) {
      | `Pass(results) =>
        Js.Global.setTimeout(
          () => set_env_check_result(_ => Some(`Pass)),
          850,
        )
        |> ignore;

        let should_prompt_git =
          List.exists(
            result => {
              switch (result) {
              | `Fail(_) => true
              | `Pass(module Dep: Core.Dependency.S) =>
                Dep.name == "Git" ? true : false
              }
            },
            results,
          );

        set_should_prompt_git(_ => should_prompt_git);
        ();
      | `Fail(_) =>
        set_env_check_result(_ => Some(`Fail));
        set_is_active(_ => Some(false));
      }
    });

  let on_complete_wizard =
    React.useCallback0(configuration => {
      Js.Global.setTimeout(
        () => set_configuration(_ => Some(configuration)),
        850,
      )
      |> ignore
    });

  let on_complete_scaffold =
    React.useCallback0(scaffold_result => {
      Js.Global.setTimeout(
        () => set_scaffold_result(_ => Some(scaffold_result)),
        850,
      )
      |> ignore
    });

  React.useEffect1(
    () => {
      let _ =
        switch (scaffold_result) {
        | None => ()
        | Some(_) => set_is_active(_ => Some(false))
        };

      None;
    },
    [|scaffold_result|],
  );

  Ink.Hooks.use_input(
    (~input as _input, ~key as _key) => (),
    ~options={is_active: is_active},
  );

  let initial_configuration =
    React.useMemo1(
      () =>
        Core.Configuration.make_partial(
          ~name=?Option.map(fst, parsed_name_and_dir),
          ~directory=?Option.map(snd, parsed_name_and_dir),
          (),
        ),
      [|parsed_name_and_dir|],
    );

  <>
    <Banner />
    <Box flexDirection=`column gap=1>
      {switch (initial_name_is_valid) {
       | Some(Error(`Msg(error))) =>
         <Ui.Badge color=`red> {React.string(error)} </Ui.Badge>
       | _ =>
         switch (env_check_result, configuration, scaffold_result) {
         | (None, _, _) => <Env_check.Component onEnvCheck=on_env_check />
         | (Some(`Pass), None, _) =>
           <Wizard
             initial_configuration
             onComplete=on_complete_wizard
             should_prompt_git
           />
         | (Some(`Pass), Some(configuration), None) =>
           <Scaffold configuration onComplete=on_complete_scaffold />
         | (Some(`Pass), Some(configuration), Some(Error(msg))) =>
           <Ui.Badge color=`red> {React.string(msg)} </Ui.Badge>
         | (Some(`Pass), Some(configuration), Some(Ok(_))) =>
           <>
             <Text color="green">
               {React.string({j|✔ |j})}
               <Text color="cyan" bold=true>
                 {React.string(configuration.name)}
               </Text>
               {React.string(" scaffolded successfully!")}
             </Text>
             <Next_steps configuration />
             <Text color="cyan">
               {React.string("Visit the Melange docs at: ")}
               <Link url="https://melange.re" fallback=false>
                 <Text bold=true> {React.string("https://melange.re")} </Text>
               </Link>
             </Text>
           </>
         | _ => React.null
         }
       }}
    </Box>
  </>;
};

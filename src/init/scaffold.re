open Ink;

module Overwrite = {
  open Ui;

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
      (
        ~configuration: Cma.Configuration.t,
        ~onSubmit as onChange,
        ~isDisabled,
      ) => {
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

// 1. Copy base directory
// 2. Check if any configuration options require extensions (e.g. webpack, vite)
//    For each extension:
//    2.1. Copy any files from the extension directory if required
//    2.2. Extend any existing templates (TODO: How do we relate an extension to a template?)
// 3. Compile templates
// 4. Run any actions(?) (e.g. npm install, opam init, opam install)

module Compile_templates = {
  open Ui;
  [@react.component]
  let make = (~configuration: Cma.Configuration.t) => {
    let (compilation_result, set_compilation_result) =
      React.useState(() => None);

    React.useEffect0(() => {
      set_compilation_result(curr =>
        if (Option.is_none(curr)) {
          Some(Cma.Scaffold.run(configuration));
        } else {
          curr;
        }
      );

      None;
    });

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
  let make =
      (
        ~overwrite: option([> | `Clear | `Overwrite])=?,
        ~configuration: Cma.Configuration.t,
      ) => {
    let (copy_complete, set_copy_complete) = React.useState(() => false);
    let (error, set_error) = React.useState(() => None);

    React.useEffect0(() => {
      // todo use Cma.Fs
      let result = Fs.create_dir(~overwrite?, configuration.name);

      switch (result) {
      | Ok(_) => set_copy_complete(_ => true)
      | Error(err) =>
        set_error(_ => Some(err));
        ();
      };

      let _ = Js.Global.setTimeout(() => {exit(1)}, 500);
      None;
    });

    <Box flexDirection=`column gap=1>
      {switch (error) {
       | Some(err) => <Text> {React.string(err)} </Text>
       | None =>
         copy_complete
           ? <Compile_templates configuration />
           : <Spinner label="Copying template files" />
       }}
    </Box>;
  };
};

[@react.component]
let make = (~configuration as initial_configuration: Cma.Configuration.t) => {
  let (configuration, set_configuration) =
    React.useState(() => initial_configuration);
  let (project_dir_exists, _set_project_dir_exists) =
    React.useState(() => Fs.project_dir_exists(configuration.name));

  let onSubmit =
    React.useCallback0((value: string) => {
      let overwrite = Overwrite.overwrite_of_string(value);

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

  <Box flexDirection=`column gap=1>
    {switch (project_dir_exists, configuration.overwrite) {
     | (true, None) => <Overwrite configuration onSubmit isDisabled=false />
     | (true, Some(`Overwrite))
     | (true, Some(`Clear)) =>
       <>
         <Overwrite configuration onSubmit isDisabled=true />
         <Copy_template configuration overwrite={configuration.overwrite} />
       </>
     | _ => <Copy_template configuration />
     }}
  </Box>;
};

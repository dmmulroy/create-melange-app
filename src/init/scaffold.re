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

module Compile_templates = {
  open Ui;
  [@react.component]
  let make = (~configuration: Cma.Configuration.t) => {
    let (compilation_result, set_compilation_result) =
      React.useState(() => None);

    React.useEffect0(() => {
      Cma.Scaffold.run(configuration)
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

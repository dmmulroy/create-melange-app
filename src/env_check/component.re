open Bindings;
open Ink;
open Ui;

let dependency_check_result_is_successful = dependency_results => {
  dependency_results
  |> List.for_all(
       fun
       | `Pass(_) => true
       | _ => false,
     );
};

module Dependency_results = {
  [@react.component]
  let make =
      (
        ~results:
           list(
             [<
               | `Fail((module Core.Dependency.S))
               | `Pass((module Core.Dependency.S))
             ],
           ),
      ) => {
    <Box flexDirection=`column gap=1>
      {results
       |> List.sort((a, b) =>
            switch (a, b) {
            | (`Fail(module A: Core.Dependency.S), `Fail(_)) =>
              if (A.required) {1} else {(-1)}
            | (`Fail(_), _) => 1
            | (_, `Fail(_)) => (-1)
            | _ => 0
            }
          )
       |> List.mapi((idx, dependency_check_result) => {
            <Box key={Int.to_string(idx)} gap=1>
              {switch (dependency_check_result) {
               | `Pass(module Dep: Core.Dependency.S) =>
                 <Box flexDirection=`row gap=1>
                   <Badge key="badge" color=`green>
                     {React.string("PASS")}
                   </Badge>
                   <Text key="text">
                     {React.string("Dependency: " ++ Dep.name)}
                   </Text>
                 </Box>
               | `Fail(module Dep: Core.Dependency.S) =>
                 <Box flexDirection=`column>
                   <Box flexDirection=`row gap=1>
                     {Dep.required
                        ? <Badge key="red" color=`red>
                            {React.string("FAIL")}
                          </Badge>
                        : <Badge key="yellow" color=`yellow>
                            {React.string("WARNING")}
                          </Badge>}
                     <Text key="text">
                       {React.string("Dependency: " ++ Dep.name)}
                     </Text>
                   </Box>
                   <Text key="help"> {React.string(Dep.help)} </Text>
                 </Box>
               }}
            </Box>
          })
       |> Array.of_list
       |> React.array}
    </Box>;
  };
};

[@react.component]
let make = (~onEnvCheck=?) => {
  let (dependency_results, set_dependency_results) =
    React.useState(() => None);
  let (loading, set_loading) = React.useState(() => true);
  let (_error, set_error) = React.useState(() => None);

  React.useEffect0(() => {
    set_loading(_ => true);
    Core.Engine.check_dependencies()
    |> Promise_result.perform(checks_result => {
         switch (checks_result) {
         | Error(error) => set_error(_ => Some(error))
         | Ok(results) =>
           set_dependency_results(_ => Some(results));
           set_loading(_ => false);
         }
       });
    None;
  });

  React.useEffect1(
    () => {
      switch (onEnvCheck, dependency_results) {
      | (Some(onEnvCheck), Some(dependency_results)) =>
        if (dependency_check_result_is_successful(dependency_results)) {
          onEnvCheck(`Pass(dependency_results));
        } else {
          onEnvCheck(`Fail(dependency_results));
        }
      | _ => ()
      };

      None;
    },
    [|dependency_results|],
  );

  let is_successful =
    React.useMemo1(
      () =>
        Option.fold(
          ~none=false,
          ~some=dependency_check_result_is_successful,
          dependency_results,
        ),
      [|dependency_results|],
    );

  <Box flexDirection=`column gap=1>
    {switch (loading, dependency_results) {
     | (true, _) =>
       <Spinner label={js|Checking environment dependencies 🔎 |js} />
     | (false, Some(results)) =>
       <>
         <Text key="1">
           {React.string({js|Checking environment dependencies 🔎 |js})}
         </Text>
         <Dependency_results key="2" results />
         <Text key="3">
           {is_successful
              ? {
                React.string(
                  {js|Your environment dependencies are ready to go! 🚀|js},
                );
              }
              : {
                React.string(
                  {js|Please install your missing depedencies and try again.|js},
                );
              }}
         </Text>
       </>
     | _ => React.null
     }}
  </Box>;
};

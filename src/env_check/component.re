open Ink;
open Ui;

let dependency_check_result_is_successful =
    (results: list(Core.Dependency.check_result)) => {
  List.filter(
    (result: Core.Dependency.check_result) => {
      module Dependency = (val result.dependency);

      switch (result.status) {
      | `Failed(_) when Dependency.required == true => true
      | _ => false
      };
    },
    results,
  )
  |> List.length == 0;
};

module Dependency_results = {
  [@react.component]
  let make = (~results: list(Core.Dependency.check_result)) => {
    <Box flexDirection=`column gap=1>
      {List.sort(
         (a: Core.Dependency.check_result, b: Core.Dependency.check_result) => {
           module A = (val a.dependency: Core.Dependency.S);
           module B = (val b.dependency: Core.Dependency.S);

           switch (a.status, b.status) {
           | (`Failed(_), `Failed(_)) => if (A.required) {1} else {(-1)}
           | (`Failed(_), _) => 1
           | (_, `Failed(_)) => (-1)
           | _ => 0
           };
         },
         results,
       )
       |> List.map((result: Core.Dependency.check_result) => {
            module Dependency = (val result.dependency);
            <Box key=Dependency.name gap=1>
              {switch (result.status) {
               | `Failed(_) =>
                 <Box flexDirection=`column>
                   <Box flexDirection=`row gap=1>
                     {Dependency.required
                        ? <Badge color=`red> {React.string("FAIL")} </Badge>
                        : <Badge color=`yellow>
                            {React.string("WARNING")}
                          </Badge>}
                     <Text>
                       {React.string("Dependency: " ++ Dependency.name)}
                     </Text>
                   </Box>
                   <Text> {React.string(Dependency.help)} </Text>
                 </Box>
               | `Pass =>
                 <Box flexDirection=`row gap=1>
                   <Badge color=`green> {React.string("PASS")} </Badge>
                   <Text>
                     {React.string("Dependency: " ++ Dependency.name)}
                   </Text>
                 </Box>
               }}
            </Box>;
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

  React.useEffect0(() => {
    set_loading(_ => true);

    let _ =
      Core.Engine.check_dependencies()
      |> Js.Promise.then_(results => {
           set_dependency_results(_ => Some(results));
           set_loading(_ => false);
           Js.Promise.resolve();
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
    Option.fold(
      ~none=false,
      ~some=dependency_check_result_is_successful,
      dependency_results,
    );

  <Box flexDirection=`column gap=1>
    {switch (loading, dependency_results) {
     | (true, _) =>
       <Spinner label={js|Checking environment dependencies 🔎 |js} />
     | (false, Some(results)) =>
       <>
         <Text>
           {React.string({js|Checking environment dependencies 🔎 |js})}
         </Text>
         <Dependency_results results />
         <Text>
           {is_successful
              ? {
                React.string(
                  {js|Your environment dependencies are ready to go! 🚀|js},
                );
              }
              : {
                React.string(
                  {js|Please fix the above issues before continuing. 🛠 |js},
                );
              }}
         </Text>
       </>
     | _ => React.null
     }}
  </Box>;
};

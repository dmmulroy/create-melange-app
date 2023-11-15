let prefix = {js|[create-melange-app]: |js};

let print = (~without_prefix=false, msg) =>
  if (without_prefix) {
    msg;
  } else {
    prefix ++ msg;
  };

[@react.component]
let make = () => {
  let (loading, setLoading) = React.useState(() => false);
  let (env_check_status, set_env_check_status) = React.useState(() => None);

  React.useEffect0(() => {
    setLoading(_ => true);

    let result = Action.run();

    setLoading(_ => false);

    set_env_check_status(_ => Some(result));

    None;
  });

  /* render section */
  <>
    <Ink.Text>
      {{js|Checking environment dependencies 🔎 |js} |> print |> React.string}
    </Ink.Text>
    {switch (loading, env_check_status) {
     // Initial state
     | (false, None) =>
       <Ink.Text>
         {{js|Preparing to check environment dependencies|js}
          |> print
          |> React.string}
       </Ink.Text>
     // Loading state
     | (true, _) =>
       <Ink.Text>
         {{js|Checking environment dependencies 🔎 |js}
          |> print
          |> React.string}
       </Ink.Text>
     // Failure state
     | (_, Some(Error(missing_dependencies))) =>
       <Ink.Text color="red">
         {"Missing dependency: "
          ++ String.concat(", ", missing_dependencies)
          |> print
          |> React.string}
       </Ink.Text>
     // Success state
     | (_, Some(Ok(dependencies))) =>
       <>
         {React.array(
            Array.of_list(
              List.map(
                dependency => {
                  let name = Dependency.name(dependency);
                  let version = Dependency.version(dependency);
                  <Ink.Text key=name>
                    {{js|✅ |js}
                     ++ name
                     ++ " version "
                     ++ version
                     ++ " found"
                     |> print
                     |> React.string}
                  </Ink.Text>;
                },
                dependencies,
              ),
            ),
          )}
         <Ink.Text>
           {{js|Your environment dependencies are ready to go 🚀|js}
            |> print
            |> React.string}
         </Ink.Text>
         <Ink.Text>
           {{js|Enter your app's name: super-dope-ocaml-webapp|js}
            |> print
            |> React.string}
         </Ink.Text>
       </>
     }}
  </>;
};
// Format.sprintf({js|✅ %s version %s found\n|js}, (Dependency.name dependency), (Dependency.version dependency))

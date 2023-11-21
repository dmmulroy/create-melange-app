open Ink;
open Common;
let prefix = {js|[create-melange-app]:|js};

module Missing_dependency = {
  [@react.component]
  let make = (~name, ~help_message) => {
    <Prefix>
      <Text color="red">
        {{js| ⚠️  Missing dependency: |js} ++ name |> React.string}
      </Text>
      <Text> {React.string(help_message)} </Text>
    </Prefix>;
  };
};

module Successful_env_check = {
  [@react.component]
  let make = (~node: Dependency.Node.t, ~opam: Dependency.Opam.t) => {
    <>
      <Prefix>
        <Text>
          {{js| ✅ |js}
           ++ opam.name
           ++ " version "
           ++ opam.version
           ++ " found"
           |> React.string}
        </Text>
      </Prefix>
      <Prefix>
        <Text>
          {{js| ✅ |js}
           ++ node.name
           ++ " version "
           ++ node.version
           ++ " found"
           |> React.string}
        </Text>
      </Prefix>
      <Prefix>
        <Text>
          {React.string(
             {js|Your environment dependencies are ready to go 🚀|js},
           )}
        </Text>
      </Prefix>
    </>;
  };
};

[@react.component]
let make = (~on_env_check=?) => {
  let (dependency_results, set_dependency_results) =
    React.useState(() => None);

  React.useEffect0(() => {
    let results = Action.run();

    set_dependency_results(_ => Some(results));

    switch (on_env_check) {
    | Some(on_env_check) => on_env_check(results)
    | None => ()
    };

    None;
  });

  /* render section */
  <>
    <Prefix>
      <Text>
        {React.string({js|Checking environment dependencies 🔎 |js})}
      </Text>
    </Prefix>
    {switch (dependency_results) {
     // Initial state
     | None => React.null
     // Failure state which is indicative of a missing dependency
     | Some(Error((name, help_message))) =>
       <Missing_dependency name help_message />
     // Success state
     | Some(Ok((node, opam))) => <Successful_env_check node opam />
     }}
  </>;
};

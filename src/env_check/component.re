let prefix = {js|[create-melange-app]:|js};

module Missing_dependency = {
  [@react.component]
  let make = (~name, ~help_message) => {
    <>
      <Ink.Text color="red">
        {prefix
         ++ {js| ⚠️  Missing dependency: |js}
         ++ name
         |> React.string}
      </Ink.Text>
      <Ink.Text> {React.string(help_message)} </Ink.Text>
    </>;
  };
};

module Successful_env_check = {
  [@react.component]
  let make = (~node: Dependency.Node.t, ~opam: Dependency.Opam.t) => {
    <>
      <Ink.Text>
        {prefix
         ++ {js| ✅ |js}
         ++ opam.name
         ++ " version "
         ++ opam.version
         ++ " found"
         |> React.string}
      </Ink.Text>
      <Ink.Text>
        {prefix
         ++ {js| ✅ |js}
         ++ node.name
         ++ " version "
         ++ node.version
         ++ " found"
         |> React.string}
      </Ink.Text>
      <Ink.Text>
        {React.string(
           {js|Your environment dependencies are ready to go 🚀|js},
         )}
      </Ink.Text>
    </>;
  };
};

[@react.component]
let make = () => {
  let (dependency_results, set_dependency_results) =
    React.useState(() => None);

  React.useEffect0(() => {
    let results = Action.run();

    set_dependency_results(_ => Some(results));

    None;
  });

  /* render section */
  <>
    <Ink.Text>
      {React.string(prefix ++ {js|Checking environment dependencies 🔎 |js})}
    </Ink.Text>
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

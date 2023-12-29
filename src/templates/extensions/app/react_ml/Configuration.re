// TODO: Writ comment explaing open Module;
open Create_melange_app;
// TODO: Write comment introducing React.string and why we need it
[@react.component]
let make = (~configuration: Configuration.t) => {
  <div>
    <h3> {React.string("Your create-melange-app configuration:")} </h3>
    <ul>
      <li> {React.string(Configuration.to_string(configuration))} </li>
      <li>
        {React.string(
           Format.sprintf("Your project name is %s", configuration.name),
         )}
      </li>
      <li>
        {React.string(
           Format.sprintf(
             "Your project was created in %s (relative to where you invoked `create-melange-app`)",
             configuration.directory,
           ),
         )}
      </li>
      <li>
        {React.string(
           Format.sprintf(
             "Your bundler is %s",
             Configuration.Bundler.to_string(configuration.bundler),
           ),
         )}
      </li>
      <li>
        {React.string(Format.sprintf("Your project is a React app"))}
      </li>
      <li>
        {React.string(
           Format.sprintf(
             "Your project was %s initialized with git",
             configuration.initialize_git ? "" : "not",
           ),
         )}
      </li>
      <li>
        {React.string(
           Format.sprintf(
             "Your project was %s initialized with npm",
             configuration.initialize_npm ? "" : "not",
           ),
         )}
      </li>
      <li>
        {React.string(
           Format.sprintf(
             "Your project was %s initialized with the OCaml toolchain",
             configuration.initialize_ocaml_toolchain ? "" : "not",
           ),
         )}
      </li>
      <li>
        {React.string(
           Format.sprintf(
             "Your overwrite preference is %s",
             switch (configuration.overwrite) {
             | None => "none"
             | Some(overwrite) =>
               Configuration.overwrite_preference_to_string(overwrite)
             },
           ),
         )}
      </li>
    </ul>
  </div>;
};

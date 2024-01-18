/*
 * In ReasonML, the `open` statement is used to bring modules into the current
 * scope, similar to using `import` in JavaScript or TypeScript. However, unlike
 * `import`, `open` makes all of the module's contents immediately available
 * without the need to prefix them with the module name. This is akin to doing a
 * wildcard import in JavaScript:
 *
 * `import * as Create_melange_app from 'Create_melange_app';`
 */
open Cma_configuration;

[@react.component]
let make = (~configuration: Configuration.t) => {
  let node_package_manager_str =
    configuration.node_package_manager |> Node_package_manager.to_string;

  <div className="text-[#b8c0e0] text-2xl">
    <h3 className="font-bold text-3xl mb-2">
      <>
        {React.string("Your")}
        <span
          className="bg-gradient-to-r from-[#f5bde6] to-[#c6a0f6] bg-clip-text text-transparent">
          {React.string(" create-melange-app ")}
        </span>
        {React.string("configuration:")}
      </>
    </h3>
    <ul>
      <li>
        <>
          {React.string("Project name: ")}
          <span
            className="font-bold bg-gradient-to-r from-[#8bd5ca] to-[#91d7e3] bg-clip-text text-transparent">
            {React.string(configuration.name)}
          </span>
        </>
      </li>
      <li>
        <>
          {React.string("Project directory: ")}
          <span
            className="font-bold bg-gradient-to-r from-[#8bd5ca] to-[#91d7e3] bg-clip-text text-transparent">
            {React.string(configuration.directory)}
          </span>
        </>
      </li>
      <li>
        <>
          {React.string("Bundler: ")}
          <span
            className="font-bold bg-gradient-to-r from-[#8bd5ca] to-[#91d7e3] bg-clip-text text-transparent">
            {configuration.bundler
             |> Bundler.to_string
             |> String.capitalize_ascii
             |> React.string}
          </span>
        </>
      </li>
      {configuration.initialize_git
       || configuration.initialize_npm
       || configuration.initialize_ocaml_toolchain
         ? <li>
             <>
               {React.string("Initialized with: ")}
               <span
                 className="font-bold bg-gradient-to-r from-[#8bd5ca] to-[#91d7e3] bg-clip-text text-transparent">
                 {switch (
                    configuration.initialize_git,
                    configuration.initialize_npm,
                    configuration.initialize_ocaml_toolchain,
                  ) {
                  | (true, false, false) => React.string("Git")
                  | (true, true, false) =>
                    "Git and " ++ node_package_manager_str |> React.string
                  | (true, true, true) =>
                    "Git, "
                    ++ node_package_manager_str
                    ++ " , and the OCaml toolchain"
                    |> React.string
                  | (false, true, false) =>
                    React.string(node_package_manager_str)
                  | (false, true, true) =>
                    node_package_manager_str
                    ++ " and the OCaml toolchain"
                    |> React.string
                  | (false, false, true) =>
                    "The OCaml toolchain" |> React.string
                  | (true, false, true) =>
                    "Git and the OCaml toolchain" |> React.string
                  | (false, false, false) => assert(false)
                  }}
               </span>
             </>
           </li>
         : React.null}
    </ul>
  </div>;
};

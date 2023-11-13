// This is a real commander.js example, and is what we're aiming
// to generate with melange.
/* program
    |> Command.set_name "create-melange-app"
    |> Command.set_description "A CLI for creating applications with Melange"
    |> Command.set_version "0.0.1"
    |> Command.argument ~name:"[dir]"
         ~description:
           "The name of the application, as well as the name of the directory \
            to create"
    |> Command.add_action (fun args ->
           Js.Console.log args;
           `Void ())
    |> Command.parse */
const { program } = require("commander");

program
  .name("creating-melange-app")
  .description("A CLI for creating applications with Melange")
  .version("0.0.1")
  .argument(
    "[dir]",
    "The name of the application, as well as the name of the directory to create"
  )
  .action(function (...args) {
    console.log(args);
  })
  .parse();

// example output:
// bun commaned_example.js -s / --first a/b/c
// { first: true, separator: "/" }

open Bindings

module Version : Process.S with type input = unit and type output = string =
struct
  type input = unit
  type output = string

  let name = "node --version"

  let exec (_ : input) =
    let options = Node.Child_process.option ~encoding:"utf8" () in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const "Failed to get node version")
  ;;
end

module Dependency = Dependency.Make (struct
  include Version

  let name = "Node.js"

  let help =
    {|
  Node.js is required to run create-melange-app.

  Here's how to install it:

    On macOS: Use Homebrew by running `brew install node` in your terminal.

    On Linux: Use your distribution's package manager. For example, on Ubuntu, run `sudo apt-get install nodejs`.

    On Windows: Download the official Windows Installer from the Node.js website. 

    Alternatively, you can use a package manager like Chocolatey and run `choco install nodejs`.

    For detailed installation instructions and downloads, visit the official Node.js website: 

    https://nodejs.org/en/download/|}
  ;;

  let required = true
  let input = ()
end)

open Bindings
open Context_plugin

module Init_and_stage :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "git init && git add -A"

  let exec (project_dir_name : input) =
    let options =
      Node.Child_process.option ~cwd:project_dir_name ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec name options
    |> Js.Promise.then_ (fun value -> Js.Promise.resolve @@ Ok value)
    |> Js.Promise.catch (fun _err ->
           Js.Promise.resolve @@ Error "Failed to initialize npm")
  ;;
end

module Copy_gitignore :
  Process.S with type input = string and type output = unit = struct
  type input = string
  type output = unit

  let name = "copy git extension files"

  let gitignore_path =
    Node.Path.join
      [|
        Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
        "..";
        "templates";
        "extensions";
        "git_scm";
        "_gitignore";
      |]
  ;;

  let exec (project_dir_name : input) =
    let dest = Node.Path.join [| project_dir_name; "/"; ".gitignore" |] in
    Fs.copy_file ~dest gitignore_path
  ;;
end

module Plugin = struct
  module Init_and_stage = struct
    include Plugin.Make_process (struct
      include Init_and_stage

      let stage = `Post_compile
      let input_of_context (ctx : Context.t) = Ok ctx.configuration.directory
    end)
  end

  module Copy_gitignore = struct
    include Plugin.Make_process (struct
      include Copy_gitignore

      let stage = `Post_compile
      let input_of_context (ctx : Context.t) = Ok ctx.configuration.directory
    end)
  end
end

module Version : Process.S with type input = unit and type output = string =
struct
  type input = unit
  type output = string

  let name = "git --version"

  let exec (_ : input) =
    let options = Node.Child_process.option ~encoding:"utf8" () in
    Nodejs.Child_process.async_exec name options
    |> Js.Promise.then_ (fun value -> Js.Promise.resolve @@ Ok value)
    |> Js.Promise.catch (fun _err ->
           Js.Promise.resolve @@ Error "Failed to get git version")
  ;;
end

module Dependency = Dependency.Make (struct
  include Version

  let name = "Git"

  let help =
    {|
  Git is a version control system commonly used in software development and is not required to run create-melange-app. 

  However, without Git, we won't be able to initialize a Git repository for you.

  If you wish to use Git, here's how to install it:

    On macOS: Use Homebrew by running `brew install git` in your terminal.

    On Linux: Use your distribution's package manager. For example, on Ubuntu, run `sudo apt-get install git`.

    On Windows: Download and install Git for Windows from https://git-scm.com/download/win. 

    Alternatively, if using WSL (Windows Subsystem for Linux), follow the Linux installation instructions.

    For more information on using Git, visit https://git-scm.com/doc
  |}
  ;;

  let required = false
  let input = ()
end)

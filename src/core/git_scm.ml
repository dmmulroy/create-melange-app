open Bindings

module Init_and_stage :
  Process.S with type input = string and type output = string = struct
  type input = string
  type output = string

  let name = "git init && git add -A"

  let error_message =
    {|
    Failed to initialize git repository

    The scaffolding process failed while running `git init && git add -A`. 
    Your project is ready, but you will have to initialize git on your own.

    You can `cd` into your project directory and run the following command:

    npm run dev

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
  ;;

  let exec (project_dir_name : input) =
    let options =
      Node.Child_process.option ~cwd:project_dir_name ~encoding:"utf8" ()
    in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const error_message)
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

  let error_message =
    {|
    Failed to copy gitignore file to project directory

    The scaffolding process failed while copying `.gitignore`. Please try 
    running `create-melange-app` again and choose to `Clear` the project 
    directory created by this run.

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
  ;;

  let exec (project_dir_name : input) =
    let dest = Node.Path.join [| project_dir_name; "/"; ".gitignore" |] in
    Fs.copy_file ~dest gitignore_path
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end

module Version : Process.S with type input = unit and type output = string =
struct
  type input = unit
  type output = string

  let name = "git --version"

  let exec (_ : input) =
    let options = Node.Child_process.option ~encoding:"utf8" () in
    Nodejs.Child_process.async_exec name options
    |> Promise_result.of_js_promise
    |> Promise_result.catch Promise_result.resolve_error
    |> Promise_result.map_error (Fun.const "Failed to get git version")
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

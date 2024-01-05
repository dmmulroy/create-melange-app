open Bindings

type app_options = {
  project_directory : string;
  syntax_preference : Configuration.syntax_preference;
  is_react_app : bool;
}

module Copy : Process.S with type input = app_options and type output = unit =
struct
  type input = app_options
  type output = unit

  let name = "copy app files"

  let base_path =
    Node.Path.join
      [|
        Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
        "..";
        "templates";
        "extensions";
        "app";
      |]
  ;;

  let app_ml_path = Node.Path.join [| base_path; "app_ml" |]
  let app_re_path = Node.Path.join [| base_path; "app_re" |]
  let react_ml_path = Node.Path.join [| base_path; "react_ml" |]
  let react_re_path = Node.Path.join [| base_path; "react_re" |]

  let error_message =
    {|
    Failed to copy app files to project directory

    The scaffolding process failed while copying app files. Please try 
    running `create-melange-app` again and choose to `Clear` the project 
    directory created by this run.

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
  ;;

  let exec (input : input) =
    let dest = Node.Path.join [| input.project_directory; "/"; "src" |] in
    let copy = Fs.copy_file ~dest in
    (match (input.syntax_preference, input.is_react_app) with
    | `OCaml, false -> copy app_ml_path
    | `OCaml, true -> copy react_ml_path
    | `ReasonML, false -> copy app_re_path
    | `ReasonML, true -> copy react_re_path)
    |> Promise_result.map_error (Fun.const error_message)
  ;;
end

open Bindings

type app_options = App_files.app_options

module Copy : Process.S with type input = app_options and type output = unit =
struct
  type input = app_options
  type output = unit

  let name = "copy test files"

  let base_path =
    Node.Path.join
      [|
        Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
        "..";
        "templates";
        "extensions";
        "test";
      |]
  ;;

  let test_ml_path = Node.Path.join [| base_path; "app_ml" |]
  let test_re_path = Node.Path.join [| base_path; "app_re" |]
  let test_react_ml_path = Node.Path.join [| base_path; "react_ml" |]
  let test_react_re_path = Node.Path.join [| base_path; "react_re" |]
  let dune_tmpl_file_name = "dune.tmpl"

  let test_dune_file_template_path =
    Node.Path.join [| base_path; dune_tmpl_file_name |]
  ;;

  let error_message =
    {|
    Failed to copy test files to project directory

    The scaffolding process failed while copying test files. Please try 
    running `create-melange-app` again and choose to `Clear` the project 
    directory created by this run.

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
  ;;

  let exec (input : input) =
    let dest = Node.Path.join [| input.project_directory; "/"; "test" |] in
    let test_files_path =
      match (input.syntax_preference, input.is_react_app) with
      | `OCaml, false -> test_ml_path
      | `OCaml, true -> test_react_ml_path
      | `ReasonML, false -> test_re_path
      | `ReasonML, true -> test_react_re_path
    in

    (fun _ ->
      (* copy dunefile template file into dest *)
      Fs.copy_file
        ~dest:(Node.Path.join [| dest; dune_tmpl_file_name |])
        test_dune_file_template_path)
    |> Promise_result.bind
         ((* copy files contained in test_files_path into dest *)
          Fs.copy_file ~dest test_files_path)
    |> Promise_result.log_and_map_error (Fun.const error_message)
  ;;
end

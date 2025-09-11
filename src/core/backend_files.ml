open Bindings

type backend_options = {
  project_directory : string;
  backend_framework : Configuration.backend_framework option;
  project_name : string;
}

module Copy :
  Process.S with type input = backend_options and type output = unit = struct
  type input = backend_options
  type output = unit

  let name = "copy backend files"

  let base_path =
    Node.Path.join
      [|
        Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
        "..";
        "templates";
        "extensions";
        "backend";
        "dream";
      |]
  ;;

  let error_message =
    {|
    Failed to copy backend files to project directory

    The scaffolding process failed while copying backend files. Please try 
    running `create-melange-app` again and choose to `Clear` the project 
    directory created by this run.

    If the problem persists, please open an issue at 
    github.com/dmmulroy/create-melange-app/issues, and or join our discord for 
    help at https://discord.gg/fNvVdsUWHE.
  |}
  ;;

  let exec (input : input) =
    match input.backend_framework with
    | Some `Dream ->
        let open Promise_result.Syntax.Let in
        let backend_dest =
          Node.Path.join [| input.project_directory; "backend" |]
        in
        let bin_dest = Node.Path.join [| backend_dest; "bin" |] in
        let+ _ =
          Fs_extra.ensureDir backend_dest |> Promise_result.of_js_promise
        in
        let+ _ = Fs_extra.ensureDir bin_dest |> Promise_result.of_js_promise in

        let+ _ =
          Fs_extra.copy
            (Node.Path.join [| base_path; "bin"; "main.ml.tmpl" |])
            (Node.Path.join [| bin_dest; "main.ml.tmpl" |])
          |> Promise_result.of_js_promise
        in
        let+ _ =
          Fs_extra.copy
            (Node.Path.join [| base_path; "bin"; "dune.tmpl" |])
            (Node.Path.join [| bin_dest; "dune.tmpl" |])
          |> Promise_result.of_js_promise
        in
        let+ _ =
          Fs_extra.copy
            (Node.Path.join [| base_path; "dune.tmpl" |])
            (Node.Path.join [| backend_dest; "dune.tmpl" |])
          |> Promise_result.of_js_promise
        in
        let+ _ =
          Fs_extra.copy
            (Node.Path.join [| base_path; "README.md.tmpl" |])
            (Node.Path.join [| backend_dest; "README.md.tmpl" |])
          |> Promise_result.of_js_promise
        in

        Promise_result.resolve_ok ()
        |> Promise_result.log_and_map_error (Fun.const error_message)
    | None -> Promise_result.resolve_ok ()
  ;;
end

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
        [%mel.raw "__dirname"];
        "..";
        "templates";
        "extensions";
        "git";
        ".gitignore";
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
      let input_of_context (ctx : Context.t) = Ok ctx.configuration.name
    end)
  end

  module Copy_gitignore = struct
    include Plugin.Make_process (struct
      include Copy_gitignore

      let stage = `Post_compile
      let input_of_context (ctx : Context.t) = Ok ctx.configuration.name
    end)
  end
end

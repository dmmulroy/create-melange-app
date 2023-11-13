[@@@ocaml.warning "-27"]

let trim_dashes str =
  if StringLabels.starts_with ~prefix:"--" str then
    StringLabels.sub ~pos:2 ~len:(String.length str - 2) str
  else if StringLabels.starts_with ~prefix:"-" str then
    StringLabels.sub ~pos:1 ~len:(String.length str - 1) str
  else str

(* A CLI for creating applications with melange *)
module Argument = struct
  type t = {
    name : string;
    description : string;
    required : bool;
    default_value : string option;
  }

  let make ?default_value ~required ~name ~description () =
    { name; description; required; default_value }
end

module Opt = struct
  type value = String of string | Bool of bool | Strings of string list

  type t = {
    default_value : value option;
    description : string;
    name : string;
    short_name : string option;
    required : bool;
    value_name : string option;
  }

  let short_name_to_formatted_string (short_name : string option) =
    match short_name with
    | None -> ""
    | Some short_name -> Format.sprintf "-%s" short_name

  let name_to_formatted_string (name : string) = Format.sprintf "--%s" name

  let make ?value_name ?default_value ?short_name ~required ~name ~description
      () =
    {
      name = trim_dashes name;
      description;
      short_name = Option.map trim_dashes short_name;
      required;
      default_value;
      value_name;
    }
end

module Command = struct
  type t = {
    aliases : string list;
    arguments : Argument.t list;
    description : string;
    name : string;
    options : Opt.t list;
    sub_commands : t list;
  }

  (** [add_option opt cmd] adds [opt] to [cmd] *)
  let add_argument arg cmd =
    match cmd.arguments with
    | [] -> { cmd with arguments = [ arg ] }
    | args -> { cmd with arguments = arg :: args }

  (** [add_option opt cmd] adds [opt] to [cmd] *)
  let add_option opt cmd =
    match cmd.options with
    | [] -> { cmd with options = [ opt ] }
    | opts -> { cmd with options = opt :: opts }

  (** [add_sub_command child parent] adds [child] as a subcommand of [parent] *)
  let add_sub_command child parent =
    match parent.sub_commands with
    | [] -> { parent with sub_commands = [ child ] }
    | children -> { parent with sub_commands = child :: children }

  let make ?(aliases = []) ?(arguments = []) ?(sub_commands = [])
      ?(options = []) ~name ~description () =
    { name; aliases; arguments; sub_commands; options; description }
end

module Program = struct
  type t = {
    commands : Command.t list;
    root_command : Command.t option;
    version : string;
  }

  let make ?root_command ?(commands = []) ~version () =
    { version; commands; root_command }
end

module Commander_js = struct
  (* val make_argument : Argument.t -> Commander.Argument.t *)
  let make_argument (argument : Argument.t) =
    let default_value =
      argument.default_value |> Option.map (fun value -> `String value)
    in
    let arg =
      Commander.Argument.make ~name:argument.name
        ~description:argument.description ()
    in
    let arg =
      match default_value with
      | Some value -> arg |> Commander.Argument.default ~value
      | None -> arg
    in
    if argument.required then arg |> Commander.Argument.arg_required
    else arg |> Commander.Argument.arg_optional

  let make_command_name ?(aliases = []) name =
    match aliases with
    | [] -> name
    | aliases -> List.map trim_dashes (name :: aliases) |> String.concat ", "

  (* val make_command : Command.t -> Commander.Command.t *)
  let rec make_command (command : Command.t) =
    let cmd =
      command.name
      |> make_command_name ~aliases:command.aliases
      |> Commander.create_command
      |> fun cmd ->
      List.fold_left
        (fun cmd' (argument : Argument.t) ->
          Commander.Command.add_argument (make_argument argument) cmd')
        cmd command.arguments
      |> fun cmd ->
      List.fold_left
        (fun cmd' (command : Command.t) ->
          Commander.Command.add_command (make_command command) cmd')
        cmd command.sub_commands
    in
    cmd

  let opt_to_flags (opt : Opt.t) =
    let value_name =
      opt.value_name
      |> Option.map (fun value_name ->
             if opt.required then Format.sprintf "<%s>" value_name
             else Format.sprintf "[%s]" value_name)
    in
    match (opt.short_name, value_name) with
    | None, Some value_name -> Format.sprintf "--%s %s" opt.name value_name
    | Some short_name, Some value_name ->
        Format.sprintf "-%s, --%s %s" short_name opt.name value_name
    | Some short_name, None -> Format.sprintf "-%s, --%s" short_name opt.name
    | None, None -> Format.sprintf "--%s" opt.name

  (* val make_option : Opt.t -> Commander.Option.t *)
  let make_option (opt : Opt.t) =
    let opt' =
      opt |> opt_to_flags |> Commander.Opt.make ~description:opt.description
    in
    match opt.default_value with
    | None -> opt'
    | Some (String value) -> opt' |> Commander.Opt.set_default (`String value)
    | Some (Strings value) ->
        opt' |> Commander.Opt.set_default (`Strings (Array.of_list value))
    | Some (Bool value) -> opt' |> Commander.Opt.set_default (`Bool value)

  let make (program : Program.t) =
    program.root_command
    |> Option.fold ~none:Commander.program ~some:make_command
    |> Commander.Command.set_version program.version
    |> fun root_command ->
    List.fold_left
      (fun program' command ->
        Commander.Command.add_command (make_command command) program')
      root_command program.commands
end

open Common

module Config = struct
  module type S = sig
    val command : string
    val help : string
    val name : string
    val parse_version : string -> (string, string) result
  end
end

module type S = sig
  type t = { name : string; version : string }

  val make : string -> t
  val name : string
  val version : t -> string
  val check : unit -> (t, string * string) result
end

module Make (M : Config.S) : S = struct
  type t = { name : string; version : string }

  let make version = { name = M.name; version }
  let name = M.name
  let version dependency = dependency.version

  let check () =
    let cmd_options = Node.Child_process.option ~encoding:"utf8" () in
    try
      cmd_options
      |> Node.Child_process.execSync M.command
      |> M.parse_version |> Result.map make
      |> Result.map_error (fun _ -> (M.name, M.help))
    with _ ->
      (* TODO: Add level logging: "Error running command: %s for dependency: %s" "Error running command: %s for dependency: %s" *)
      Error (M.name, M.help)
end

module Opam : S = Make (struct
  let command = "opam --version"

  (* TODO: Possibly use the Format module *)
  let help =
    {|
    Opam is the package manager for OCaml and is required to run create-melange-app.  

    Here's how to install it:

      On macOS: Use Homebrew by running `brew install opam` in your terminal.

      On Linux: Use your distribution's package manager. For example, on Ubuntu, run `sudo apt-get install opam`.

      On Windows: It's recommended to use WSL (Windows Subsystem for Linux) and then follow the Linux installation instructions.

      After installing, initialize opam with `opam init` in your terminal.

      For more information, visit https://ocaml.org/docs/installing-ocaml#installing-ocaml 
  |}

  let name = "opam"
  let parse_version version = Ok (String.trim version)
end)

module Node : S = Make (struct
  let name = "node"

  (* TODO: Possibly use the Format module *)
  let help =
    {|
  Node is required to run create-melange-app.

  Here's how to install it:

    On macOS: Use Homebrew by running `brew install node` in your terminal.

    On Linux: Use your distribution's package manager. For example, on Ubuntu, run `sudo apt-get install nodejs`.

    On Windows: Download the official Windows Installer from the Node.js website. Alternatively, you can use a package manager like Chocolatey and run `choco install nodejs`.

    For detailed installation instructions and downloads, visit the official Node.js website: https://nodejs.org/en/download/|}

  let command = "node --version"
  let parse_version version = Ok (String.trim version)
end)

type t = Node of Node.t | Opam of Opam.t

let check_all () =
  let open Syntax.Let in
  let@ node = Node.check () in
  let@ opam = Opam.check () in
  Ok (node, opam)

let name = function Node _ -> Node.name | Opam _ -> Opam.name

let version = function
  | Node node -> Node.version node
  | Opam opam -> Opam.version opam

module Config = struct
  module type S = sig
    val name : string
    val command : string
    val parse_version : string -> (string, [> `Msg of string ]) result
  end
end

module type S = sig
  type t = { version : string }

  val make : string -> t
  val name : string
  val version : t -> string
  val check : unit -> (t, [> `Msg of string ]) result
end

module Make (M : Config.S) : S = struct
  type t = { version : string }

  let make version = { version }
  let name = M.name
  let version dependency = dependency.version

  let check () =
    let cmd_options = Node.Child_process.option ~encoding:"utf8" () in
    try
      cmd_options
      |> Node.Child_process.execSync M.command
      |> M.parse_version
      |> Result.map (fun version -> make version)
      |> Result.map_error (fun _ ->
             `Msg (Format.sprintf "Dependency %s not found" M.name))
    with _ ->
      Error
        (`Msg
          (Format.sprintf "Error running command: %s for dependency: %s"
             M.command M.name))
end

module Opam = Make (struct
  let name = "opam"
  let command = "opam --version"
  let parse_version version = Ok (String.trim version)
end)

module Node = Make (struct
  let name = "node"
  let command = "node --version"
  let parse_version version = Ok (String.trim version)
end)

type t = Node of Node.t | Opam of Opam.t

let name = function Node _ -> Node.name | Opam _ -> Opam.name

let version = function
  | Node node -> Node.version node
  | Opam opam -> Opam.version opam

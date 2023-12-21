module type S = sig
  type input
  type output

  val name : string
  val exec : input -> (output, string) result Js.Promise.t
end

module type Exec = S

module type Spawn = sig
  type input
  type output

  val name : string
  val spawn : input -> (output, string) result Js.Promise.t
  val on_stdout : (string -> unit) -> unit
  val on_stderr : (string -> unit) -> unit
  val on_exit : (int -> unit) -> unit
  val on_error : (Js.Exn.t -> unit) -> unit
end

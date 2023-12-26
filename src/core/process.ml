open Bindings

module type S = sig
  type input
  type output

  val name : string
  val exec : input -> (output, string) Promise_result.t
end

module type S = sig
  type input
  type output

  val name : string
  val exec : input -> (output, string) result Js.Promise.t
end

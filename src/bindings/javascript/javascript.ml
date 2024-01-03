module Json = struct
  include Js.Json

  type replacer

  external stringify : t -> 'a Js.null -> int -> string = "stringify"
  [@@mel.scope "JSON"]

  let stringify ?(indent = 0) json = stringify json Js.null indent
end

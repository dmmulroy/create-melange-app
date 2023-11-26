type token
type dynamic = Dynamic : 'a -> dynamic [@@unboxed]

type t = {
  token : token;
  render : (Context.t -> Emitter.t) -> dynamic Js.Promise.t;
}

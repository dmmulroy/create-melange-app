type t = {
  on : (string -> (unit -> unit) -> unit[@u]);
  remove_listener : (string -> (unit -> unit) -> unit[@u]);
      [@mel.as "removeListener"]
}

let on ~event_name ~cb event_emitter =
  (fun _ -> (event_emitter.on event_name cb [@u])) ()

let remove_listener ~event_name ~cb event_emitter =
  (fun _ -> (event_emitter.remove_listener event_name cb [@u])) ()

external make : unit -> t = "EventEmitter"
[@@mel.new] [@@mel.module "node:events"]

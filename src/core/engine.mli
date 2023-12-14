open Context_plugin

val run : Configuration.t -> (Context.t, string) result Js.Promise.t
val check_dependencies : unit -> Dependency.check_result list Js.Promise.t

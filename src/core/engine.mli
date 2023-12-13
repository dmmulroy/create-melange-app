open Context_plugin

val run : Configuration.t -> (Context.t, string) result Js.Promise.t

type dependency_check_result = {
  name : string;
  required : bool;
  status : [ `Pass | `Failed of string ];
}

val check_dependencies : unit -> dependency_check_result list Js.Promise.t

type t = Configuration.t

let template (configuration : Configuration.t) : t Template.t =
  let template_directory = Node.Path.join [| configuration.directory; "./" |] in
  Template.make ~name:"README.tmpl" ~value:configuration ~dir:template_directory
    ~to_json:Configuration.to_json
;;

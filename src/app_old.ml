type value = { name : string }

let main () =
  let value = { name = "test" } in
  let template = Handlebars.compile "Hello, {{name}}!" () in
  Js.log @@ template value ()
;;

let () = main ()

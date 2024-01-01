module type S = sig
  type input

  val validate : input -> (input, [ `Msg of string ]) result
end

module Project_name : S with type input = string = struct
  type input = string

  let is_empty name = String.length name == 0

  (* TODO: Consider a ux like the following:
     [create-melange-app] What will your project be called? foo-bar

     Invalid: foo-bar
                 ^ Name must be lowercase and only contain letters, numbers, or _
  *)
  let validate name =
    let test = Js.Re.test_ [%re "/^[a-z_0-9.]+$/"] in
    if is_empty name then Error (`Msg "Name cannot be empty")
    else if test name == false then
      Error
        (`Msg
          (Format.sprintf
             "%s is an invalid name. Your project name must be lowercase and \
              only contain letters, numbers, or _"
             name))
    else Ok name
  ;;
end

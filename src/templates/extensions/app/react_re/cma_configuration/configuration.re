type overwrite_preference = [ | `Clear | `Overwrite];

let overwrite_preference_to_string =
  fun
  | `Clear => "clear"
  | `Overwrite => "overwrite";

let overwrite_preference_of_string =
  fun
  | "clear" => Ok(`Clear)
  | "overwrite" => Ok(`Overwrite)
  | _ => Error("Invalid overwrite preference");

type t = {
  name: string,
  directory: string,
  node_package_manager: Node_package_manager.t,
  bundler: Bundler.t,
  is_react_app: bool,
  initialize_git: bool,
  initialize_npm: bool,
  initialize_ocaml_toolchain: bool,
  overwrite: option(overwrite_preference),
};

let make =
    (
      ~name,
      ~directory,
      ~node_package_manager,
      ~bundler,
      ~is_react_app,
      ~initialize_git,
      ~initialize_npm,
      ~initialize_ocaml_toolchain,
      ~overwrite=?,
      (),
    ) => {
  name,
  directory,
  node_package_manager,
  bundler,
  is_react_app,
  initialize_git,
  initialize_npm,
  initialize_ocaml_toolchain,
  overwrite,
};

let to_string = config =>
  Format.sprintf(
    "Your configuration:\nName: %s\nDirectory: %s\nBunder: %s\nis_react_app: %b\nInitialize git: %b\nInitialize npm: %b\nInitialize OCaml toolchain: %b\n",
    config.name,
    config.directory,
    Bundler.to_string(config.bundler),
    config.is_react_app,
    config.initialize_git,
    config.initialize_npm,
    config.initialize_ocaml_toolchain,
  );


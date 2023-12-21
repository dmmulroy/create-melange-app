open Bindings.Ink;

[@react.component]
let make = (~children) => {
  <Text> {React.string({js|[create-melange-app] |js})} children </Text>;
};

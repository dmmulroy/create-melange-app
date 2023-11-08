module Static = {
  [@mel.module "ink"] [@react.component]
  external make:
    (
      ~items: array('a),
      ~style: string=?,
      ~children: ('a, int) => React.element
    ) =>
    React.element =
    "Static";
};

open Fest;
module RTL = ReactTestingLibrary;
[@mel.get] external textContent: Dom.element => string = "textContent";

Domloader.init();

module Hello = {
  [@react.component]
  let make = (~text) => <div> {"Hello " ++ text |> React.string} </div>;
};

let () =
  test("test component", () => {
    let result = RTL.render(<Hello text="Nila" />);

    // Check that Hello component renders the name properly.

    let el = RTL.getByText(~matcher=`Str("Hello Nila"), result);
    expect |> equal(textContent(el), "Hello Nila");
  });

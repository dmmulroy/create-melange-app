open Fest;

let () = test("equal", () =>
           expect |> equal(4 - 3, 1)
         );
let () = test("equal 2", () =>
           expect |> equal("f" ++ "oo", "foo")
         );
let () = test("ok", () =>
           expect |> ok(true || false)
         );

module Deep_strict_equal = {
  type foo =
    | Foo(int);
  type bar = {
    foo,
    bar: string,
  };

  let assertion = (~f, ()) =>
    expect
    |> f(
         {
           foo: Foo(42),
           bar: "hello",
         },
         {
           let bar = {
             foo: Foo(40),
             bar: "hell",
           };
           let bar = {
             ...bar,
             bar: bar.bar ++ "o",
           };
           let bar = {
             ...bar,
             foo:
               switch (bar.foo) {
               | Foo(x) => Foo(x + 2)
               },
           };

           bar;
         },
       );

  let () = test("deep_equal", assertion(~f=deep_equal));
  let () = test("deepEqual", assertion(~f=deepEqual));
};

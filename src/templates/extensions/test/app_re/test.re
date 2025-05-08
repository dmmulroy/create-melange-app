open Fest;

test("equal", () =>
  expect |> equal(4 - 3, 1)
);

test("equal 2", () =>
  expect |> equal("f" ++ "oo", "foo")
);

test("ok", () =>
  expect |> ok(true || false)
);

type foo =
  | Foo(int);

type bar = {
  foo,
  bar: string,
};

test("deepEqual", () =>
  expect
  |> deepEqual(
       {
         foo: Foo(42),
         bar: "hello",
       },
       {
         foo: Foo(42),
         bar: "hello",
       },
     )
);

open Fest;;

test "equal" (fun () -> expect |> equal (4 - 3) 1);
test "equal 2" (fun () -> expect |> equal ("f" ^ "oo") "foo");
test "ok" (fun () -> expect |> ok (true || false))

type foo = Foo of int
type bar = { foo : foo; bar : string };;

test "deepEqual" (fun () ->
    expect
    |> deepEqual { foo = Foo 42; bar = "hello" } { foo = Foo 42; bar = "hello" })

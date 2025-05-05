open Fest

let () = test "equal" (fun () -> expect |> equal (4 - 3) 1)
let () = test "equal 2" (fun () -> expect |> equal ("f" ^ "oo") "foo")
let () = test "ok" (fun () -> expect |> ok (true || false))

module Deep_strict_equal = struct
  type foo = Foo of int
  type bar = { foo : foo; bar : string }

  let assertion ~f () =
    expect
    |> f
         { foo = Foo 42; bar = "hello" }
         (let bar = { foo = Foo 40; bar = "hell" } in
          let bar = { bar with bar = bar.bar ^ "o" } in
          let bar =
            { bar with foo = (match bar.foo with Foo x -> Foo (x + 2)) }
          in
          bar)

  let () = test "deep_equal" (assertion ~f:deep_equal)
  let () = test "deepEqual" (assertion ~f:deepEqual)
end

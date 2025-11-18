open Mylib

let test_hello () =
  let result = Greet.hello "Alice" in
  Alcotest.(check string) "hello returns greeting" "Hello, Alice!" result

let test_goodbye () =
  let result = Greet.goodbye "Bob" in
  Alcotest.(check string) "goodbye returns farewell" "Goodbye, Bob!" result

let test_greet_many () =
  let names = ["Alice"; "Bob"; "Charlie"] in
  let result = Greet.greet_many names in
  let expected = "Hello, Alice!\nHello, Bob!\nHello, Charlie!" in
  Alcotest.(check string) "greet_many greets all names" expected result

let () =
  let open Alcotest in
  run "Greet" [
    "basic", [
      test_case "hello" `Quick test_hello;
      test_case "goodbye" `Quick test_goodbye;
      test_case "greet_many" `Quick test_greet_many;
    ];
  ]

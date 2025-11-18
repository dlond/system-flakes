(** Simple greeting library *)

let hello name =
  Printf.sprintf "Hello, %s!" name

let goodbye name =
  Printf.sprintf "Goodbye, %s!" name

let greet_many names =
  List.map hello names
  |> String.concat "\n"

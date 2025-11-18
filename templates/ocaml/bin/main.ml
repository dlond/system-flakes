open Cmdliner
open Mylib

let greet name =
  Greet.hello name
  |> print_endline

let name_arg =
  let doc = "Name to greet" in
  Arg.(value & pos 0 string "World" & info [] ~docv:"NAME" ~doc)

let greet_cmd =
  let doc = "Greet someone by name" in
  let info = Cmd.info "myapp" ~version:"0.1.0" ~doc in
  Cmd.v info Term.(const greet $ name_arg)

let () = exit (Cmd.eval greet_cmd)

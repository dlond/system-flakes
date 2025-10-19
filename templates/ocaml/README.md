# OCaml Development Environment

OCaml learning environment with Jane Street Core/Async libraries pre-installed for interview preparation.

## Usage

```bash
# Initialize the environment
nix flake init -t github:dlond/system-flakes#ocaml
nix develop

# Start interactive REPL with Core
utop
# In utop:
#require "core";;
open Core;;

# Create a new project
dune init project my_project
cd my_project

# Build and run
dune build
dune exec ./bin/main.exe
```

## Quick Example in REPL

```ocaml
# Start utop and try Core immediately:
utop

#require "core";;
open Core;;

(* Jane Street style - using Core's List module *)
let sum = List.fold ~init:0 ~f:(+) [1;2;3;4;5];;

(* Using pipe operators *)
[1;2;3;4;5]
|> List.map ~f:(fun x -> x * 2)
|> List.filter ~f:(fun x -> x > 5);;

(* Time operations *)
let start = Time_ns.now ();;
let elapsed = Time_ns.diff (Time_ns.now ()) start;;
```

## Pre-Installed Jane Street Essentials

- **Core**: Enhanced standard library with better data structures
- **Core_unix**: Unix system programming utilities
- **Async**: Concurrent programming framework
- **PPX_jane**: Syntax extensions used at Jane Street

## Additional Packages via Opam

For learning and experimentation, you can install additional packages:

```bash
# Testing frameworks
opam install alcotest qcheck

# Benchmarking
opam install core_bench benchmark

# Data structures
opam install containers iter

# Web development
opam install dream cohttp-async
```

## Example: Order Book Implementation

```ocaml
(* lib/order_book.ml *)
open Core

type side = Buy | Sell [@@deriving sexp, compare]

type order = {
  id: int;
  price: float;
  quantity: int;
  side: side;
  timestamp: Time_ns.t;
} [@@deriving sexp, fields]

module Order_book = struct
  type t = {
    buy_orders: order list;
    sell_orders: order list;
  }

  let empty = { buy_orders = []; sell_orders = [] }

  let add_order book order =
    match order.side with
    | Buy ->
      { book with
        buy_orders =
          List.sort ~compare:(fun a b ->
            Float.compare b.price a.price)
          (order :: book.buy_orders) }
    | Sell ->
      { book with
        sell_orders =
          List.sort ~compare:(fun a b ->
            Float.compare a.price b.price)
          (order :: book.sell_orders) }

  let match_orders book =
    match book.buy_orders, book.sell_orders with
    | [], _ | _, [] -> book, []
    | best_buy :: _, best_sell :: _ ->
      if Float.(best_buy.price >= best_sell.price) then
        (* Execute trade *)
        let executed_qty = Int.min best_buy.quantity best_sell.quantity in
        (* Return updated book and trades *)
        book, [(best_buy, best_sell, executed_qty)]
      else
        book, []
end
```

## Testing Example

```ocaml
(* test/test_order_book.ml *)
open Core
open Alcotest

let test_empty_book () =
  let book = Order_book.empty in
  check (list int) "no buy orders" []
    (List.map ~f:(fun o -> o.id) book.buy_orders);
  check (list int) "no sell orders" []
    (List.map ~f:(fun o -> o.id) book.sell_orders)

let test_suite = [
  "Order Book", [
    test_case "empty book" `Quick test_empty_book;
  ]
]

let () = Alcotest.run "Order Book Tests" test_suite
```

## Learning Path

1. **Basics**: OCaml syntax, pattern matching, type system
2. **Data structures**: Implement maps, heaps, tries, queues
3. **Functional patterns**: Monads, functors, applicatives
4. **Concurrency**: Build concurrent systems with Async
5. **Performance**: Optimization and benchmarking

## Resources

- [Real World OCaml](https://dev.realworldocaml.org/)
- [OCaml.org Tutorials](https://ocaml.org/docs)
- [Core Documentation](https://ocaml.org/p/core/latest/doc/index.html)
- [Async Documentation](https://ocaml.org/p/async/latest/doc/index.html)
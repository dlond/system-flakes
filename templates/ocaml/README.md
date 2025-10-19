# OCaml Development Environment

Complete OCaml development environment with Core libraries for functional programming and systems development.

## Usage

```bash
# Initialize the environment
nix flake init -t github:dlond/system-flakes#ocaml
nix develop

# Start interactive REPL
utop

# Create a new project
dune init project my_project

# Build and run
dune build
dune exec ./main.exe
```

## Included Libraries

- **Core**: Alternative standard library with additional data structures
- **Async**: Concurrent programming framework
- **PPX**: Syntax extensions for metaprogramming
- **Testing**: Alcotest, QCheck for property-based testing
- **Benchmarking**: Core_bench for performance analysis
- **Data structures**: Containers, Iter libraries

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
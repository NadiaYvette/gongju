# gongju

**Pure type-level utility functions, arity composition, and positional combinators for Haskell.**

`gongju` (공구 / 工具, Korean for "tools" or "implements") replaces Template Haskell arity splices (like `composition-extra`) and finite tuple generics (like `tuple-sop`) with pure type-level Peano induction, bidirectional functional dependencies, and type-safe curried argument permutations.

---

## Key Features

1. **TypeLits to Peano Bridge:** Ergonomic `@n` type applications (`compN @3`, `slipr @2`) backed by structural inductive Peano data kinds (`'Z | 'S Peano`).
2. **Variadic Arity Composition:** Composing unary functions with $n$-ary curried functions with bidirectional functional dependencies (`compN @n`, `fmapN @n`).
3. **Positional Combinators:** Pulling arguments to the front (`slipr @n`), pushing them deeper (`slipl @n`), and swapping adjacent arguments (`twist @n`) directly on curried function arrows without heap allocations.
4. **Arbitrary Argument Permutation:** Reordering curried function arguments via positional index lists (`permute @'[2, 0, 1]`) with support for duplicate argument types and partial permutations.
5. **Grand Unified Tape Engine:** Open-world composition over pure and monadic/comonadic effects using visible-forall `(.@)` and `withOps`.

---

## Quick Start

```haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

import Gongju.Core

main :: IO ()
main = do
  -- 1. Variadic composition over a 3-argument function:
  let add3 x y z = (x + y + z :: Int)
  print (compN @3 (* 2) add3 1 2 3) -- Prints 12

  -- 2. Permuting arguments of a function:
  let f x y z = (x, y, z)
  print (permute @'[2, 0, 1] f True 10 "gongju") -- Prints (10, "gongju", True)

  -- 3. Tape-driven composition:
  let comp = ((+ 1) .@ [P, P]) (+)
  print (comp 5 10) -- Prints 16
```

---

## Documentation & Reading Order

1. [`docs/INDEX.md`](docs/INDEX.md) — Technical documentation index.
2. [`docs/TUTORIAL.md`](docs/TUTORIAL.md) — Comprehensive hands-on tutorial.
3. [`docs/notes/GONGJU_DESIGN.md`](docs/notes/GONGJU_DESIGN.md) — Canonical design monograph and type-level invariants.
4. [`AGENTS.md`](AGENTS.md) — Advisory guidance for AI coding assistants.

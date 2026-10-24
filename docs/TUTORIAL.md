# gongju Tutorial — Hands-On Guide to Type-Level Utilities

`gongju` (공구 / 工具, tools/implement) replaces Template Haskell splices and finite tuple generics with inductive Peano typeclasses, bidirectional functional dependencies, and type-safe argument permutations.

---

## 1. Variadic Arity Composition (`compN`)

In standard Haskell, composing unary functions with multi-argument curried functions requires nested dots:
- 1 argument: `f . g`
- 2 arguments: `(f .) . g` or `f .: g`
- 3 arguments: `((f .) .) . g` or `f ..: g`

With `gongju`, arity composition is indexed dynamically by a type-level natural `@n`:

```haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

import Gongju.Core

-- Unary function:
let display :: Int -> String
    display x = "Result: " ++ show x

-- 3-argument function:
let volume :: Int -> Int -> Int -> Int
    volume w h d = w * h * d

-- Compose display over volume:
let displayVolume = compN @3 display volume
```

`displayVolume 2 3 4` evaluates to `"Result: 24"`.

---

## 2. Positional Curried Arrow Manipulation

Instead of converting curried functions into tuples, `gongju` allows pulling, pushing, and transposing arguments directly:

### Yanking (`slipr @n`)
Pull the $n$-th argument (0-indexed) to position 0:

```haskell
let format x y z = (x, y, z)
-- Pull argument 2 (z) to the front:
let pulled = slipr @2 format
-- pulled z x y == (x, y, z)
```

### Transposing Adjacent Arguments (`twist @n`)
Swap adjacent arguments at depth $n$ and $n + 1$:

```haskell
let sub x y = x - y
-- Swap arguments at position 0 and 1 (standard flip):
twist @0 sub 10 30 -- Result: 20
```

---

## 3. Arbitrary Argument Permutation (`permute`)

Permute curried functions of arbitrary arities by specifying a type-level list of original 0-indexed positions:

```haskell
let f a b c d = (a, b, c, d)

-- Reorder to [3, 0, 2, 1]:
let g = permute @'[3, 0, 2, 1] f
-- g d a c b == (a, b, c, d)
```

Notice that duplicate types (e.g. `Int -> Int -> Int -> Int -> r`) are disambiguated positionally rather than by type search.

---

## 4. Heterogeneous Lists & Currying (`curryH`, `uncurryH`)

Bridge curried arrows to first-class argument lists:

```haskell
let add (x :> y :> HNil) = x + y :: Int
let curried = curryH add
curried 10 20 -- Result: 30
```

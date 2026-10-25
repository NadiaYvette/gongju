# gongju Tutorial — Hands-On Guide to Type-Level Utilities & The Tape Engine

`gongju` (공구 / 工具, tools/implement) is a modern type-level utility library for Haskell.
It replaces Template Haskell splices (like `composition-extra`) and finite tuple generics (like `tuple-sop`)
with pure type-level Peano induction, bidirectional functional dependencies, an open-world tape engine,
and seamless integration with canonical Hackage categorical libraries.

---

## 1. Quick Setup & Required Extensions

All functionality is accessible via a single top-level module:

```haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE TypeApplications #-}

import Gongju.Core
```

For custom instances or advanced type-level pipelines, enabling `TypeFamilies` and `UndecidableInstances` is standard.

---

## 2. Variadic Arity Composition (`compN`, `fmapN`)

In standard Haskell, composing a unary function with multi-argument curried functions requires repetitive dots:
- 1 argument: `f . g`
- 2 arguments: `(f .) . g` or `f .: g`
- 3 arguments: `((f .) .) . g` or `f ..: g`

With `gongju`, composition is indexed dynamically by a visible type-level natural `@n`:

```haskell
-- Unary formatter:
display :: Int -> String
display x = "Result: " ++ show x

-- 3-argument function:
volume :: Int -> Int -> Int -> Int
volume w h d = w * h * d

-- Compose display over volume:
displayVolume :: Int -> Int -> Int -> String
displayVolume = compN @3 display volume
-- displayVolume 2 3 4 ==> "Result: 24"
```

Similarly, nested functor mapping (`fmapN @n`) maps a transformation through $n$ layers of nested functors:

```haskell
let nested = Just [1, 2, 3 :: Int]
fmapN @2 (+ 10) nested -- ==> Just [11, 12, 13]
```

Full bidirectional functional dependencies ensure type inference propagates symmetrically in both directions.
See Note [Variadic Composition Bidirectional Fundeps] [ref:note-variadic-composition-fundeps].

---

## 3. Positional Combinators & In-Place Arrow Manipulation

Rather than packing arguments into intermediate tuples or lists, `gongju` provides combinators that operate directly on curried function arrows `(a -> r)`:

### Yanking (`slipr @n`)
Pulls the $n$-th argument (0-indexed) to position 0:

```haskell
let tuple3 x y z = (x, y, z)
-- Pull argument 2 (z) to position 0:
let pulled = slipr @2 tuple3
-- pulled True 42 "hello" ==> (42, "hello", True)
```

### Shoving (`slipl @n`)
Pushes argument 0 deeper to position $n$:

```haskell
let sub x y = (x - y :: Int)
-- Push argument 0 to position 1:
let shoved = slipl @1 sub
-- shoved 5 20 ==> 15  (20 - 5)
```

### Swapping Adjacent Arguments (`twist @n`)
Swaps adjacent arguments at depth $n$ and $n + 1$:

```haskell
let sub x y = (x - y :: Int)
-- Swap arguments 0 and 1 (standard flip):
twist @0 sub 5 20 -- ==> 15
```

See Note [Positional Curried Arrow Manipulation] [ref:note-positional-arrow-manipulation].

---

## 4. Arbitrary Argument Permutation (`permute`)

Permute curried functions of arbitrary arities by specifying a type-level list of original 0-indexed positions:

```haskell
let f a b c d = (a, b, c, d)

-- Reorder arguments from [0, 1, 2, 3] to [2, 0, 3, 1]:
let g = permute @'[2, 0, 3, 1] f
-- g "c" "a" "d" "b" ==> ("a", "b", "c", "d")
```

Crucially, duplicate argument types (e.g. `Int -> Int -> Int -> r`) are disambiguated positionally without type-search ambiguity. Under GHC `-O2`, `permute` simplifies into inlined lambda applications with zero runtime overhead.
See Note [Iterated Yank Index Adjustment] [ref:note-iterated-yank-adjustment].

---

## 5. The Grand Unified Open-World Tape Engine (`withOps`, `(.@)`)

The open-world tape engine replaces rigid ad-hoc composition splices with a programmable, extensible state machine driven by an open list of operation mode tags:

### Visible Infix Tape Syntax (`(.@)`)

```haskell
-- 1. Pure argument consumption (P):
let add3 x y z = (x + y + z :: Int)
let h = ((+ 100) .@ [P, P, P]) add3
h 10 20 30 -- ==> 160

-- 2. Explicit positional permutation tags (i # P):
let tuple3 x y z = (x, y, z)
let p = (id .@ [2 # P, 0 # P, 1 # P]) tuple3
p True (42 :: Int) "gongju" -- ==> (42, "gongju", True)

-- 3. Monadic binding on the tape (M):
let mAction :: Int -> Int -> [Int]
    mAction x y = [x + y, x * y]
let mComp = (fmap show .@ [P, M]) mAction
mComp 3 [10, 20 :: Int] -- ==> ["[13,30]", "[23,60]"]
```

### Monadic Join (`J`) & Layered Lifting (`L sub`)
Stack-modifying operations allow collapsing nested return effects (`J`) or lifting transformations along specific functor paths (`L '[F]`):

```haskell
-- withOps evaluates the tape directly:
withOps [P, P] id (+) 10 20 -- ==> 30
```

---

## 6. Contravariant Syntax Grids (`Gongju.Contravariant`)

Contravariant function composition corresponds to pre-composing transformations onto argument positions of multi-argument functions:

### Positional Pre-Composition (`precomposeAt @n`, `(-.)`, `(-.*)`, `(-.**)`)

```haskell
let add3 x y z = (x + y + z :: Int)

-- Pre-compose (* 10) onto argument slot 1 (0-indexed):
let f1 = precomposeAt @1 (* 10) add3
f1 1 2 3 -- ==> 24  (1 + 20 + 3)

-- Using the infix syntax grid:
let f2 = (* 10) -.* add3
f2 1 2 3 -- ==> 24

-- Pre-compose onto argument slot 2:
let f3 = (* 100) -.** add3
f3 1 2 3 -- ==> 303  (1 + 2 + 300)
```

### 2D Function Splicing Grid (`spliceAt @n @m`)
Splices an $m$-ary function directly into argument slot $n$ of an outer function:

```haskell
let add3 x y z = (x + y + z :: Int)
let mult2 u v = (u * v :: Int)

-- Splice 2-argument mult2 into argument slot 1 of 3-argument add3:
let spliced = spliceAt @1 @2 mult2 add3
-- Arguments become: x -> (u -> v) -> z
spliced 10 3 4 5 -- ==> 27  (10 + (3 * 4) + 5)
```

See Note [Contravariant Positional Pre-Composition] [ref:note-contravariant-precomposition].

### Nested Contravariant Alternating Parity Stacks (`contramapN @n`)
Mapping through nested contravariant functors flips arrow variance at each step:
- Depth 1 (`(<-$>)`): Contravariant reversal (`a -> b` maps `f b -> f a`)
- Depth 2 (`(<-$$>)`): Covariant cancellation (`a -> b` maps `f (g a) -> f (g b)`)
- Depth 3 (`(<-$$$>)`): Contravariant reversal (`a -> b` maps `f (g (h b)) -> f (g (h a))`)

```haskell
-- 1 layer:
let isPositive = Predicate (> (0 :: Int))
let p1 = (* 2) <-$> isPositive
getPredicate p1 5 -- ==> True

-- 2 layers (two reversals cancel into a covariant mapping!):
let pp = Predicate (\(Predicate p) -> p (10 :: Int)) :: Predicate (Predicate Int)
let pp' = (* 2) <-$$> pp
getPredicate pp' (Predicate (> 15)) -- ==> True  (10 * 2 = 20 > 15)
```

See Note [Contravariant Functor Alternating Parity] [ref:note-contravariant-alternating-parity].

---

## 7. Comonads & Distributive Commutation (`Gongju.Comonad`)

Integrates canonical `Control.Comonad.Comonad`, `Data.Distributive.Distributive`, and `Data.Functor.Rep.Representable`:

### Cokleisli Extension (`W`)
Extend cokleisli functions across comonadic arguments:

```haskell
let wAction :: [Int] -> Int -> String
    wAction xs multiplier = show (sum xs * multiplier)
-- Using W tag to extend comonad:
let wComp = (fmap (++ "!") .@ [W, P]) wAction
```

### Commuting Representable Effects Outside a Comonad (`PullDist`)
Commutes a representable effect (e.g. Reader) outside a comonad without requiring Traversable instances:

```haskell
-- PullDist shifts Distributive layers outward:
let comp = withOps [W, P, PullDist] id g
```

---

## 8. Canonical Adjunctions & Dual Annihilation (`Gongju.Adjunction`)

Integrates canonical `Data.Functor.Adjunction.Adjunction` (`((,) e)` $\dashv$ `((->) e)`):

### Dual Pairing Annihilation (`zapLR`, `zapRL`)
Pairs a left adjoint context `l (a -> b)` with a right adjoint context `r a` and annihilates both into pure `b`:

```haskell
-- zapLR: left adjoint (,) against right adjoint (->):
let pair = (10 :: Int, length :: String -> Int)
let f e = replicate e 'x'
zapLR pair f -- ==> 10

-- zapRL: right adjoint (->) against left adjoint (,):
let g :: Int -> String -> Int
    g e str = length str + e
zapRL g (10 :: Int, "hello") -- ==> 15
```

### Adjunction Counit on the Tape (`AdjC`)

```haskell
let counitTarget = (5 :: Int, (+ 10) :: Int -> Int)
withOps [AdjC] id counitTarget -- ==> 15
```

---

## 9. Kan Extensions, Yoneda & Codensity Fusion (`Gongju.Kan`)

Integrates canonical `Data.Functor.Kan.Ran`, `Data.Functor.Kan.Lan`, `Data.Functor.Yoneda`, and `Control.Monad.Codensity`:

### Universal Ran and Lan Reductions

```haskell
-- Right Kan extension unit & counit:
let ranVal = ranUnit (Identity (42 :: Int))
runIdentity (ranCounit ranVal) -- ==> 42

-- Left Kan extension unit & counit:
let lanVal = lanUnit (Identity (99 :: Int)) :: Lan Identity Identity (Identity Int)
runIdentity (lanCounit lanVal) -- ==> 99
```

### $O(1)$ Functor Mapping Fusion (Yoneda & Coyoneda)
Fuse arbitrary chains of `fmap` into a single continuation-passing representation:

```haskell
let yon = liftYoneda [1, 2, 3 :: Int]
let yonMapped = fmap (* 2) yon
lowerYoneda yonMapped -- ==> [2, 4, 6]
```

### $O(1)$ Monadic Bind CPS Optimization (Codensity)
Transforms right-associated monadic bind chains into $O(1)$ CPS continuations:

```haskell
let cod = liftCodensity (Just (100 :: Int))
let codBound = cod >>= \x -> pure (x + 23)
lowerCodensity codBound -- ==> Just 123
```

---

## 10. Canonical Profunctor Mapping (`Gongju.Profunctor`)

Integrates canonical `Data.Profunctor.Profunctor` into Gongju's mapping engine:

```haskell
let f = (+ 10) :: Int -> Int

-- Contravariant pre-processing of argument 1 (lmap):
let g1 = mapPath @'[P1] (* 2) f
g1 5 -- ==> 20  ((5 * 2) + 10)

-- Covariant post-processing of return value (rmap):
let g2 = mapPath @'[P2] (* 2) f
g2 5 -- ==> 30  ((5 + 10) * 2)

-- Simultaneous bidirectional transformation (dimap):
let g3 = dimap (* 2) show f
g3 5 -- ==> "20"
```

---

## 11. Positional Monadic Binding & Lifting Masks (`Gongju.Monad`)

Replaces Template Haskell monadic splices (such as `Control.Monad.Syntax` in `composition-extra`) with two-phase Peano induction, multi-slot boolean lifting masks, and arity-indexed Kleisli composition.

### Two-Phase Positional Monadic Binding (`bindPos`, `bindAt`)

When binding a monadic value into a multi-argument function `f :: a -> b -> c -> m d`:
- **Tail binds** (`after = 0`): `bindAt @n` binds the argument at slot `n`.
  - `(==<<)` and `(>>==)`: slot 1
  - `(===<<)` and `(>>===)`: slot 2
  - `(====<<)` and `(>>====)`: slot 3
- **Interior binds** (`after > 0`): `bindPos @before @after` skips `before` leading pure arguments and floats `after` trailing pure arguments outside `(>>=)`.
  - `(=.=<<)` and `(>>=.=)`: slot 1 of 3 (`before = 1, after = 1`)
  - `(==.<<)` / `(=..<<)` and `(>>.==)` / `(>>..=)`: slot 0 of 3 (`before = 0, after = 2`)

```haskell
let add3 x y z = pure (x + y + z) :: Maybe Int

-- Tail bind at slot 2:
(add3 ===<< Just 10) 1 2 -- ==> Just 13

-- Interior bind at slot 1 (middle argument):
(add3 =.=<< Just 20) 1 3 -- ==> Just 24

-- Interior bind at slot 0 (leading argument):
(add3 ==.<< Just 10) 2 3 -- ==> Just 15
```

See Note [Positional Monadic Curried Binding] [ref:note-positional-monadic-binding].

### Multi-Slot Monadic Lifting Masks (`liftMask`)

With the promoted two-element kind `ArgMode = Pure | Monadic` (aliases `PArg`, `MArg`), any arbitrary subset of curried arguments can be lifted into `Monad m` simultaneously in a single pass:

```haskell
let f a b c = pure (a ++ ":" ++ show b ++ ":" ++ c) :: [String]

-- Lift 1st and 3rd arguments to monadic lists, leaving 2nd argument pure:
let g = liftMask @'[MArg, PArg, MArg] f
g ["a", "b"] 42 ["x", "y"]
-- ==> ["a:42:x", "a:42:y", "b:42:x", "b:42:y"]
```

See Note [Multi-Slot Monadic Lifting Masks] [ref:note-multislot-monadic-masks].

### Arity-Indexed Kleisli Composition (`bindKleisliN`, `liftPureN`)

Compose Kleisli arrows or lift pure functions across arbitrary curried arities:

```haskell
-- Lift pure binary function into Applicative:
liftPureN @2 (+) 3 4 -- ==> Just 7 :: Maybe Int

-- Post-compose Kleisli arrow checkEven after binary monadic function:
let f x y = Just (x + y :: Int)
let checkEven z = if even z then Just z else Nothing
(checkEven <=<. f) 2 4 -- ==> Just 6
(checkEven <=<. f) 2 3 -- ==> Nothing
```

---

## 12. Reading Order & Cross-References

- [`docs/INDEX.md`](INDEX.md) — Documentation index and corpus map.
- [`docs/notes/GONGJU_DESIGN.md`](notes/GONGJU_DESIGN.md) — Canonical architectural decisions (D1–D9).
- [`docs/NEWBIE_GUIDE.md`](NEWBIE_GUIDE.md) — Fast symbol navigation and token-conservation guide.
- [`README.md`](../README.md) — Project status and quickstart.
- [`PLAN.md`](../PLAN.md) — Strategic engineering roadmap.
- [`STATE.md`](../STATE.md) — Active operational frontier.

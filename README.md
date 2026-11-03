# gongju

**Pure type-level utility functions, arity composition, positional combinators, and structured text utilities for Haskell.**

`gongju` (공구 / 工具, tools/implements) replaces Template Haskell arity splices (e.g. `composition-extra`) and finite tuple generics (e.g. `tuple-sop`) with pure type-level Peano induction, bidirectional functional dependencies, and type-safe curried argument permutations. It features an open-world tape engine, 2D contravariant syntax grids, multi-slot monadic lifting masks, curried profunctor strand reordering, and zero-cost Core inlining.

---

## The Name & Philological Grounding

The project takes its name from the Korean word **공구** (**工具**, *gongju*), meaning "tools," "implements," or "instruments of manufacture."

In traditional East Asian craftsmanship and metallurgy, *gongju* refers specifically to the secondary implements forged by toolmakers to shape, measure, and assemble primary works—the master gauges, clamps, and shaping irons without which intricate joinery is impossible.

In type-theoretic functional programming, `gongju` serves an identical purpose:
- Rather than forcing engineers to rely on brittle macro expansions, untyped AST generation, or external Template Haskell preprocessors that emit hundreds of fixed-arity splices, `gongju` builds the **tools of functional composition directly out of Haskell's pure type system**.
- By leveraging structural induction over Peano naturals, bidirectional functional dependencies, and GHC's native Core simplifier, `gongju` proves that high-arity composition and arbitrary argument permutations can be completely type-safe, compile-time verified, and executed with **zero runtime overhead**.

---

## Core Motivation & Architecture

### The Limitations of Prior Art

Developers working with multi-argument curried functions in Haskell have historically faced two painful compromises:

1. **Template Haskell Arity Generation (e.g. `composition-extra`):**
   - Libraries generate combinatorial explosions of fixed operators (`(.:)`, `(..:)`, `(...:)`, `(>>==)`, `(>>===)`).
   - Each arity requires bespoke code generation, compile-time bloat, and fragile upper bounds.
   - Type inference across higher-order boundaries is limited, and arity cannot be parameterized or abstracted dynamically.

2. **Generic Tuple Coercions (e.g. `tuple-sop`):**
   - Uncurrying functions into $n$-tuples using generic representations incurs boxing overhead, tuple size limits (typically arities 2 to 24), and impedance mismatches.
   - Crucially, tuple-based and type-directed indexing fails when a function contains **duplicate argument types** (e.g. `Int -> String -> Int -> Bool` cannot distinguish the first `Int` from the third `Int` via type search).

### The Gongju Solution

`gongju` eliminates both limitations through an integrated architecture:

1. **Pure Peano Structural Induction:** All combinators recurse over an inductive data kind (`data Peano = Z | S Peano`). Non-overlapping inductive instances guarantee deterministic constraint solving without stuck type families.
2. **Ergonomic TypeLits Bridge:** Developers write natural `@n` type applications (`compN @3`, `slipr @2`, `permute @'[2, 0, 1]`), which closed type families convert to Peano kinds at compile time.
3. **Bidirectional Functional Dependencies:** Class definitions enforce bidirectional fundeps so type inference propagates symmetrically: forward from argument types to return values, and backward from expected contexts into polymorphic functions.
4. **In-Place Arrow Manipulation:** Combinators (`slipr`, `slipl`, `twist`) manipulate curried function arrows `(a -> b -> ... -> r)` directly, avoiding any heap allocation or tuple packaging.
5. **Positional Disambiguation:** Permutations and pre-compositions index by zero-based argument positions rather than types, cleanly handling duplicate types and partial permutations.
6. **Zero-Cost Core Simplification:** Every inductive combinator across the entire engine is marked `{-# INLINE #-}`, allowing GHC's simplifier under `-O2` to eliminate all typeclass dictionaries, intermediate closures, and unboxed structures into primitive lambdas.

---

## Multi-Package Catalog

The repository is organized as a modular multi-package Cabal project:

| Package | Directory | Description | Hackage Status |
| :--- | :--- | :--- | :--- |
| **`gongju`** | [`packages/gongju/`](packages/gongju/) | Core type-level engine, Peano bridge, compositional combinators, positional manipulators, permutations, open-world tape engine, contravariant grids, monadic masks, profunctor arrow/strand permutations, and canonical Hackage integrations. | Ready (0.1.0.0) |
| **`gongju-text`** | [`packages/gongju-text/`](packages/gongju-text/) | High-level text processing refinements, non-empty text utilities (`NonNull Text`), stanza chunking, and hierarchical indentation layout parsing. | Ready (0.1.0.0) |

---

## Key Subsystems & Worked Examples

### 1. Variadic Arity Composition (`Gongju.Composition`)

Compose unary transformations over curried functions of arbitrary arities, or map through nested functor layers:

```haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

import Gongju.Core

-- Compose unary formatter over 3-argument function:
volume :: Int -> Int -> Int -> Int
volume w h d = w * h * d

displayVolume :: Int -> Int -> Int -> String
displayVolume = compN @3 (\v -> "Volume: " ++ show v) volume

-- displayVolume 2 3 4 ==> "Volume: 24"

-- Map through 3 layers of nested Functors:
let nested = Just [Right (42 :: Int)]
fmapN @3 (* 2) nested -- ==> Just [Right 84]
```

### 2. Positional Arrow Manipulation (`Gongju.Positional`)

Manipulate curried arguments directly on the function arrow without allocating intermediate tuples:

```haskell
-- Yank argument 2 (0-indexed) to position 0:
let tuple3 x y z = (x, y, z)
let yanked = slipr @2 tuple3
-- yanked True 42 "hello" ==> (42, "hello", True)

-- Shove argument 0 deeper to position 1:
let sub x y = (x - y :: Int)
let shoved = slipl @1 sub
-- shoved 5 20 ==> 15  (20 - 5)

-- Swap adjacent arguments at depth 0 (standard flip):
twist @0 sub 5 20 -- ==> 15
```

### 3. Arbitrary Argument Permutation (`Gongju.Permute`)

Reorder curried function arguments according to a type-level index list. Handles duplicate argument types and partial permutations with mathematical totality:

```haskell
let f a b c d = (a, b, c, d)

-- Reorder arguments from [0, 1, 2, 3] to [2, 0, 3, 1]:
let g = permute @'[2, 0, 3, 1] f
-- g "c" "a" "d" "b" ==> ("a", "b", "c", "d")
```

### 4. The Grand Unified Open-World Tape Engine (`Gongju.Core`)

An open-world composition machine driven by explicit operation mode tags, evaluating compositions over pure, monadic, and comonadic effects:

```haskell
-- Pure argument consumption:
let add3 x y z = (x + y + z :: Int)
let h = ((+ 100) .@ [P, P, P]) add3
-- h 10 20 30 ==> 160

-- Explicit positional permutation on the tape:
let p = (id .@ [2 # P, 0 # P, 1 # P]) tuple3
-- p True (42 :: Int) "gongju" ==> (42, "gongju", True)

-- Monadic binding on the tape:
let mAction x y = [x + y, x * y]
let mComp = (fmap show .@ [P, M]) mAction
-- mComp 3 [10, 20 :: Int] ==> ["[13,30]", "[23,60]"]
```

### 5. Contravariant Syntax Grids (`Gongju.Contravariant`)

Pre-compose argument transformations onto specific argument slots or splice multi-argument functions directly into curried arrows:

```haskell
-- Positional pre-composition onto slot 1:
let add3 x y z = (x + y + z :: Int)
let f1 = precomposeAt @1 (* 10) add3
-- f1 1 2 3 ==> 24  (1 + 20 + 3)

-- Using the infix contravariant grid:
let f2 = (* 10) -.* add3
-- f2 1 2 3 ==> 24

-- 2D function splicing: splice 2-argument mult2 into slot 1 of 3-argument add3:
let mult2 u v = (u * v :: Int)
let spliced = spliceAt @1 @2 mult2 add3
-- spliced 10 3 4 5 ==> 27  (10 + (3 * 4) + 5)

-- Nested contravariant mapping with alternating parity:
let isPositive = Predicate (> (0 :: Int))
let p1 = (* 2) <-$> isPositive
-- getPredicate p1 5 ==> True
```

### 6. Positional Monadic Binding & Lifting Masks (`Gongju.Monad`)

Bind monadic values into multi-argument functions or lift subsets of arguments using boolean masks:

```haskell
let add3 x y z = pure (x + y + z) :: Maybe Int

-- Tail bind at slot 2:
(add3 ===<< Just 10) 1 2 -- ==> Just 13

-- Interior bind at slot 1 (middle argument):
(add3 =.=<< Just 20) 1 3 -- ==> Just 24

-- Multi-slot lifting mask: lift 1st and 3rd arguments to lists, leaving 2nd pure:
let f a b c = pure (a ++ ":" ++ show b ++ ":" ++ c) :: [String]
let g = liftMask @'[MArg, PArg, MArg] f
-- g ["a", "b"] 42 ["x", "y"] ==> ["a:42:x", "a:42:y", "b:42:x", "b:42:y"]
```

### 7. Profunctor Effect Handler Permutations (`Gongju.Profunctor`)

Reorder curried configuration parameters of effect handlers or permute right-nested tuple inputs of arrow strands:

```haskell
-- Reorder curried handler parameters:
let handler env1 env2 env3 = \(x :: Int) -> env1 ++ ":" ++ show env2 ++ ":" ++ env3 ++ ":" ++ show x
let handler' = permuteHandler @'[2, 0, 1] handler
-- handler' "c" "a" 42 10 ==> "a:42:c:10"

-- Permute arrow strand inputs consuming right-nested tuples:
let strand = \(z, (x, (y, ()))) -> show (x * 100 + y * 10 + z :: Int)
let strand' = permuteInputs @'[2, 0, 1] strand
-- strand' (1, (2, (3, ()))) ==> "123"
```

### 8. Structured Text Utilities (`Gongju.Text.*`)

Safe non-empty text operations, stanza splitting, and hierarchical indentation layout parsing:

```haskell
{-# LANGUAGE OverloadedStrings #-}

import Gongju.Text.NonEmpty (wordsNE)
import Gongju.Text.Stanza (stanzas, unStanza)
import Gongju.Text.Layout (parseBlocks, Block(..))

-- Non-empty word splitting:
wordsNE "hello   world" -- ==> Just ("hello" :| ["world"])

-- Stanza chunking:
let doc = "Line 1\nLine 2\n\nLine 3\n"
map unStanza (stanzas doc) -- ==> [["Line 1", "Line 2"], ["Line 3"]]

-- Hierarchical layout block parsing:
let raw = ["root", "  child 1", "  child 2", "    grandchild"]
parseBlocks raw -- ==> [Block 0 ["root"] [Block 2 ["child 1", "child 2"] [Block 4 ["grandchild"] []]]]
```

---

## Zero-Cost Inlining & GHC Core Simplification

A fundamental architectural invariant of `gongju` is **zero runtime penalty**:

- Every inductive combinator is annotated with `{-# INLINE #-}`.
- Under GHC `-O2`, the Simplifier completely beta-reduces the inductive typeclass dictionaries (`$fComposeN`, `$fPermute`, `$fYank`, `$fPrecomposeAt`, `$fBindPos`, etc.) and eliminates all residual dictionary arguments.
- The compiled GHC Core code is indistinguishable from hand-written, specialized monomorphic lambdas.

This guarantee is mechanically tested on every build by the automated Core inspection harness:

```bash
./bin/gongju-inspect-core
```

---

## Documentation Corpus & Reading Order

The technical documentation corpus is structured for progressive disclosure:

1. [`docs/INDEX.md`](docs/INDEX.md) — Comprehensive corpus inventory, audience reading paths, and package catalog.
2. [`docs/TUTORIAL.md`](docs/TUTORIAL.md) — Detailed hands-on tutorial with worked examples across all 12 subsystems.
3. [`docs/NEWBIE_GUIDE.md`](docs/NEWBIE_GUIDE.md) — Fast symbol navigation table and 15-minute quickstart.
4. [`docs/MAINTAINER_GUIDE.md`](docs/MAINTAINER_GUIDE.md) — Architectural invariants (I1–I8), verification gates, and triage runbooks.
5. [`docs/notes/GONGJU_DESIGN.md`](docs/notes/GONGJU_DESIGN.md) — Canonical design monograph detailing decisions D1–D11.
6. [`docs/notes/DOC_STRATEGY.md`](docs/notes/DOC_STRATEGY.md) — Documentation strategy, precedence rule, and lifecycle.
7. [`docs/notes/COMMIT_ATTRIBUTION.md`](docs/notes/COMMIT_ATTRIBUTION.md) — Linux kernel RFC 2822 trailer format standards.
8. [`AGENTS.md`](AGENTS.md) — Advisory operational rules and navigation funnels for AI coding assistants.

---

## Physical Verification Discipline

Before any commit or release, all 6 physical verification gates must pass cleanly:

```bash
./bin/gongju-verify
```

1. **Gate 1: HLint Static Analysis:** Zero hints allowed across all source modules (`.hlint.yaml`).
2. **Gate 2: Full Cabal Test Suite:** All test suites pass across all packages (`cabal test all`).
3. **Gate 3: Zero-Cost Core Inspection:** 0 residual dictionaries, 100% of pipelines simplified (`bin/gongju-inspect-core`).
4. **Gate 4: Tagref Cross-Reference Gate:** Zero dangling references and zero duplicate tags (`bin/gongju-tagref`).
5. **Gate 5: Markdown Link Integrity Gate:** Every relative link and heading anchor resolves (`bin/gongju-linkcheck`).
6. **Gate 6: CLOC Comment Density Gate:** Comment density satisfies documentation thresholds (`bin/gongju-cloc`).

---

## License & Attribution

- Licensed under the **European Union Public Licence (EUPL-1.2)** or **Apache License 2.0** (`LICENSE`).
- Copyright (c) 2026 Nadia Yvette Chambers.
- AI assistant contributions follow the RFC 2822 trailer format (`Assisted-by:`). See [`docs/notes/COMMIT_ATTRIBUTION.md`](docs/notes/COMMIT_ATTRIBUTION.md).

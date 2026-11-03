# Gongju Newbie Quickstart & Token-Conservation Guide

**Audience:** New human contributors and AI coding assistant drivers (Antigravity, Claude Code, Cursor, Aider).  
**Parent Strategy:** [`docs/notes/DOC_STRATEGY.md`](notes/DOC_STRATEGY.md)  
**Corpus Inventory:** [`docs/INDEX.md`](INDEX.md)  
**Interactive Tutorial:** [`docs/TUTORIAL.md`](TUTORIAL.md)  
**Maintainer Guide:** [`docs/MAINTAINER_GUIDE.md`](MAINTAINER_GUIDE.md)  

---

## 1. The Progressive Disclosure Funnel

To conserve context tokens, reduce latency, and prevent attention degradation, follow the 3-level progressive disclosure funnel:

```
Level 0: Global Navigation  (docs/INDEX.md, package overview)      →   ~10–50 tokens
Level 1: Structural Outline (module export lists, type headers)   →   ~100–250 tokens
Level 2: Targeted Slice     (view_file StartLine / EndLine)       →   ~200–500 tokens
```

- **Level 0 (Global):** Start by identifying the responsible module from the symbol table below.
- **Level 1 (Structural):** View only the module export header and type definitions.
- **Level 2 (Targeted):** Use line range slices (`StartLine` / `EndLine`) to examine the exact typeclass instance or helper function needed. Never read an entire module when a 20-line slice suffices.

---

## 2. Fast Package & Symbol Navigation

### Core Type-Level Library (`packages/gongju/`)

| If you are looking for... | Look in module | Source Location |
| :--- | :--- | :--- |
| `Peano`, `'Z`, `'S`, `ToPeano`, `FromPeano` | `Gongju.Peano` | [`packages/gongju/src/Gongju/Peano.hs`](../packages/gongju/src/Gongju/Peano.hs) |
| `compN`, `ComposeN`, `fmapN`, `FmapN` | `Gongju.Composition` | [`packages/gongju/src/Gongju/Composition.hs`](../packages/gongju/src/Gongju/Composition.hs) |
| `slipr` (`Yank`), `slipl` (`Shove`), `twist` (`Twist`) | `Gongju.Positional` | [`packages/gongju/src/Gongju/Positional.hs`](../packages/gongju/src/Gongju/Positional.hs) |
| `permute`, `Permute`, `Adjust`, `MapAdjust` | `Gongju.Permute` | [`packages/gongju/src/Gongju/Permute.hs`](../packages/gongju/src/Gongju/Permute.hs) |
| `IxFunctor`, `IxApplicative`, `IxMonad`, `IxComonad` | `Gongju.Indexed` | [`packages/gongju/src/Gongju/Indexed.hs`](../packages/gongju/src/Gongju/Indexed.hs) |
| `Comonad`, `Distributive`, `Representable`, `W`, `PullDist` | `Gongju.Comonad` | [`packages/gongju/src/Gongju/Comonad.hs`](../packages/gongju/src/Gongju/Comonad.hs) |
| `Adjunction`, `zapLR`, `zapRL`, `AdjU`, `AdjC` | `Gongju.Adjunction` | [`packages/gongju/src/Gongju/Adjunction.hs`](../packages/gongju/src/Gongju/Adjunction.hs) |
| `Ran`, `Lan`, `Yoneda`, `Coyoneda`, `Codensity`, `Density` | `Gongju.Kan` | [`packages/gongju/src/Gongju/Kan.hs`](../packages/gongju/src/Gongju/Kan.hs) |
| `Profunctor`, `dimap`, `CurriedCat`, `yankTuple`, `permuteTuple`, `permuteInputs`, `permuteHandler` | `Gongju.Profunctor` | [`packages/gongju/src/Gongju/Profunctor.hs`](../packages/gongju/src/Gongju/Profunctor.hs) |
| `precomposeAt`, `spliceAt`, `contramapN`, `(-.)`, `(-.*)`, `(<-$>)` | `Gongju.Contravariant` | [`packages/gongju/src/Gongju/Contravariant.hs`](../packages/gongju/src/Gongju/Contravariant.hs) |
| `bindPos`, `bindAt`, `liftMask`, `liftPureN`, `bindKleisliN`, `(==<<)`, `(=.=<<)` | `Gongju.Monad` | [`packages/gongju/src/Gongju/Monad.hs`](../packages/gongju/src/Gongju/Monad.hs) |
| Top-level re-exports & Grand Unified Tape Engine (`withOps`, `(.@)`) | `Gongju.Core` | [`packages/gongju/src/Gongju/Core.hs`](../packages/gongju/src/Gongju/Core.hs) |
| Core inspection test fixtures | `CoreInspection` | [`packages/gongju/test/CoreInspection.hs`](../packages/gongju/test/CoreInspection.hs) |
| Automated Core inspection verifier | Script | [`bin/gongju-inspect-core`](../bin/gongju-inspect-core) |
| Full test suite | `Main` (Test) | [`packages/gongju/test/Main.hs`](../packages/gongju/test/Main.hs) |

### Structured Text Library (`packages/gongju-text/`)

| If you are looking for... | Look in module | Source Location |
| :--- | :--- | :--- |
| `NonNull`, `fromText`, `toText`, `wordsNE`, `linesNE` | `Gongju.Text.NonEmpty` | [`packages/gongju-text/src/Gongju/Text/NonEmpty.hs`](../packages/gongju-text/src/Gongju/Text/NonEmpty.hs) |
| `Stanza`, `stanzas`, `stanzasSeq` | `Gongju.Text.Stanza` | [`packages/gongju-text/src/Gongju/Text/Stanza.hs`](../packages/gongju-text/src/Gongju/Text/Stanza.hs) |
| `IndentedLine`, `Block`, `parseIndentedLines`, `parseBlocks` | `Gongju.Text.Layout` | [`packages/gongju-text/src/Gongju/Text/Layout.hs`](../packages/gongju-text/src/Gongju/Text/Layout.hs) |
| Text test suite | `Main` (Test) | [`packages/gongju-text/test/Main.hs`](../packages/gongju-text/test/Main.hs) |

---

## 3. The Peano Induction Mental Model

Understanding how Gongju works requires understanding how GHC resolves inductive typeclasses over Peano numbers.

### The Problem with GHC.TypeLits.Nat
GHC's built-in `Nat` numbers (`0, 1, 2, ...`) are backed by arbitrary-precision integers in the compiler. GHC cannot pattern match on `n + 1` during typeclass instance resolution:
```haskell
-- This WILL NOT compile in standard GHC:
instance MyClass 0 where ...
instance MyClass (n + 1) where ... -- ERROR: Illegal type family application in instance head
```

### The Gongju Bridge
Gongju defines a structural Peano data kind in [`Gongju.Peano`](../packages/gongju/src/Gongju/Peano.hs):
```haskell
data Peano = Z | S Peano
```
Typeclasses then inductively match on `'Z` (base case) and `'S p` (inductive step):
```haskell
-- Base case (arrived at target position):
instance Yank 'Z a (a -> r) r where
  slipr0 f a = f a

-- Inductive step (recurse deeper into the arrow spine):
instance Yank p a rest r => Yank ('S p) a (x -> rest) (x -> r) where
  slipr0 f a x = slipr0 @p (\rest' -> f rest' x) a
```
The closed type family `ToPeano n` translates numeric literals like `@2` into `'S ('S 'Z)`. The user writes clean numbers; the compiler resolves clean, non-overlapping inductive instances.

---

## 4. 15-Minute Quickstart Recipes

### Recipe 1: Compose over a Multi-Argument Function
```haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}
import Gongju.Core

let add3 x y z = (x + y + z :: Int)
let display = show :: Int -> String

-- Compose display after add3:
let f = compN @3 display add3
f 10 20 30 -- ==> "60"
```

### Recipe 2: Permute Function Arguments Point-Free
```haskell
let format name age city = name ++ " is " ++ show age ++ " years old and lives in " ++ city
-- Original arguments: 0 = name (String), 1 = age (Int), 2 = city (String)
-- Suppose we want to pass: city (2), name (0), age (1)
let format' = permute @'[2, 0, 1] format
format' "Berlin" "Alice" (30 :: Int) -- ==> "Alice is 30 years old and lives in Berlin"
```

### Recipe 3: Pre-Compose an Argument Transformation
```haskell
let greet name (score :: Int) = name ++ ": " ++ show score
-- Double the score before passing it to greet:
let greetWithBonus = (* 2) -.* greet
greetWithBonus "Bob" 50 -- ==> "Bob: 100"
```

### Recipe 4: Non-Empty Words and Stanzas
```haskell
import Gongju.Text.NonEmpty (wordsNE)
import Gongju.Text.Stanza (stanzas, unStanza)

-- Safe word splitting:
wordsNE "hello functional world" -- ==> Just ("hello" :| ["functional", "world"])

-- Split markdown or text into paragraphs:
let sample = "Para 1\nLine 2\n\nPara 2\nLine 2"
let paras = map unStanza (stanzas sample)
```

---

## 5. Next Steps

- For an in-depth exploration of every subsystem, read [`docs/TUTORIAL.md`](TUTORIAL.md).
- For design invariants and decision rationale, read [`docs/notes/GONGJU_DESIGN.md`](notes/GONGJU_DESIGN.md).
- For verification commands and maintenance rules, read [`docs/MAINTAINER_GUIDE.md`](MAINTAINER_GUIDE.md).

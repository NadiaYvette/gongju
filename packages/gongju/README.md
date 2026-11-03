# gongju

**Pure type-level utility functions, arity composition, and positional combinators for Haskell.**

`gongju` (공구 / 工具, tools/implement) replaces Template Haskell arity generation (like `composition-extra`) and tuple generics (like `tuple-sop`) with pure type-level Peano induction, bidirectional functional dependencies, and type-safe argument permutations.

---

## Key Modules

- **[`Gongju.Core`](src/Gongju/Core.hs)** — Re-exports all core modules and the Grand Unified Open-World Tape Engine (`withOps`, `(.@)`).
- **[`Gongju.Peano`](src/Gongju/Peano.hs)** — Type-level Peano numbers (`'Z`, `'S`), compile-time natural conversion (`ToPeano`, `FromPeano`), and reflection typeclasses.
- **[`Gongju.Composition`](src/Gongju/Composition.hs)** — Variadic function composition (`compN @n`, `ComposeN`) and nested functor mapping (`fmapN @n`, `FmapN`) with bidirectional functional dependencies.
- **[`Gongju.Positional`](src/Gongju/Positional.hs)** — In-place curried arrow combinators without heap allocation:
  - `slipr @n` (`Yank`): Pull the $n$-th argument to position 0.
  - `slipl @n` (`Shove`): Push argument 0 deeper to position $n$.
  - `twist @n` (`Twist`): Swap adjacent arguments at depth $n$ and $n + 1$.
- **[`Gongju.Permute`](src/Gongju/Permute.hs)** — Arbitrary argument permutation (`permute @'[2, 0, 1]`, `Permute`) with full disambiguation of duplicate argument types.
- **[`Gongju.Indexed`](src/Gongju/Indexed.hs)** — Indexed monads, indexed applicatives, and indexed comonads (`IxFunctor`, `IxApplicative`, `IxMonad`, `IxComonad`).
- **[`Gongju.Comonad`](src/Gongju/Comonad.hs)** — Integrations with `comonad` and `distributive` (`W`, `PullDist`, `Representable`).
- **[`Gongju.Adjunction`](src/Gongju/Adjunction.hs)** — Categorical adjunctions and dual pairing annihilation (`zapLR`, `zapRL`, `AdjU`, `AdjC`).
- **[`Gongju.Kan`](src/Gongju/Kan.hs)** — Kan extensions, Yoneda and Coyoneda $O(1)$ fusion, and Codensity CPS monad optimization (`Ran`, `Lan`, `Yoneda`, `Codensity`).
- **[`Gongju.Profunctor`](src/Gongju/Profunctor.hs)** — Profunctor mapping grids (`dimap`), Curried category arrow permutation (`CurriedCat`, `yankCat`, `permuteCat`), right-nested tuple spine arrow permutations (`yankTuple`, `permuteTuple`), and profunctor strand input/output reordering (`permuteInputs`, `permuteOutputs`, `permuteHandler`).
- **[`Gongju.Contravariant`](src/Gongju/Contravariant.hs)** — Contravariant syntax grids: positional pre-composition (`precomposeAt @n`, `(-.)`, `(-.*)`), 2D function splicing (`spliceAt @n @m`), and nested contravariant functor mapping with alternating parity (`contramapN @n`, `(<-$>)`, `(<-$$>)`).
- **[`Gongju.Monad`](src/Gongju/Monad.hs)** — Two-phase positional monadic binding (`bindPos @before @after`, `bindAt @n`, `(==<<)`, `(=.=<<)`), multi-slot monadic lifting masks (`liftMask @'[MArg, PArg, MArg]`), and arity-indexed Kleisli composition (`liftPureN @n`, `bindKleisliN @n`, `(<=<.)`, `(.>=>)`).

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

## Zero-Cost Guarantee

Under GHC `-O2`, all combinators inline and simplify into primitive lambda applications with zero residual typeclass dictionaries, verified mechanically by `bin/gongju-inspect-core`.

---

## License

Licensed under the European Union Public Licence (EUPL-1.2) or Apache License 2.0.

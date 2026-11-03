# Changelog for `gongju`

All notable changes to the `gongju` package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to the Haskell Package Versioning Policy (PVP).

## [0.1.0.0] — 2026-10-24

### Added
- **`Gongju.Peano`**: Inductive Peano type kind (`Peano`, `'Z`, `'S`), compile-time natural bridge (`ToPeano`, `FromPeano`), and reflection typeclasses.
- **`Gongju.Composition`**: Variadic function composition (`compN @n`, `ComposeN`) and nested functor mapping (`fmapN @n`, `FmapN`) with bidirectional functional dependencies.
- **`Gongju.Positional`**: In-place curried arrow combinators without heap allocation:
  - `slipr @n` (`Yank`): Pull the $n$-th argument to position 0.
  - `slipl @n` (`Shove`): Push argument 0 deeper to position $n$.
  - `twist @n` (`Twist`): Swap adjacent arguments at depth $n$ and $n + 1$.
- **`Gongju.Permute`**: Arbitrary curried function argument permutation (`permute @indices`, `Permute`) via iterated `Yank` and index adjustment (`Adjust`, `MapAdjust`), with full support for duplicate argument types.
- **`Gongju.Indexed`**: Indexed monads, indexed applicatives, and indexed comonads (`IxFunctor`, `IxApplicative`, `IxMonad`, `IxComonad`).
- **`Gongju.Comonad`**: Canonical comonad and distributive integrations (`Comonad`, `Distributive`, `Representable`, `W`, `PullDist`).
- **`Gongju.Adjunction`**: Categorical adjunctions and dual pairing annihilation (`Adjunction`, `zapLR`, `zapRL`, `AdjU`, `AdjC`).
- **`Gongju.Kan`**: Right and Left Kan extensions, Yoneda and Coyoneda $O(1)$ fusion, and Codensity CPS monad optimization (`Ran`, `Lan`, `Yoneda`, `Coyoneda`, `Codensity`, `Density`).
- **`Gongju.Profunctor`**: Profunctor mapping grids (`dimap`, `lmap`, `rmap`), Curried category arrow permutation (`CurriedCat`, `yankCat`, `permuteCat`), right-nested tuple spine arrow permutations (`yankTuple`, `permuteTuple`), and profunctor strand input/output reordering (`permuteInputs`, `permuteOutputs`, `permuteHandler`).
- **`Gongju.Contravariant`**: Contravariant syntax grids: positional pre-composition (`precomposeAt @n`, `(-.)`, `(-.*)`, `(-.**)`), 2D function splicing (`spliceAt @n @m`), and nested contravariant functor mapping with alternating parity (`contramapN @n`, `(<-$>)`, `(<-$$>)`, `(<-$$$>)`).
- **`Gongju.Monad`**: Two-phase positional monadic binding (`bindPos @before @after`, `bindAt @n`, `(==<<)`, `(=.=<<)`, `(===<<)`), multi-slot monadic lifting masks (`liftMask @'[MArg, PArg, MArg]`), and arity-indexed Kleisli composition (`liftPureN @n`, `bindKleisliN @n`, `(<=<.)`, `(.>=>)`).
- **`Gongju.Core`**: Top-level re-exports and Grand Unified Open-World Tape Engine (`withOps`, `(.@)`).
- **Core Inspection Test Suite**: Automated verification harness ensuring zero residual dictionaries and complete inlining under GHC `-O2`.

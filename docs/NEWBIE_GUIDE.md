# Gongju Newbie Quickstart & Token-Conservation Guide

**Audience:** New human contributors and AI coding assistant drivers (Antigravity, Claude Code, Cursor, Aider).  
**Parent Strategy:** [`docs/notes/DOC_STRATEGY.md`](notes/DOC_STRATEGY.md)  
**Corpus Inventory:** [`docs/INDEX.md`](INDEX.md)  
**Interactive Tutorial:** [`docs/TUTORIAL.md`](TUTORIAL.md)  
**Maintainer Guide:** [`docs/MAINTAINER_GUIDE.md`](MAINTAINER_GUIDE.md)  

---

## 1. The Progressive Disclosure Funnel

To conserve context tokens and maintain reasoning sharpness, never dump entire modules into your working context.

```
Level 0: Global Navigation  (docs/INDEX.md, package overview)      →   ~10–50 tokens
Level 1: Structural Outline (module export lists, type headers)   →   ~100–250 tokens
Level 2: Targeted Slice     (view_file StartLine / EndLine)       →   ~200–500 tokens
```

---

## 2. Fast Package & Symbol Navigation

| If you are looking for... | Look in module | Source Location |
| :--- | :--- | :--- |
| `Peano`, `ToPeano`, `FromPeano` | `Gongju.Peano` | `packages/gongju/src/Gongju/Peano.hs` |
| `compN`, `ComposeN`, `fmapN`, `FmapN` | `Gongju.Composition` | `packages/gongju/src/Gongju/Composition.hs` |
| `slipr`, `Yank`, `slipl`, `Shove`, `twist`, `Twist` | `Gongju.Positional` | `packages/gongju/src/Gongju/Positional.hs` |
| `permute`, `Permute`, `Adjust`, `MapAdjust` | `Gongju.Permute` | `packages/gongju/src/Gongju/Permute.hs` |
| `IxFunctor`, `IxApplicative`, `IxMonad`, `IxComonad` | `Gongju.Indexed` | `packages/gongju/src/Gongju/Indexed.hs` |
| `Comonad`, `Distributive`, `Representable` | `Gongju.Comonad` | `packages/gongju/src/Gongju/Comonad.hs` |
| `Adjunction`, `zapLR`, `zapRL`, `AdjU`, `AdjC` | `Gongju.Adjunction` | `packages/gongju/src/Gongju/Adjunction.hs` |
| `Ran`, `Lan`, `Yoneda`, `Coyoneda`, `Codensity`, `Density` | `Gongju.Kan` | `packages/gongju/src/Gongju/Kan.hs` |
| `Profunctor`, `IxProfunctor`, `dimap`, `P1`, `P2`, `PP1`, `PP2` | `Gongju.Profunctor` | `packages/gongju/src/Gongju/Profunctor.hs` |
| `precomposeAt`, `spliceAt`, `contramapN`, `(-.)`, `(<-$>)` | `Gongju.Contravariant` | `packages/gongju/src/Gongju/Contravariant.hs` |
| Top-level re-exports | `Gongju.Core` | `packages/gongju/src/Gongju/Core.hs` |
| Unit tests & properties | `Main` (Test) | `packages/gongju/test/Main.hs` |

Use targeted line ranges (`StartLine`/`EndLine`) when viewing files.

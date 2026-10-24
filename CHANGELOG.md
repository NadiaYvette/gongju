# Changelog

All notable changes to `gongju` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to the Haskell Package Versioning Policy (PVP).

## [0.1.0.0] — 2026-10-24

### Added
- Canonical repository scaffolding via `gachi`.
- `Gongju.Peano`: `Peano`, `ToPeano`, `FromPeano`.
- `Gongju.Composition`: `ComposeN` (`compN`), `FmapN` (`fmapN`).
- `Gongju.Positional`: `Yank` (`slipr`), `Shove` (`slipl`), `Twist` (`twist`).
- `Gongju.Permute`: `Permute` (`permute`) via iterated `Yank` and `Adjust`.
- `Gongju.HList`: `HList`, `CurryH`, `ArgsOf`, `ResultOf`.
- 5 physical verification gates and full Hspec test suite.

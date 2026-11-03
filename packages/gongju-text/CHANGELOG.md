# Changelog for `gongju-text`

All notable changes to the `gongju-text` package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to the Haskell Package Versioning Policy (PVP).

## [0.1.0.0] — 2026-10-24

### Added
- **`Gongju.Text.NonEmpty`**: Non-empty text refinements and safe splitting utilities using `mono-traversable`'s `NonNull`:
  - `toText`: Convert non-null text to strict text.
  - `fromText`: Safe constructor returning `Maybe (NonNull Text)`.
  - `wordsNE`: Split text into non-empty words as `Maybe (NonEmpty Text)`.
  - `linesNE`: Split text into non-empty lines as `Maybe (NonEmpty Text)`.
- **`Gongju.Text.Stanza`**: Stanza splitting and parsing over polymorphic containers:
  - `Stanza`: Newtype wrapper around polymorphic text containers.
  - `stanzas`: Split strict text into stanzas of non-blank lines as standard lists (`[Stanza []]`).
  - `stanzasSeq`: Split strict text into stanzas collecting lines into `Data.Sequence.Seq`.
- **`Gongju.Text.Layout`**: Lightweight indentation measurement and hierarchical block-nesting analysis:
  - `IndentedLine`: Line representation with measured leading whitespace indentation depth.
  - `Block`: Nested block structure with line content and recursive child sub-blocks.
  - `parseIndentedLines`: Measure space indentation depths across line lists.
  - `parseBlocks`: Build nested hierarchical block trees from indented lines.
- Full test suite covering non-empty splits, stanza chunking, and hierarchical indentation parsing.

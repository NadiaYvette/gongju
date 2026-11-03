# gongju-text

**Structured text utilities, non-empty text collections, and layout parsing for Haskell.**

`gongju-text` provides lightweight, robust text processing utilities leveraging non-empty refinements, polymorphic container targets, and layout-aware block and stanza parsing.

---

## Features

1. **Non-Empty Text Refinements (`Gongju.Text.NonEmpty`):**
   - Safe construction and unwrap via `NonNull Text` (`fromText`, `toText`).
   - Non-empty word splitting (`wordsNE :: Text -> Maybe (NonEmpty Text)`).
   - Non-empty line splitting (`linesNE :: Text -> Maybe (NonEmpty Text)`).

2. **Polymorphic Stanza Chunking (`Gongju.Text.Stanza`):**
   - Stanza grouping of lines separated by one or more blank or whitespace lines.
   - Container-polymorphic wrapper `Stanza container`.
   - List-based (`stanzas :: Text -> [Stanza []]`) and sequence-based (`stanzasSeq :: Text -> Seq (Stanza Seq)`) chunking.

3. **Indentation and Block Parsing (`Gongju.Text.Layout`):**
   - Space-indentation measuring (`parseIndentedLines :: [Text] -> [IndentedLine]`).
   - Hierarchical indentation block tree construction (`parseBlocks :: [Text] -> [Block]`).
   - Zero-dependency layout analysis without full Markdown or YAML parser overhead.

---

## Quick Example

```haskell
{-# LANGUAGE OverloadedStrings #-}

import qualified Data.Text as T
import Gongju.Text.NonEmpty (wordsNE)
import Gongju.Text.Stanza (stanzas, unStanza)
import Gongju.Text.Layout (parseBlocks, Block(..))

main :: IO ()
main = do
  -- 1. Non-empty word splitting
  print (wordsNE "hello   world")

  -- 2. Stanza grouping
  let doc = "First stanza line 1\nLine 2\n\nSecond stanza line 1\nLine 2"
  mapM_ (print . unStanza) (stanzas doc)

  -- 3. Indented block hierarchy
  let lines' = ["root", "  child 1", "  child 2", "    grandchild"]
  print (parseBlocks lines')
```

---

## License

Licensed under the European Union Public Licence (EUPL-1.2) or Apache License 2.0.

{- |
Module      : Gongju.Text.Stanza
Description : Stanza splitting and parsing over polymorphic containers
Copyright   : (c) Nadia Yvette Chambers, 2026
License     : EUPL-1.2 OR Apache-2.0

Handles grouping of lines into stanzas separated by one or more blank lines,
with support for polymorphic container targets (Lists, Sequences, Vectors).
-}
module Gongju.Text.Stanza
    ( Stanza (..)
    , stanzas
    , stanzasSeq
    ) where

import qualified Data.Text as T
import qualified Data.Sequence as Seq
import Data.Sequence (Seq)

-- | A stanza represents a block of non-blank lines.
newtype Stanza container = Stanza { unStanza :: container T.Text }

deriving instance Show (container T.Text) => Show (Stanza container)
deriving instance Eq (container T.Text) => Eq (Stanza container)

-- | Split text into stanzas separated by blank lines, returning standard lists.
stanzas :: T.Text -> [Stanza []]
stanzas = fmap (Stanza . filter (not . T.null)) . splitStanzas . T.lines
  where
    splitStanzas [] = []
    splitStanzas ls =
        let (block, rest) = break isBlank ls
        in case block of
             []   -> splitStanzas (dropWhile isBlank rest)
             b    -> b : splitStanzas (dropWhile isBlank rest)

    isBlank = T.null . T.strip

-- | Split text into stanzas, collecting lines into 'Seq.Seq'.
stanzasSeq :: T.Text -> Seq (Stanza Seq)
stanzasSeq = Seq.fromList . fmap toSeqStanza . stanzas
  where
    toSeqStanza (Stanza xs) = Stanza (Seq.fromList xs)

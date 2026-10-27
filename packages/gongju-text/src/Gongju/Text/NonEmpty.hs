{- |
Module      : Gongju.Text.NonEmpty
Description : Non-empty text refinements and safe splitting utilities
Copyright   : (c) Nadia Yvette Chambers, 2026
License     : EUPL-1.2 OR Apache-2.0

Provides safe wrappers and collection operations over non-empty text values
utilizing 'mono-traversable' 'NonNull' types, ensuring operations like word
splitting and regex-style matching yield meaningful non-empty components.
-}
module Gongju.Text.NonEmpty
    ( NonNull
    , toText
    , fromText
    , wordsNE
    , linesNE
    ) where

import qualified Data.Text as T
import Data.List.NonEmpty (NonEmpty (..))
import Data.NonNull (NonNull, fromNullable, toNullable)

-- | Convert a NonNull Text back to a strict Text.
toText :: NonNull T.Text -> T.Text
toText = toNullable

-- | Attempt to create a NonNull Text from a strict Text.
fromText :: T.Text -> Maybe (NonNull T.Text)
fromText = fromNullable

-- | Split text into non-empty words as a NonEmpty collection.
wordsNE :: T.Text -> Maybe (NonEmpty T.Text)
wordsNE t =
    let ws = filter (not . T.null) (T.words t)
    in case ws of
         []     -> Nothing
         (w:ws') -> Just (w :| ws')

-- | Split text into non-empty lines as a NonEmpty collection.
linesNE :: T.Text -> Maybe (NonEmpty T.Text)
linesNE t =
    let ls = filter (not . T.null) (T.lines t)
    in case ls of
         []     -> Nothing
         (l:ls') -> Just (l :| ls')

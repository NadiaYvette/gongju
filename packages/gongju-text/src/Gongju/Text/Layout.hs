{- |
Module      : Gongju.Text.Layout
Description : Lightweight layout, indentation, and block-nesting analysis
Copyright   : (c) Nadia Yvette Chambers, 2026
License     : EUPL-1.2 OR Apache-2.0

Provides indentation measuring and hierarchical block structure resolution
without relying on full specification codecs like Markdown.
-}
module Gongju.Text.Layout
    ( IndentedLine (..)
    , Block (..)
    , parseIndentedLines
    , parseBlocks
    ) where

import qualified Data.Text as T

-- | A line with measured leading whitespace indentation depth.
data IndentedLine = IndentedLine
    { indentDepth :: !Int
    , lineContent :: !T.Text
    } deriving stock (Show, Eq)

-- | A nested block of content based on indentation level.
data Block = Block
    { blockIndent :: !Int
    , blockLines  :: ![T.Text]
    , subBlocks   :: ![Block]
    } deriving stock (Show, Eq)

-- | Convert raw lines into 'IndentedLine' records counting space depth.
parseIndentedLines :: [T.Text] -> [IndentedLine]
parseIndentedLines = map parseLine
  where
    parseLine t =
        let (spaces, rest) = T.span (== ' ') t
        in IndentedLine (T.length spaces) rest

-- | Group indented lines into nested hierarchical blocks.
parseBlocks :: [T.Text] -> [Block]
parseBlocks lines' = buildBlocks (parseIndentedLines $ filter (not . T.null . T.strip) lines')

buildBlocks :: [IndentedLine] -> [Block]
buildBlocks [] = []
buildBlocks (IndentedLine d content : rest) =
    let (sameOrDeeper, shallower) = span (\l -> indentDepth l >= d) rest
        (direct, deeper) = span (\l -> indentDepth l == d) sameOrDeeper
        currLines = content : map lineContent direct
        nested = buildBlocks deeper
        currBlock = Block d currLines nested
    in currBlock : buildBlocks shallower

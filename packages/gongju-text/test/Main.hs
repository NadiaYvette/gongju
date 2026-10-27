module Main (main) where

import Test.Hspec
import qualified Data.Text as T
import qualified Data.Sequence as Seq
import Data.List.NonEmpty (NonEmpty (..))
import Gongju.Text.NonEmpty
import Gongju.Text.Stanza
import Gongju.Text.Layout

main :: IO ()
main = hspec $ do
  describe "Gongju.Text.NonEmpty" $ do
    it "fromText returns Nothing for empty text" $
      fromText T.empty `shouldBe` Nothing

    it "wordsNE splits words into NonEmpty" $
      wordsNE "hello world" `shouldBe` Just (T.pack "hello" :| [T.pack "world"])

  describe "Gongju.Text.Stanza" $ do
    it "parses stanzas separated by blank lines" $ do
      let sample = "Line 1\nLine 2\n\nLine 3\n"
          res = stanzas sample
      res `shouldBe` [Stanza [T.pack "Line 1", T.pack "Line 2"], Stanza [T.pack "Line 3"]]

    it "parses stanzas into Seq containers" $ do
      let sample = "A\n\nB\n"
          res = stanzasSeq sample
      res `shouldBe` Seq.fromList [Stanza (Seq.singleton (T.pack "A")), Stanza (Seq.singleton (T.pack "B"))]

  describe "Gongju.Text.Layout" $ do
    it "computes indentation depths" $ do
      let raw = [T.pack "  indented"]
      parseIndentedLines raw `shouldBe` [IndentedLine 2 (T.pack "indented")]

    it "constructs nested blocks" $ do
      let raw = [T.pack "root", T.pack "  child"]
          res = parseBlocks raw
      res `shouldBe` [Block 0 [T.pack "root"] [Block 2 [T.pack "child"] []]]

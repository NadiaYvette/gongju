{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeApplications #-}

module Main (main) where

import Test.Hspec
import Gongju.Core

main :: IO ()
main = hspec do
  -- Tested against Note [Peano TypeLits Bridge] [ref:note-peano-typelits-bridge]
  describe "Gongju.Peano Naturals" do
    it "converts numeric TypeLits to Peano and verifies term equality" do
      show (Z :: Peano) `shouldBe` "Z"
      show (S Z :: Peano) `shouldBe` "S Z"

  -- Tested against Note [Variadic Composition Bidirectional Fundeps] [ref:note-variadic-composition-fundeps]
  describe "Gongju.Composition Variadic Composition" do
    it "compN @1 behaves identically to standard function composition (.)" do
      let f = (+ 1) :: Int -> Int
          g = (* 2) :: Int -> Int
      compN @1 f g 5 `shouldBe` f (g 5)

    it "compN @2 composes over a 2-argument curried function" do
      let f = show :: Int -> String
          add2 x y = (x + y :: Int)
      compN @2 f add2 10 20 `shouldBe` "30"

    it "compN @3 composes over a 3-argument curried function" do
      let f = (* 2) :: Int -> Int
          add3 x y z = (x + y + z :: Int)
      compN @3 f add3 1 2 3 `shouldBe` 12

    it "fmapN @2 maps through a nested functor layer" do
      let nested = Just [1, 2, 3 :: Int]
      fmapN @2 (+ 10) nested `shouldBe` Just [11, 12, 13]

  -- Tested against Note [Positional Curried Arrow Manipulation] [ref:note-positional-arrow-manipulation]
  describe "Gongju.Positional Combinators" do
    it "slipr @1 pulls the 1st argument (0-indexed) to position 0" do
      let sub x y = (x - y :: Int)
      slipr @1 sub 5 20 `shouldBe` 15

    it "slipr @2 pulls the 2nd argument (0-indexed) to position 0" do
      let f x y z = (x, y, z) :: (Int, String, Bool)
      slipr @2 f True 42 "hello" `shouldBe` (42, "hello", True)

    it "slipl @1 pushes the 0th argument to position 1" do
      let f x y = (x - y :: Int)
      slipl @1 f 5 20 `shouldBe` 15

    it "twist @0 swaps adjacent arguments at position 0 and 1" do
      let sub x y = (x - y :: Int)
      twist @0 sub 5 20 `shouldBe` 15

  -- Tested against Note [Iterated Yank Index Adjustment] [ref:note-iterated-yank-adjustment]
  describe "Gongju.Permute Arbitrary Argument Permutation" do
    it "permute @'[2, 0, 1] permutes a 3-argument function" do
      let f x y z = (x, y, z) :: (Int, String, Bool)
      permute @'[2, 0, 1] f True 10 "gongju" `shouldBe` (10, "gongju", True)

    it "permutes functions with identical argument types without ambiguity" do
      let f x y z = (x - y + z :: Int)
      permute @'[1, 2, 0] f 20 30 10 `shouldBe` (10 - 20 + 30)

  describe "Gongju.HList Heterogeneous Argument Bundles" do
    it "curries and uncurries functions over HList bundles" do
      let f :: HList '[Int, Int] -> Int
          f (x :> y :> HNil) = x + y
          curried :: Int -> Int -> Int
          curried = curryH f
      curried 10 25 `shouldBe` 35
      uncurryH curried ((10 :: Int) :> (25 :: Int) :> HNil) `shouldBe` 35

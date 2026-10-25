{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- | Module: CoreInspection
-- Description: Representative pipelines for mechanical GHC Core zero-cost verification
--
-- This module defines concrete, representative combinator pipelines over curried functions,
-- tuples, monadic bindings, contravariant syntax grids, and profunctor effect handlers.
--
-- When compiled under @-O2@, GHC's Simplifier must beta-reduce and inline every single one of
-- these definitions down to direct lambda expressions with ZERO dictionary allocations and
-- ZERO indirect typeclass calls ($fComposeN, $fPermute, $fYank, $fPrecomposeAt, $fBindPos, etc.).
--
-- Tested and mechanically verified against:
-- Note [Zero-Cost Inlining and Core Simplification] [ref:note-zero-cost-core-simplification].
module CoreInspection
  ( -- * Variadic Composition Fixtures
    testComp2
  , testComp3
    -- * Positional Arrow Manipulation Fixtures
  , testSlipr1
  , testSlipl2
  , testTwist1
  , testYank1
  , testShove2
    -- * Arbitrary Permutation Fixtures
  , testPermute3
    -- * Contravariant Grid & Splicing Fixtures
  , testPrecompose1
  , testSplice12
    -- * Positional Monadic Binding Fixtures
  , testBind1
  , testBindPos11
  , testLiftPure2
    -- * Tuple-Spine Arrow Permutations
  , testPermuteTuple3
  , testPermuteInputs
  , testSwapStrand
    -- * Curried Category & Handler Permutations
  , testCatFlip
  , testCatApply
  , testCompCat2
  , testYankCat1
  , testPermuteCat3
  , testPermuteHandler3
  ) where

import Gongju.Core

-- ---------------------------------------------------------------------------
-- 1. Variadic Arity Composition
-- ---------------------------------------------------------------------------

-- | Variadic composition over a binary function: simplifies to @\f g x y -> f (g x y)@.
testComp2 :: (Int -> Int) -> (Int -> Int -> Int) -> Int -> Int -> Int
testComp2 f g x y = compN @2 f g x y
{-# NOINLINE testComp2 #-}

-- | Variadic composition over a ternary function: simplifies to @\f g x y z -> f (g x y z)@.
testComp3 :: (Int -> Int) -> (Int -> Int -> Int -> Int) -> Int -> Int -> Int -> Int
testComp3 f g x y z = compN @3 f g x y z
{-# NOINLINE testComp3 #-}

-- ---------------------------------------------------------------------------
-- 2. Positional Curried Arrow Manipulation
-- ---------------------------------------------------------------------------

-- | Pull argument 1 to position 0 via 'slipr': simplifies to @\f y x -> f x y@.
testSlipr1 :: (Int -> Int -> Int) -> Int -> Int -> Int
testSlipr1 f y x = slipr @1 f y x
{-# NOINLINE testSlipr1 #-}

-- | Push argument 0 to position 2 via 'slipl': simplifies to @\f x y z -> f z x y@.
testSlipl2 :: (Int -> Int -> Int -> Int) -> Int -> Int -> Int -> Int
testSlipl2 f x y z = slipl @2 f x y z
{-# NOINLINE testSlipl2 #-}

-- | Transpose adjacent arguments 1 and 2 via 'twist': simplifies to @\f x z y -> f x y z@.
testTwist1 :: (Int -> Int -> Int -> Int) -> Int -> Int -> Int -> Int
testTwist1 f x z y = twist @1 f x z y
{-# NOINLINE testTwist1 #-}

-- | Synonym 'yank' pulling argument 1 to position 0: simplifies to @\f y x -> f x y@.
testYank1 :: (Int -> Int -> Int) -> Int -> Int -> Int
testYank1 f y x = yank @1 f y x
{-# NOINLINE testYank1 #-}

-- | Synonym 'shove' pushing argument 0 to position 2: simplifies to @\f x y z -> f z x y@.
testShove2 :: (Int -> Int -> Int -> Int) -> Int -> Int -> Int -> Int
testShove2 f x y z = shove @2 f x y z
{-# NOINLINE testShove2 #-}

-- ---------------------------------------------------------------------------
-- 3. Arbitrary Permutations
-- ---------------------------------------------------------------------------

-- | Permute ternary arguments @'[2, 0, 1]@: simplifies to @\f z x y -> f x y z@.
testPermute3 :: (Int -> Int -> Int -> Int) -> Int -> Int -> Int -> Int
testPermute3 f z x y = permute @'[2, 0, 1] f z x y
{-# NOINLINE testPermute3 #-}

-- ---------------------------------------------------------------------------
-- 4. Contravariant Syntax Grids & 2D Splicing
-- ---------------------------------------------------------------------------

-- | Precompose at argument slot 1: simplifies to @\h f x y -> f x (h y)@.
testPrecompose1 :: (Int -> Int) -> (Int -> Int -> Int) -> Int -> Int -> Int
testPrecompose1 h f x y = precomposeAt @1 h f x y
{-# NOINLINE testPrecompose1 #-}

-- | Splice a binary function into slot 1 of a ternary function:
-- simplifies to @\h f x u v z -> f x (h u v) z@.
testSplice12 :: (Int -> Int -> Int) -> (Int -> Int -> Int -> Int) -> Int -> Int -> Int -> Int -> Int
testSplice12 h f x u v z = spliceAt @1 @2 h f x u v z
{-# NOINLINE testSplice12 #-}

-- ---------------------------------------------------------------------------
-- 5. Positional Monadic Binding
-- ---------------------------------------------------------------------------

-- | Monadic bind at slot 1: simplifies to direct pattern matching on 'mb'.
testBind1 :: (Int -> Int -> Maybe Int) -> Maybe Int -> Int -> Maybe Int
testBind1 f mb x = bindAt @1 f mb x
{-# NOINLINE testBind1 #-}

-- | Interior monadic bind at slot 1 with 1 trailing argument:
-- simplifies to direct pattern matching on 'mb' and application to 'z'.
testBindPos11 :: (Int -> Int -> Int -> Maybe Int) -> Maybe Int -> Int -> Int -> Maybe Int
testBindPos11 f mb x z = bindPos @1 @1 f mb x z
{-# NOINLINE testBindPos11 #-}

-- | Pure lifting of binary function into 'Monad': simplifies to @\f x y -> Just (f x y)@.
testLiftPure2 :: (Int -> Int -> Int) -> Int -> Int -> Maybe Int
testLiftPure2 f x y = liftPureN @2 f x y
{-# NOINLINE testLiftPure2 #-}

-- ---------------------------------------------------------------------------
-- 6. Right-Nested Tuple-Spine Arrow Permutations
-- ---------------------------------------------------------------------------

-- | Reorder right-nested 3-tuple spine: simplifies to direct nested unboxing and tuple construction.
testPermuteTuple3 :: (Int, (Int, (Int, ()))) -> (Int, (Int, (Int, ())))
testPermuteTuple3 t = permuteTuple @'[2, 0, 1] t
{-# NOINLINE testPermuteTuple3 #-}

-- | Reorder input tuple spine of a profunctor strand: simplifies to direct projection into @p@.
testPermuteInputs :: ((Int, (Int, (Int, ()))) -> Int) -> (Int, (Int, (Int, ()))) -> Int
testPermuteInputs p inp = permuteInputs @'[2, 0, 1] p inp
{-# NOINLINE testPermuteInputs #-}

-- | Swap inputs of binary pair profunctor strand: simplifies to @\p inp -> p (case inp of (a, b) -> (b, a))@.
testSwapStrand :: ((Int, Int) -> Int) -> (Int, Int) -> Int
testSwapStrand p inp = swapStrand p inp
{-# NOINLINE testSwapStrand #-}

-- ---------------------------------------------------------------------------
-- 7. Curried Category & Effect Handler Permutations
-- ---------------------------------------------------------------------------

-- | Curried category morphism argument swap: simplifies to @\f y x -> f x y@.
testCatFlip :: (Int -> Int -> Int) -> Int -> Int -> Int
testCatFlip f y x = catFlip f y x
{-# NOINLINE testCatFlip #-}

-- | Bridge category morphism application: simplifies to @\f x y -> f x y@.
testCatApply :: (Int -> Int -> Int) -> Int -> Int -> Int
testCatApply f x y = catApply f x y
{-# NOINLINE testCatApply #-}

-- | Curried category arity composition: simplifies to @\g f x y z -> g (f x y z)@.
testCompCat2 :: (Int -> Int) -> (Int -> Int -> Int -> Int) -> Int -> Int -> Int -> Int
testCompCat2 g f x y z = compCatN @2 g f x y z
{-# NOINLINE testCompCat2 #-}

-- | Pull category input at position 1 forward: simplifies to @\f y x -> f x y@.
testYankCat1 :: (Int -> Int -> Int) -> Int -> Int -> Int
testYankCat1 f y x = yankCat @1 f y x
{-# NOINLINE testYankCat1 #-}

-- | Arbitrary category input permutation: simplifies to @\f z x y -> f x y z@.
testPermuteCat3 :: (Int -> Int -> Int -> Int) -> Int -> Int -> Int -> Int
testPermuteCat3 f z x y = permuteCat @'[2, 0, 1] f z x y
{-# NOINLINE testPermuteCat3 #-}

-- | Effect handler environment parameter permutation: simplifies to @\h z x y env -> h x y z env@.
testPermuteHandler3 :: (Int -> Int -> Int -> Int -> Int) -> Int -> Int -> Int -> Int -> Int
testPermuteHandler3 h z x y env = permuteHandler @'[2, 0, 1] h z x y env
{-# NOINLINE testPermuteHandler3 #-}

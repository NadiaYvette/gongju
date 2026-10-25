{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Test Suite for Gongju: Grand Unified Open-World Tape Engine and Permutation Library
--
-- Validates:
-- * Peano natural transformations and bidirectional fundep inference.
-- * Variadic composition and open-world tape execution via visible-forall (.@).
-- * Positional combinators (slipr, slipl, twist) and arbitrary permutation (permute).
-- * Indexed monad and comonad transitions (IxFunctor, IxPointed, IxApplicative, IxMonad).
-- * Canonical comonads, distributive functors, and representable commute laws.
-- * Canonical adjunctions with dual annihilation (zapLR, zapRL, unit, counit).
-- * Canonical Kan extensions (Ran, Lan), Yoneda fusion, and Codensity CPS optimizations.
-- * Canonical profunctors with contravariant/covariant slot mappings.
module Main (main) where

import Test.Hspec
import Data.Functor.Identity (Identity (..))
import Gongju.Core
import CoreInspection

-- | Minimal Comonad fixture for verifying cokleisli extension via 'W'.
-- Implements canonical 'Control.Comonad.Comonad'.
newtype IdW a = IdW a
  deriving (Eq, Show)

instance Functor IdW where
  fmap f (IdW a) = IdW (f a)

instance Comonad IdW where
  extract (IdW a) = a
  duplicate (IdW a) = IdW (IdW a)

-- | Minimal Distributive and Representable Functor fixture (Reader functor).
-- Validates effect commutation outside a comonad via 'Dist'.
newtype ReaderR r a = ReaderR { runReaderR :: r -> a }

instance Functor (ReaderR r) where
  fmap f (ReaderR g) = ReaderR (f . g)

instance Distributive (ReaderR r) where
  distribute f = ReaderR \r -> fmap (\(ReaderR g) -> g r) f

instance Representable (ReaderR r) where
  type Rep (ReaderR r) = r
  tabulate = ReaderR
  index (ReaderR f) = f

-- | Minimal Indexed State Monad fixture.
-- Implements canonical 'Data.Functor.Indexed' and 'Control.Monad.Indexed'.
newtype IxState i j a = IxState { runIxState :: i -> (a, j) }

instance IxFunctor IxState where
  imap f (IxState g) = IxState \i ->
    let (a, j) = g i in (f a, j)

instance IxPointed IxState where
  ireturn a = IxState (a,)

instance IxApplicative IxState where
  iap (IxState gf) (IxState ga) = IxState \i ->
    let (f, j) = gf i
        (a, l) = ga j
    in (f a, l)

instance IxMonad IxState where
  ibind k (IxState g) = IxState \i ->
    let (a, j) = g i
    in runIxState (k a) j

main :: IO ()
main = hspec do
  -- Tested against Note [Peano TypeLits Bridge] [ref:note-peano-typelits-bridge]
  describe "Gongju.Peano Naturals & List Type Families" do
    it "converts numeric TypeLits to Peano and verifies term equality" do
      show (Z :: Peano) `shouldBe` "Z"
      show (S Z :: Peano) `shouldBe` "S Z"

  -- Tested against Note [Variadic Composition Bidirectional Fundeps] [ref:note-variadic-composition-fundeps]
  describe "Gongju.Composition Variadic Composition & Tape Engine" do
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

    it "executes tape-driven composition via infix (.@) on pure arguments" do
      let add3 x y z = (x + y + z :: Int)
          h = ((+ 100) .@ [P, P, P]) add3
      h 10 20 30 `shouldBe` 160

    it "executes tape-driven composition with explicit argument indices" do
      let tuple3 x y z = (x, y, z) :: (Int, String, Bool)
          p = (id .@ [2 # P, 0 # P, 1 # P]) tuple3
      p True (42 :: Int) "gongju" `shouldBe` (42, "gongju", True)

    it "executes tape-driven monadic binding" do
      let mAction :: Int -> Int -> [Int]
          mAction x y = [x + y, x * y]
          mComp = (fmap show .@ [P, M]) mAction
      mComp 3 [10, 20 :: Int] `shouldBe` ["[13,30]", "[23,60]"]

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

  describe "Gongju.Indexed Transitions" do
    it "composes transitions over indexed state monad" do
      let step1 :: Int -> Int -> String
          step1 x y = show (x + y)
          comp = (imap (++ "!") .@ [P, IxM]) step1
          res = comp 10 (IxState \s -> (5 :: Int, s + 1))
      runIxState res (0 :: Int) `shouldBe` ("15!", 1 :: Int)

  describe "Gongju.Comonad & Distributive Functors" do
    it "extends cokleisli functions using W tag" do
      let wAction :: IdW Int -> Int -> String
          wAction (IdW x) y = show (x + y)
          wComp = (fmap (++ "!") .@ [W, P]) wAction
      wComp (IdW 5) (10 :: Int) `shouldBe` IdW "15!"

    it "commutes a Representable effect outside a Comonad via PullRet '[Dist]" do
      let g :: IdW Int -> Int -> ReaderR String Int
          g (IdW baseVal) multiplier = ReaderR \env -> (baseVal + multiplier) * length env
          comp = withOps [W, P, PullDist] id g
          readerRes = comp (IdW 10) (5 :: Int)
      runReaderR readerRes "abc" `shouldBe` IdW 45

  -- Tested against Data.Functor.Adjunction canonical instances
  describe "Gongju.Adjunction Dual Annihilation & Adjoints" do
    -- Dual pairing annihilation: zapLR pairs left adjoint (,) with right adjoint (->)
    it "performs dual annihilation via zapLR on ((,) e) and ((->) e)" do
      let pair = (10 :: Int, length :: String -> Int)
          f e = replicate e 'x'
      zapLR pair f `shouldBe` 10

    -- Dual pairing annihilation: zapRL pairs right adjoint (->) with left adjoint (,)
    it "performs dual annihilation via zapRL on ((->) e) and ((,) e)" do
      let pair = (10 :: Int, "hello")
          f :: Int -> String -> Int
          f e str = length str + e
      zapRL f pair `shouldBe` 15

    -- Adjunction counit: collapses pair of environment and accessor (e, e -> a) to a
    it "applies adjunction counit via withOps [AdjC]" do
      let counitTarget = (5 :: Int, (+ 10) :: Int -> Int)
          comp = withOps [AdjC] id counitTarget
      comp `shouldBe` 15

  -- Tested against kan-extensions canonical Ran, Lan, Yoneda, Coyoneda, Codensity
  describe "Gongju.Kan Right/Left Kan Extensions, Yoneda & Codensity" do
    -- Universal counit of Right Kan extension collapses Ran g h (g a) to h a
    it "counit collapses Ran to underlying functor via ranCounit" do
      let ranVal = ranUnit (Identity (42 :: Int))
      runIdentity (ranCounit ranVal) `shouldBe` 42

    -- Universal unit of Left Kan extension embeds h a into Lan g h (g a)
    it "unit embeds functor into Lan via lanUnit" do
      let lanVal = lanUnit (Identity (99 :: Int)) :: Lan Identity Identity (Identity Int)
      runIdentity (lanCounit lanVal) `shouldBe` 99

    -- Coyoneda allows fmap fusion without requiring Functor constraints until lowering
    it "fuses mapping via Coyoneda lifting and lowering" do
      let co = liftCoyoneda [1, 2, 3 :: Int]
          coMapped = fmap (+ 10) co
      lowerCoyoneda coMapped `shouldBe` [11, 12, 13]

    -- Yoneda provides O(1) CPS composition for arbitrary covariant functors
    it "fuses mapping via Yoneda lifting and lowering" do
      let yon = liftYoneda [1, 2, 3 :: Int]
          yonMapped = fmap (* 2) yon
      lowerYoneda yonMapped `shouldBe` [2, 4, 6]

    -- Codensity optimizes right-associated monadic bind chains into O(1) continuations
    it "optimizes monad bind CPS via Codensity" do
      let cod = liftCodensity (Just (100 :: Int))
          codBound = cod >>= \x -> pure (x + 23)
      lowerCodensity codBound `shouldBe` Just 123

  -- Tested against profunctors canonical Profunctor and dimap
  describe "Gongju.Profunctor Contravariant/Covariant Mapping" do
    -- Contravariant pre-processing of input arguments via P1 (lmap)
    it "maps profunctor first slot contravariantly via mapPath @'[P1]" do
      let f = (+ 10) :: Int -> Int
          g = mapPath @'[P1] (* 2) f
      g 5 `shouldBe` 20

    -- Covariant post-processing of return values via P2 (rmap)
    it "maps profunctor second slot covariantly via mapPath @'[P2]" do
      let f = (+ 10) :: Int -> Int
          g = mapPath @'[P2] (* 2) f
      g 5 `shouldBe` 30

    -- Simultaneous bidirectional transformation via dimap
    it "dimaps both profunctor slots simultaneously via dimap" do
      let f = (+ 10) :: Int -> Int
          g = dimap (* 2) show f
      g 5 `shouldBe` "20"

  -- Tested against Note [Contravariant Positional Pre-Composition] [ref:note-contravariant-precomposition]
  describe "Gongju.Contravariant Positional Pre-Composition & 2D Splicing" do
    it "precomposeAt @0 and (-.) pre-compose argument 0" do
      let f x y = (x - y :: Int)
          g = precomposeAt @0 (* 2) f
          h = (* 2) -. f
      g 10 3 `shouldBe` 17
      h 10 3 `shouldBe` 17

    it "precomposeAt @1 and (-.*) pre-compose argument 1" do
      let f x y z = (x + y * z :: Int)
          g = precomposeAt @1 (+ 10) f
          h = (+ 10) -.* f
      g 5 2 3 `shouldBe` 41
      h 5 2 3 `shouldBe` 41

    it "precomposeAt @2 and (-.**) pre-compose argument 2" do
      let tuple3 x y z = (x, y, z) :: (Int, String, Bool)
          g = precomposeAt @2 not tuple3
          h = not -.** tuple3
      g 10 "abc" False `shouldBe` (10, "abc", True)
      h 10 "abc" False `shouldBe` (10, "abc", True)

    it "precomposeAt @3 and (-.***) pre-compose argument 3" do
      let tuple4 w x y z = (w, x, y, z) :: (Int, Int, Int, Int)
          g = precomposeAt @3 (* 100) tuple4
          h = (* 100) -.*** tuple4
      g 1 2 3 4 `shouldBe` (1, 2, 3, 400)
      h 1 2 3 4 `shouldBe` (1, 2, 3, 400)

    it "spliceAt @1 @2 splices a binary function into slot 1 of a ternary function" do
      let add3 x y z = (x + y + z :: Int)
          mult2 u v = (u * v :: Int)
          spliced = spliceAt @1 @2 mult2 add3
      spliced 10 3 4 5 `shouldBe` 27

    it "spliceAt @0 @3 splices a ternary function into slot 0" do
      let add2 a b = (a + b :: Int)
          prod3 x y z = (x * y * z :: Int)
          spliced = spliceAt @0 @3 prod3 add2
      spliced 2 3 4 10 `shouldBe` 34

  -- Tested against Note [Contravariant Functor Alternating Parity] [ref:note-contravariant-alternating-parity]
  describe "Gongju.Contravariant Alternating Parity Stacks" do
    it "contramapN @1 and (<-$>) invert variance on 1-layer Predicate" do
      let isPositive = Predicate (> (0 :: Int))
          p1 = contramapN @1 (* 2) isPositive
          p2 = (* 2) <-$> isPositive
      getPredicate p1 5 `shouldBe` True
      getPredicate p1 (-1) `shouldBe` False
      getPredicate p2 5 `shouldBe` True
      getPredicate p2 (-1) `shouldBe` False

    it "contramapN @2 and (<-$$>) cancel variance inversion on 2-layer Predicate (covariant)" do
      let pp = Predicate (\(Predicate p) -> p (10 :: Int)) :: Predicate (Predicate Int)
          pp1 = contramapN @2 (* 2) pp
          pp2 = (* 2) <-$$> pp
      getPredicate pp1 (Predicate (> 15)) `shouldBe` True
      getPredicate pp1 (Predicate (> 25)) `shouldBe` False
      getPredicate pp2 (Predicate (> 15)) `shouldBe` True
      getPredicate pp2 (Predicate (> 25)) `shouldBe` False

    it "contramapN @3 and (<-$$$>) invert variance on 3-layer Predicate (contravariant)" do
      let ppp = Predicate (\(Predicate pp) -> pp (Predicate (> (15 :: Int)))) :: Predicate (Predicate (Predicate Int))
          ppp1 = contramapN @3 (* 2) ppp
          ppp2 = (* 2) <-$$$> ppp
          evalTest val = Predicate (\(Predicate p) -> p (val :: Int))
      getPredicate ppp1 (evalTest 10) `shouldBe` True
      getPredicate ppp1 (evalTest 5) `shouldBe` False
      getPredicate ppp2 (evalTest 10) `shouldBe` True
      getPredicate ppp2 (evalTest 5) `shouldBe` False

    it "supports Divisible divide combining two predicates" do
      let pEven = Predicate even :: Predicate Int
          pPositive = Predicate (> 0) :: Predicate Int
          pCombined = divide (\x -> (x, x)) pEven pPositive
      getPredicate pCombined 4 `shouldBe` True
      getPredicate pCombined 3 `shouldBe` False
      getPredicate pCombined (-2) `shouldBe` False

  -- Tested against Note [Positional Monadic Curried Binding] [ref:note-positional-monadic-binding]
  describe "Gongju.Monad Positional Monadic Binding" do
    it "bindAt @1 and (==<<), (>>==) bind trailing argument slot 1" do
      let f x y = pure (x * y) :: Maybe Int
      bindAt @1 f (Just 7) 6 `shouldBe` Just 42
      (f ==<< Just 7) 6 `shouldBe` Just 42
      (Just 7 >>== f) 6 `shouldBe` Just 42
      (f ==<< Nothing) 6 `shouldBe` Nothing

    it "bindAt @2 and (===<<), (>>===) bind trailing argument slot 2" do
      let add3 x y z = pure (x + y + z) :: Maybe Int
      bindAt @2 add3 (Just 10) 1 2 `shouldBe` Just 13
      (add3 ===<< Just 10) 1 2 `shouldBe` Just 13
      (Just 10 >>=== add3) 1 2 `shouldBe` Just 13

    it "bindAt @3 and (====<<), (>>====) bind trailing argument slot 3" do
      let add4 w x y z = pure (w + x + y + z) :: Maybe Int
      bindAt @3 add4 (Just 100) 1 2 3 `shouldBe` Just 106
      (add4 ====<< Just 100) 1 2 3 `shouldBe` Just 106
      (Just 100 >>==== add4) 1 2 3 `shouldBe` Just 106

    it "bindPos @1 @1 and (=.=<<), (>>=.=) bind interior slot 1 of 3" do
      let add3 x y z = pure (x + y + z) :: Maybe Int
      bindPos @1 @1 add3 (Just 20) 1 3 `shouldBe` Just 24
      (add3 =.=<< Just 20) 1 3 `shouldBe` Just 24
      (Just 20 >>=.= add3) 1 3 `shouldBe` Just 24
      (add3 =.=<< Nothing) 1 3 `shouldBe` Nothing

    it "bindPos @0 @2 and (==.<<), (=..<<), (>>.==), (>>..=) bind interior slot 0 of 3" do
      let add3 x y z = pure (x + y + z) :: Maybe Int
      bindPos @0 @2 add3 (Just 10) 2 3 `shouldBe` Just 15
      (add3 ==.<< Just 10) 2 3 `shouldBe` Just 15
      (add3 =..<< Just 10) 2 3 `shouldBe` Just 15
      (Just 10 >>.== add3) 2 3 `shouldBe` Just 15
      (Just 10 >>..= add3) 2 3 `shouldBe` Just 15
      (add3 ==.<< Nothing) 2 3 `shouldBe` Nothing

  -- Tested against Note [Multi-Slot Monadic Lifting Masks] [ref:note-multislot-monadic-masks]
  describe "Gongju.Monad Multi-Slot Lifting Masks" do
    it "liftMask @'[MArg, PArg, MArg] sequences multiple monadic slots while preserving pure arguments" do
      let f a b c = pure (a ++ ":" ++ show b ++ ":" ++ c) :: [String]
          g = liftMask @'[MArg, PArg, MArg] f
      g ["a", "b"] (42 :: Int) ["x", "y"] `shouldBe` ["a:42:x", "a:42:y", "b:42:x", "b:42:y"]

    it "liftMask @'[PArg, MArg] preserves pure arg 0 and binds monadic arg 1" do
      let g x y = if y > 0 then Just (x * y) else Nothing :: Maybe Int
          h = liftMask @'[PArg, MArg] g
      h (5 :: Int) (Just 3) `shouldBe` Just 15
      h (5 :: Int) Nothing `shouldBe` Nothing

    it "liftMask @'[MArg, MArg] lifts both arguments into a monad" do
      let g x y = if y > 0 then Just (x * y) else Nothing :: Maybe Int
          h = liftMask @'[MArg, MArg] g
      h (Just 5) (Just 3) `shouldBe` Just 15
      h Nothing (Just 3) `shouldBe` Nothing
      h (Just 5) Nothing `shouldBe` Nothing

  describe "Gongju.Monad Arity-Indexed Kleisli Composition & Pure Lifting" do
    it "liftPureN lifts pure functions to return monadic results" do
      liftPureN @1 (+ (1 :: Int)) 5 `shouldBe` (Just 6 :: Maybe Int)
      liftPureN @2 (+) (3 :: Int) 4 `shouldBe` (Just 7 :: Maybe Int)
      liftPureN @3 (\x y z -> (x + y + z :: Int)) 1 2 3 `shouldBe` (Just 6 :: Maybe Int)

    it "bindKleisliN @2 and (<=<.), (.>=>) post-compose Kleisli arrows after binary functions" do
      let f x y = Just (x + y :: Int)
          checkEven z = if even z then Just z else Nothing
      bindKleisliN @2 checkEven f 2 4 `shouldBe` Just 6
      bindKleisliN @2 checkEven f 2 3 `shouldBe` Nothing
      (checkEven <=<. f) 2 4 `shouldBe` Just 6
      (checkEven <=<. f) 2 3 `shouldBe` Nothing
      (f .>=> checkEven) 2 4 `shouldBe` Just 6
      (f .>=> checkEven) 2 3 `shouldBe` Nothing

    it "bindKleisliN @3 and (<=<..), (..>=>) post-compose Kleisli arrows after ternary functions" do
      let add3M x y z = Just (x + y + z :: Int)
          checkEven z = if even z then Just z else Nothing
      bindKleisliN @3 checkEven add3M 1 2 3 `shouldBe` Just 6
      bindKleisliN @3 checkEven add3M 1 2 4 `shouldBe` Nothing
      (checkEven <=<.. add3M) 1 2 3 `shouldBe` Just 6
      (checkEven <=<.. add3M) 1 2 4 `shouldBe` Nothing
      (add3M ..>=> checkEven) 1 2 3 `shouldBe` Just 6
      (add3M ..>=> checkEven) 1 2 4 `shouldBe` Nothing

  -- Tested against Note [Profunctor Effect Handler Permutations] [ref:note-profunctor-handler-permutations]
  describe "Gongju.Profunctor Curried Category & Handler Permutations" do
    it "catFlip and catApply work over CurriedCat (->)" do
      let f x y = (x - y :: Int)
      catFlip f 5 20 `shouldBe` 15
      catApply f 20 5 `shouldBe` 15

    it "compCatN composes category morphisms at the leaf" do
      let f x y = \z -> (x + y + z :: Int)
          g z = show (z * 2)
      compCatN @2 g f 10 20 5 `shouldBe` "70"

    it "yankCat pulls curried category inputs to position 0" do
      let sub3 x y z = (x - y - z :: Int)
      yankCat @1 sub3 10 100 5 `shouldBe` (100 - 10 - 5)
      yankCat @2 sub3 5 100 10 `shouldBe` (100 - 10 - 5)

    it "permuteCat permutes curried category inputs arbitrarily" do
      let tuple3 x y z = (x, y, z) :: (Int, String, Bool)
          perm = permuteCat @'[2, 0, 1] tuple3
      perm False 100 "hello" `shouldBe` (100, "hello", False)

    it "permuteHandler reorders environment parameters of an effect handler" do
      let handler env1 env2 env3 = \(x :: Int) -> env1 ++ ":" ++ show env2 ++ ":" ++ env3 ++ ":" ++ show x
          handler' = permuteHandler @'[2, 0, 1] handler
      handler' "c" "a" (42 :: Int) 10 `shouldBe` "a:42:c:10"

    it "compHandlerN adapts profunctor strands produced by an effect handler" do
      let h e1 e2 = \(x :: Int) -> show (x + e1 * e2)
          adapted = compHandlerN @2 (lmap (* 2)) h
      adapted 3 4 5 `shouldBe` "22"

  -- Tested against Note [Tuple-Spine Arrow Permutations] [ref:note-tuple-spine-permutations]
  describe "Gongju.Profunctor Tuple-Spine Arrow & Strand Permutations" do
    it "yankTuple pulls tuple slots to the head" do
      let t3 = (10 :: Int, (20 :: Int, (30 :: Int, ())))
      yankTuple @0 t3 `shouldBe` t3
      yankTuple @1 t3 `shouldBe` (20, (10, (30, ())))
      yankTuple @2 t3 `shouldBe` (30, (10, (20, ())))

    it "permuteTuple permutes right-nested tuple slots arbitrarily" do
      let t3 = (10 :: Int, (20 :: Int, (30 :: Int, ())))
      permuteTuple @'[2, 0, 1] t3 `shouldBe` (30, (10, (20, ())))
      permuteTuple @'[1, 2, 0] t3 `shouldBe` (20, (30, (10, ())))

    it "permuteInputs reorders profunctor strand input tuple spines" do
      let strand = \(z, (x, (y, ()))) -> show (x * 100 + y * 10 + z :: Int)
          strand' = permuteInputs @'[2, 0, 1] strand
      strand' (1, (2, (3, ()))) `shouldBe` "123"

    it "permuteOutputs reorders profunctor strand output tuple spines" do
      let gen = \() -> (10 :: Int, (20 :: Int, (30 :: Int, ())))
          gen' = permuteOutputs @'[2, 0, 1] gen
      gen' () `shouldBe` (30, (10, (20, ())))

    it "dimapPermute simultaneously permutes input and output tuple spines" do
      let biStrand = \(y, (x, ())) -> (x ++ "!", (y + 1 :: Int, ()))
          d = dimapPermute @'[1, 0] @'[1, 0] biStrand
      d ("first", (100 :: Int, ())) `shouldBe` (101, ("first!", ()))

    it "swapStrand swaps binary pair inputs of a profunctor strand" do
      let p = \(b, a) -> (a - b :: Int)
      p (5, 20) `shouldBe` 15
      swapStrand p (5, 20) `shouldBe` (-15)

  -- Tested against Note [Zero-Cost Inlining and Core Simplification] [ref:note-zero-cost-core-simplification]
  describe "Gongju.Core Zero-Cost Inspection Fixtures" do
    it "testComp2 and testComp3 evaluate arity composition" do
      testComp2 (* 2) (+) 10 20 `shouldBe` 60
      testComp3 (* 2) (\x y z -> x + y + z) 1 2 3 `shouldBe` 12

    it "testSlipr1, testSlipl2, testTwist1, testYank1, testShove2 manipulate positional arguments" do
      let f3 x y z = (x * 100 + y * 10 + z :: Int)
      testSlipr1 (-) 5 20 `shouldBe` 15
      testYank1 (-) 5 20 `shouldBe` 15
      testSlipl2 f3 1 2 3 `shouldBe` 312
      testShove2 f3 1 2 3 `shouldBe` 312
      testTwist1 f3 1 3 2 `shouldBe` 123

    it "testPermute3 permutes arguments [2, 0, 1]" do
      let f3 x y z = (x * 100 + y * 10 + z :: Int)
      testPermute3 f3 3 1 2 `shouldBe` 123

    it "testPrecompose1 and testSplice12 perform contravariant positional pre-composition" do
      testPrecompose1 (* 10) (-) 100 5 `shouldBe` 50
      testSplice12 (*) (\x y z -> x + y + z) 10 3 4 5 `shouldBe` 27

    it "testBind1, testBindPos11, testLiftPure2 perform monadic binding and lifting" do
      testBind1 (\x y -> Just (x + y)) (Just 20) 10 `shouldBe` Just 30
      testBind1 (\x y -> Just (x + y)) Nothing 10 `shouldBe` Nothing
      testBindPos11 (\x y z -> Just (x + y + z)) (Just 20) 10 5 `shouldBe` Just 35
      testBindPos11 (\x y z -> Just (x + y + z)) Nothing 10 5 `shouldBe` Nothing
      testLiftPure2 (+) 10 20 `shouldBe` Just 30

    it "testPermuteTuple3, testPermuteInputs, testSwapStrand permute tuple spines and strands" do
      testPermuteTuple3 (10, (20, (30, ()))) `shouldBe` (30, (10, (20, ())))
      testPermuteInputs (\(z, (x, (y, ()))) -> x * 100 + y * 10 + z) (1, (2, (3, ()))) `shouldBe` 123
      testSwapStrand (\(b, a) -> a - b) (5, 20) `shouldBe` (-15)

    it "testCatFlip, testCatApply, testCompCat2, testYankCat1, testPermuteCat3, testPermuteHandler3 manipulate category morphisms" do
      let f3 x y z = (x * 100 + y * 10 + z :: Int)
          f4 x y z env = (x * 1000 + y * 100 + z * 10 + env :: Int)
      testCatFlip (-) 5 20 `shouldBe` 15
      testCatApply (-) 20 5 `shouldBe` 15
      testCompCat2 (* 2) (\x y z -> x + y + z) 1 2 3 `shouldBe` 12
      testYankCat1 (-) 5 20 `shouldBe` 15
      testPermuteCat3 f3 3 1 2 `shouldBe` 123
      testPermuteHandler3 f4 3 1 2 4 `shouldBe` 1234






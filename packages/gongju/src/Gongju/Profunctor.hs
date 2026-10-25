{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}

-- | Module: Gongju.Profunctor
-- Description: Profunctors, Indexed Profunctors, and Effect Handler Permutations for Gongju
--
-- Plugs canonical 'Profunctor' from 'Data.Profunctor' and 'IxProfunctor' from
-- 'Data.Profunctor.Indexed' into Gongju's open tape composition engine, and provides
-- zero-cost argument permutations for binary profunctor strands and curried effect handlers
-- (such as in @kernmantle-polytropos@).
--
-- Supports:
-- * Contravariant input pre-processing via 'P1' / 'lmap'.
-- * Covariant output post-processing via 'P2' / 'rmap'.
-- * Simultaneous bidirectional mapping via 'dimap'.
-- * Curried category spine generalization and point-free permutations ('CurriedCat', 'ComposeCatN', 'YankCat', 'PermuteCat').
-- * Tuple-spine arrow input/output permutations ('YankTuple', 'PermuteTuple', 'permuteInputs', 'permuteOutputs', 'dimapPermute').
-- * Curried effect handler environment reordering ('permuteHandler', 'compHandlerN').
module Gongju.Profunctor
  ( -- * Re-exported Canonical Profunctor Classes
    Profunctor(..)
  , dimap'
  , lmap'
  , rmap'
    -- * Re-exported Indexed Profunctors
  , IxProfunctor
  , ixcontramap
    -- * Open Profunctor Tags
  , P1
  , P2
    -- * Ergonomic Aliases
  , PP1
  , PP2
    -- * Curried Category Permutations
  , CurriedCat (..)
  , ComposeCatN (..)
  , compCatN
  , YankCat (..)
  , yankCat
  , PermuteCat (..)
  , permuteCat
    -- * Tuple-Spine Arrow Permutations
  , YankTuple (..)
  , yankTuple
  , PermuteTuple (..)
  , permuteTuple
    -- * Profunctor Strand Permutations
  , permuteInputs
  , permuteOutputs
  , dimapPermute
  , swapStrand
    -- * Curried Effect Handler Permutations
  , permuteHandler
  , compHandlerN
  ) where

import Control.Arrow (Arrow (arr, second))
import Control.Category (Category)
import qualified Control.Category as Cat
import Data.Kind (Type)
import qualified Data.Profunctor as P
import Data.Profunctor
  ( Profunctor (..)
  )
import qualified Data.Profunctor.Indexed as IxP
import GHC.TypeLits (Nat)
import Gongju.Composition
  ( ComposeN (..)
  , InOrder
  , MapPath (..)
  , MapStep (..)
  , PL
  , compN
  )
import Gongju.Peano (Peano (..), ToPeano)
import Gongju.Permute
  ( MapAdjust
  , MapToPeano
  , Permute (..)
  , permute
  )
import Prelude hiding (id)

{- Note [Profunctor Effect Handler Permutations]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-profunctor-handler-permutations]
In arrow-based architectures and profunctor effect frameworks (such as 'kernmantle'
and 'kernmantle-polytropos'), effect strands are modeled as binary profunctors:
  @strand :: Type -> Type -> Type@
while effect handlers are curried functions taking environment configuration parameters
before producing or interpreting a strand:
  @handler :: env1 -> env2 -> ... -> p a b@

Permuting profunctor handlers requires addressing two distinct structural axes:
  1. Curried environment parameter permutations:
     Reordering @env1 -> env2 -> ... -> envk@ via 'permuteHandler @ns' (which delegates
     to Gongju's Peano-indexed 'Permute' engine).
  2. Curried category spine generalization:
     Generalizing from @(->)@ to an arbitrary Cartesian Closed Category ('CurriedCat cat')
     via 'YankCat' and 'PermuteCat'. Here, arguments are permuted point-free using only
     'catFlip' and category composition '(.)', never inspecting or allocating Haskell values.
-}

{- Note [Tuple-Spine Arrow Permutations]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-tuple-spine-permutations]
When binary profunctors or arrows consume multiple arguments simultaneously, they package
their input domain as right-nested tuples:
  @(a0, (a1, (a2, ())))@

Permuting slots in an arrow input spine requires structural induction dual to curried 'Yank':
  1. 'YankTuple (n :: Peano) arr s t':
     Pulls the @n@-th slot of the nested tuple to position 0.
     - Base case (@'Z@): The 0-th element is already at the head; returns 'Cat.id'.
     - Step case (@'S n@): Recursively pulls the @n@-th slot in the tail @r@ via
       'second (yankTuple @n)', then swaps the head and extracted slot using
       'arr (\(a, (target, rest)) -> (target, (a, rest)))'.
  2. 'PermuteTuple (ps :: [Peano]) arr s t':
     Iterates 'YankTuple' across a permutation index list, updating residual indices
     at each step with 'MapAdjust'.
  3. 'permuteInputs @ns' and 'permuteOutputs @ns':
     For any 'Profunctor p', pre-composing 'lmap (permuteTuple @ns)' or post-composing
     'rmap (permuteTuple @ns)' reorders the strand's input or output domain directly
     with zero runtime tuple packaging overhead.
-}

-- ---------------------------------------------------------------------------
-- 1. Open Profunctor Tags & Re-exports
-- ---------------------------------------------------------------------------

-- | Profunctor first slot tag (contravariant).
data P1

-- | Profunctor second slot tag (covariant).
data P2

-- | In-order profunctor first-slot (contravariant) mapping alias.
type PP1 = InOrder (PL '[P1])

-- | In-order profunctor second-slot (covariant) mapping alias.
type PP2 = InOrder (PL '[P2])

-- | Type alias specializing 'Data.Profunctor.Indexed.Profunctor' as 'IxProfunctor'.
type IxProfunctor = IxP.Profunctor

-- | Re-export indexed profunctor index contramap.
ixcontramap :: IxProfunctor p => (j -> i) -> p i a b -> p j a b
ixcontramap = IxP.ixcontramap
{-# INLINE ixcontramap #-}

-- | Strict variant of 'dimap'.
dimap' :: Profunctor p => (a -> b) -> (c -> d) -> p b c -> p a d
dimap' = P.dimap
{-# INLINE dimap' #-}

-- | Strict variant of 'lmap'.
lmap' :: Profunctor p => (a -> b) -> p b c -> p a c
lmap' = P.lmap
{-# INLINE lmap' #-}

-- | Strict variant of 'rmap'.
rmap' :: Profunctor p => (b -> c) -> p a b -> p a c
rmap' = P.rmap
{-# INLINE rmap' #-}

-- ---------------------------------------------------------------------------
-- 2. MapStep Instances for Profunctor Layers
-- ---------------------------------------------------------------------------

-- | Pre-compose argument 1 of a Profunctor contravariantly via 'lmap'.
instance (Profunctor p, s ~ p b c, t ~ p a c, MapPath ls a b a b)
  => MapStep P1 ls a b s t where
  mapStep f = P.lmap (mapPath @ls f)
  {-# INLINE mapStep #-}

-- | Post-compose argument 2 of a Profunctor covariantly via 'rmap'.
instance (Profunctor p, s ~ p a b, t ~ p a c, MapPath ls b c b c)
  => MapStep P2 ls b c s t where
  mapStep f = P.rmap (mapPath @ls f)
  {-# INLINE mapStep #-}

-- ---------------------------------------------------------------------------
-- 3. Curried Category Permutations (CurriedCat)
-- ---------------------------------------------------------------------------

-- | Cartesian Closed Category / Curried Category with morphism flipping and application.
--
-- See Note [Profunctor Effect Handler Permutations] [ref:note-profunctor-handler-permutations].
class Category cat => CurriedCat (cat :: Type -> Type -> Type) where
  -- | Post-compose a transformation onto the return slot of a morphism in @cat@.
  catMap :: (b -> c) -> cat a b -> cat a c
  -- | Swap the first two curried inputs of a morphism in @cat@.
  catFlip :: cat a (cat b c) -> cat b (cat a c)
  -- | Bridge morphism execution from Haskell values.
  catApply :: cat a b -> a -> b

instance CurriedCat (->) where
  catMap f g = f . g
  catFlip f b a = f a b
  catApply f x = f x
  {-# INLINE catMap #-}
  {-# INLINE catFlip #-}
  {-# INLINE catApply #-}

-- | Generalized arity composition over a 'Category' @cat@ at the leaf.
class Category cat => ComposeCatN (n :: Peano) (cat :: Type -> Type -> Type) x y z g out | n g -> cat x y, n cat y z g -> out where
  -- | Internal inductive worker for category composition.
  composeCatN' :: cat y z -> g -> out

instance (Category cat, g ~ cat x y, out ~ cat x z) => ComposeCatN 'Z cat x y z g out where
  composeCatN' f g = f Cat.. g
  {-# INLINE composeCatN' #-}

instance ( Category cat
         , ComposeCatN n cat x y z r r'
         , g ~ (a -> r)
         , out ~ (a -> r')
         ) => ComposeCatN ('S n) cat x y z g out where
  composeCatN' f g a = composeCatN' @n @cat @x @y @z f (g a)
  {-# INLINE composeCatN' #-}

-- | User-facing arity composition over any 'Category' @cat@.
compCatN :: forall (n :: Nat) cat x y z g out.
  ComposeCatN (ToPeano n) cat x y z g out => cat y z -> g -> out
compCatN = composeCatN' @(ToPeano n) @cat @x @y @z
{-# INLINE compCatN #-}

-- | Point-free bubbling of the @n@-th curried category input using 'catFlip' and 'catMap'.
--
-- See Note [Profunctor Effect Handler Permutations] [ref:note-profunctor-handler-permutations].
class CurriedCat cat => YankCat (n :: Peano) (cat :: Type -> Type -> Type) f g | n f -> g where
  -- | Internal inductive worker pulling the @n@-th input to position 0.
  yankCat' :: f -> g

instance (CurriedCat cat, f ~ cat a r, g ~ cat a r) => YankCat 'Z cat f g where
  yankCat' = Cat.id
  {-# INLINE yankCat' #-}

instance ( CurriedCat cat
         , f ~ cat a r
         , r' ~ cat target rest
         , g ~ cat target (cat a rest)
         , YankCat n cat r r'
         ) => YankCat ('S n) cat f g where
  yankCat' f = catFlip (catMap (yankCat' @n @cat) f)
  {-# INLINE yankCat' #-}

-- | User-facing positional yank over any 'CurriedCat'.
yankCat :: forall (n :: Nat) cat f g.
  YankCat (ToPeano n) cat f g => f -> g
yankCat = yankCat' @(ToPeano n) @cat
{-# INLINE yankCat #-}

-- | Arbitrary permutation of curried category inputs over any 'CurriedCat'.
--
-- See Note [Profunctor Effect Handler Permutations] [ref:note-profunctor-handler-permutations].
class CurriedCat cat => PermuteCat (ps :: [Peano]) (cat :: Type -> Type -> Type) f g | ps f -> g where
  -- | Internal inductive worker executing iterated point-free permutation.
  permuteCat' :: f -> g

instance (CurriedCat cat, f ~ g) => PermuteCat '[] cat f g where
  permuteCat' = Cat.id
  {-# INLINE permuteCat' #-}

instance ( CurriedCat cat
         , mid ~ cat arg rest
         , g ~ cat arg rest'
         , YankCat p cat f mid
         , PermuteCat (MapAdjust p ps) cat rest rest'
         ) => PermuteCat (p ': ps) cat f g where
  permuteCat' f = catMap (permuteCat' @(MapAdjust p ps) @cat) (yankCat' @p @cat f)
  {-# INLINE permuteCat' #-}

-- | User-facing permutation of curried category inputs.
permuteCat :: forall (ns :: [Nat]) cat f g.
  PermuteCat (MapToPeano ns) cat f g => f -> g
permuteCat = permuteCat' @(MapToPeano ns) @cat
{-# INLINE permuteCat #-}

-- ---------------------------------------------------------------------------
-- 4. Tuple-Spine Arrow Permutations (YankTuple & PermuteTuple)
-- ---------------------------------------------------------------------------

-- | Pull the @n@-th element of a right-nested tuple @s@ to the front.
--
-- See Note [Tuple-Spine Arrow Permutations] [ref:note-tuple-spine-permutations].
class Arrow ar => YankTuple (n :: Peano) (ar :: Type -> Type -> Type) s t | n s -> t where
  -- | Internal inductive worker pulling the @n@-th tuple slot to position 0.
  yankTuple' :: ar s t

instance Arrow ar => YankTuple 'Z ar s s where
  yankTuple' = Cat.id
  {-# INLINE yankTuple' #-}

instance ( Arrow ar
         , YankTuple n ar r (target, rest)
         ) => YankTuple ('S n) ar (a, r) (target, (a, rest)) where
  yankTuple' = arr (\(a, (target, rest)) -> (target, (a, rest))) Cat.. second (yankTuple' @n @ar)
  {-# INLINE yankTuple' #-}

-- | User-facing tuple slot yank for any 'Arrow'.
yankTuple :: forall (n :: Nat) ar s t.
  YankTuple (ToPeano n) ar s t => ar s t
yankTuple = yankTuple' @(ToPeano n) @ar
{-# INLINE yankTuple #-}

-- | Arbitrary permutation of slots in a right-nested tuple spine for an 'Arrow'.
--
-- See Note [Tuple-Spine Arrow Permutations] [ref:note-tuple-spine-permutations].
class Arrow ar => PermuteTuple (ps :: [Peano]) (ar :: Type -> Type -> Type) s t | ps s -> t where
  -- | Internal inductive worker executing iterated tuple slot permutation.
  permuteTuple' :: ar s t

instance Arrow ar => PermuteTuple '[] ar s s where
  permuteTuple' = Cat.id
  {-# INLINE permuteTuple' #-}

instance ( Arrow ar
         , mid ~ (arg, rest)
         , t ~ (arg, rest')
         , YankTuple p ar s mid
         , PermuteTuple (MapAdjust p ps) ar rest rest'
         ) => PermuteTuple (p ': ps) ar s t where
  permuteTuple' = second (permuteTuple' @(MapAdjust p ps) @ar) Cat.. yankTuple' @p @ar
  {-# INLINE permuteTuple' #-}

-- | User-facing tuple spine permutation for any 'Arrow'.
--
-- Examples:
--
-- >>> let t = (10 :: Int, (20 :: Int, (30 :: Int, ())))
-- >>> permuteTuple @'[2, 0, 1] t
-- (30,(10,(20,())))
permuteTuple :: forall (ns :: [Nat]) ar s t.
  PermuteTuple (MapToPeano ns) ar s t => ar s t
permuteTuple = permuteTuple' @(MapToPeano ns) @ar
{-# INLINE permuteTuple #-}

-- ---------------------------------------------------------------------------
-- 5. Profunctor Strand Permutations
-- ---------------------------------------------------------------------------

-- | Permute the right-nested tuple input spine of a 'Profunctor' according to visible 'Nat' list @ns@.
--
-- See Note [Tuple-Spine Arrow Permutations] [ref:note-tuple-spine-permutations].
permuteInputs :: forall (ns :: [Nat]) p s t b.
  (Profunctor p, PermuteTuple (MapToPeano ns) (->) s t) => p t b -> p s b
permuteInputs = P.lmap (permuteTuple @ns)
{-# INLINE permuteInputs #-}

-- | Permute the right-nested tuple output spine of a 'Profunctor' according to visible 'Nat' list @ns@.
--
-- See Note [Tuple-Spine Arrow Permutations] [ref:note-tuple-spine-permutations].
permuteOutputs :: forall (ns :: [Nat]) p a s t.
  (Profunctor p, PermuteTuple (MapToPeano ns) (->) s t) => p a s -> p a t
permuteOutputs = P.rmap (permuteTuple @ns)
{-# INLINE permuteOutputs #-}

-- | Simultaneously permute both the input and output tuple spines of a 'Profunctor'.
dimapPermute :: forall (nsIn :: [Nat]) (nsOut :: [Nat]) p sIn tIn sOut tOut.
  ( Profunctor p
  , PermuteTuple (MapToPeano nsIn) (->) sIn tIn
  , PermuteTuple (MapToPeano nsOut) (->) sOut tOut
  ) => p tIn sOut -> p sIn tOut
dimapPermute = P.dimap (permuteTuple @nsIn) (permuteTuple @nsOut)
{-# INLINE dimapPermute #-}

-- | Swap the binary pair inputs of a 'Profunctor' strand: @p (b, a) c -> p (a, b) c@.
swapStrand :: Profunctor p => p (b, a) c -> p (a, b) c
swapStrand = P.lmap (\(a, b) -> (b, a))
{-# INLINE swapStrand #-}

-- ---------------------------------------------------------------------------
-- 6. Curried Effect Handler Permutations
-- ---------------------------------------------------------------------------

-- | Permute the leading curried environment/configuration arguments of an effect handler.
--
-- See Note [Profunctor Effect Handler Permutations] [ref:note-profunctor-handler-permutations].
--
-- For example, given @handler :: Env1 -> Env2 -> Env3 -> p a b@:
--
-- @
-- let handler' = permuteHandler @'[2, 0, 1] handler
-- -- handler' now expects: Env3 -> Env1 -> Env2 -> p a b
-- @
permuteHandler :: forall (ns :: [Nat]) f g.
  Permute (MapToPeano ns) f g => f -> g
permuteHandler = permute @ns
{-# INLINE permuteHandler #-}

-- | Post-compose an arrow/profunctor transformation onto an @n@-ary curried effect handler.
--
-- For example, applying a strand adapter @(p b c -> q a d)@ to @handler :: env1 -> ... -> envn -> p b c@.
compHandlerN :: forall (n :: Nat) p q a b c d f g.
  ComposeN (ToPeano n) (p b c) (q a d) f g => (p b c -> q a d) -> f -> g
compHandlerN = compN @n
{-# INLINE compHandlerN #-}

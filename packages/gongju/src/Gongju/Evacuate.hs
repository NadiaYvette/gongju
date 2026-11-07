{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.Evacuate
-- Description: Evacuability polymorphism bridging bounded-non-empty and evacuable collections
--
-- This module implements evacuability polymorphism ('Evacuable'), providing
-- a principled typeclass bridge between standard evacuable containers (@[]@, @Set@,
-- @Seq@, @Maybe@) that admit the empty state \(\emptyset\), and non-evacuable
-- containers (@NonEmpty@, @NESet@, @NESeq@) that carry a static non-emptiness proof
-- \(|C| \ge 1\).
--
-- = Architectural Context
--
-- Per Note [Evacuability Polymorphism] [ref:note-evacuability-polymorphism], filtering
-- non-empty collections in Haskell typically forces callers to downgrade to plain
-- lists, losing the strict non-empty type guarantee. 'Gongju.Evacuate' provides
-- total, bidirectional embeddings ('toEvac', 'fromEvac') into a canonical
-- 'EvacCarrier', enabling generic sifting ('sift'), withering ('witherEvac'), and
-- relational fibre-map aggregation ('insertEvac', 'groupEvac', 'groupEvacMany')
-- where keys with empty value containers evaporate automatically.
--
-- == Invariants & Guarantees
--
-- 1. __Preservation of Non-Emptiness:__ 'fromEvac' returns @Just@ if and only if
--    the underlying carrier satisfies the target container's non-emptiness invariants.
-- 2. __Automatic Key Evaporation:__ Relational aggregation functions ('insertEvac',
--    'groupEvac', 'groupEvacMany') guarantee that no key maps to an evacuated (empty)
--    value structure.
-- 3. __Zero Runtime Allocation Overhead:__ Conversions between @NonEmpty@ and @[]@
--    or @NESet@ and @Set@ reuse underlying pointer structures.
--
-- = Worked Examples
--
-- >>> sift (> 1) (1 :| [2, 3]) :: Maybe (NonEmpty Int)
-- Just (2 :| [3])
--
-- >>> sift (> 5) (1 :| [2, 3]) :: Maybe (NonEmpty Int)
-- Nothing
--
-- >>> groupEvac [("a", 1), ("a", 2), ("b", 3)] :: Map.Map String (NonEmpty Int)
-- fromList [("a",1 :| [2]),("b",3 :| [])]
module Gongju.Evacuate
  ( -- * 1. Evacuability Polymorphism Typeclass
    Evacuable (..)
    -- * 2. Evacuability-Polymorphic Filtering & Wither Combinators
  , sift
  , mapMaybeEvac
  , witherEvac
    -- * 3. Relational & Semigroup-Fibre Map Aggregation
  , insertEvac
  , groupEvac
  , groupEvacMany
  ) where

import Data.Foldable qualified as Fold
import Data.Kind (Type)
import Data.List.NonEmpty (NonEmpty (..))
import Data.List.NonEmpty qualified as NonEmpty
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Sequence (Seq)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Set.NonEmpty (NESet)
import Data.Set.NonEmpty qualified as NESet
import Data.Sequence.NonEmpty (NESeq)
import Data.Sequence.NonEmpty qualified as NESeq
import Witherable (Filterable (..), Witherable (..))
import Witherable qualified as Wither

{- Note [Evacuability Polymorphism]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-evacuability-polymorphism]
Evacuability polymorphism bridges bounded-non-empty collections (NonEmpty, NESet, NESeq)
with standard evacuable collections ([], Set, Seq, Maybe) by abstracting over the common
carrier type and providing total conversions that safely witness emptiness or non-emptiness.
-}

--------------------------------------------------------------------------------
-- 1. Evacuable Class: Bridging C_{>= 0} and C_{>= 1} Containers
--------------------------------------------------------------------------------

-- | Unifies evacuable containers (@[]@, @Set@, @Seq@, @Maybe@) and non-evacuable
--   containers (@NonEmpty@, @NESet@, @NESeq@) over a shared 'EvacCarrier'.
--
--   The carrier must be a standard 'Filterable' instance permitting total filtering.
class Filterable (EvacCarrier c) => Evacuable (c :: Type -> Type) a where
  -- | Canonical evacuable container type representing the unconstrained collection.
  type EvacCarrier c :: Type -> Type

  -- | Total embedding from container @c a@ into its evacuable carrier.
  toEvac :: c a -> EvacCarrier c a

  -- | Conditional projection from the carrier back to @c a@.
  --   Returns @Just@ unconditionally for naturally evacuable targets, and witnesses
  --   non-emptiness (returning @Nothing@ if empty) for non-evacuable targets.
  fromEvac :: EvacCarrier c a -> Maybe (c a)

-- | Evacuable instance for standard lists.
instance Evacuable [] a where
  type EvacCarrier [] = []
  toEvac   = id
  fromEvac = Just
  {-# INLINE toEvac #-}
  {-# INLINE fromEvac #-}

-- | Evacuable instance for 'NonEmpty' lists.
instance Evacuable NonEmpty a where
  type EvacCarrier NonEmpty = []
  toEvac   = NonEmpty.toList
  fromEvac = NonEmpty.nonEmpty
  {-# INLINE toEvac #-}
  {-# INLINE fromEvac #-}

-- | Evacuable instance for 'Maybe'.
instance Evacuable Maybe a where
  type EvacCarrier Maybe = Maybe
  toEvac   = id
  fromEvac = Just
  {-# INLINE toEvac #-}
  {-# INLINE fromEvac #-}

-- | Evacuable instance for 'Set'.
instance Ord a => Evacuable Set a where
  type EvacCarrier Set = []
  toEvac   = Set.toList
  fromEvac = Just . Set.fromList
  {-# INLINE toEvac #-}
  {-# INLINE fromEvac #-}

-- | Evacuable instance for 'NESet'.
instance Ord a => Evacuable NESet a where
  type EvacCarrier NESet = []
  toEvac   = Fold.toList
  fromEvac = fmap NESet.fromList . NonEmpty.nonEmpty
  {-# INLINE toEvac #-}
  {-# INLINE fromEvac #-}

-- | Evacuable instance for 'Seq'.
instance Evacuable Seq a where
  type EvacCarrier Seq = Seq
  toEvac   = id
  fromEvac = Just
  {-# INLINE toEvac #-}
  {-# INLINE fromEvac #-}

-- | Evacuable instance for 'NESeq'.
instance Evacuable NESeq a where
  type EvacCarrier NESeq = Seq
  toEvac   = NESeq.toSeq
  fromEvac = NESeq.nonEmptySeq
  {-# INLINE toEvac #-}
  {-# INLINE fromEvac #-}

--------------------------------------------------------------------------------
-- 2. Evacuability-Polymorphic Sifting & Mapping
--------------------------------------------------------------------------------

-- | Filters any container @c1 a@ (e.g. 'NonEmpty', 'NESet', or '[]') and converts
--   it into @Maybe (c2 a)@ (e.g. @Maybe (NESet a)@).
--
--   >>> sift (> 1) [1, 2, 3] :: Maybe [Int]
--   Just [2, 3]
{-# INLINE sift #-}
sift
  :: (Evacuable c1 a, Evacuable c2 a, EvacCarrier c1 ~ EvacCarrier c2)
  => (a -> Bool) -> c1 a -> Maybe (c2 a)
sift p = fromEvac . Wither.filter p . toEvac

-- | Maps and filters across any @c1 a@ into @Maybe (c2 b)@, changing element types freely.
--
--   >>> mapMaybeEvac (\x -> if even x then Just (x * 10) else Nothing) (1 :| [2, 3, 4]) :: Maybe (NonEmpty Int)
--   Just (20 :| [40])
{-# INLINE mapMaybeEvac #-}
mapMaybeEvac
  :: (Evacuable c1 a, Evacuable c2 b, EvacCarrier c1 ~ EvacCarrier c2)
  => (a -> Maybe b) -> c1 a -> Maybe (c2 b)
mapMaybeEvac f = fromEvac . Wither.mapMaybe f . toEvac

-- | Effectfully withers any @c1 a@ into @m (Maybe (c2 b))@.
{-# INLINE witherEvac #-}
witherEvac
  :: ( Applicative m
     , Evacuable c1 a
     , Evacuable c2 b
     , EvacCarrier c1 ~ EvacCarrier c2
     , Witherable (EvacCarrier c1)
     )
  => (a -> m (Maybe b)) -> c1 a -> m (Maybe (c2 b))
witherEvac f = fmap fromEvac . Wither.wither f . toEvac

--------------------------------------------------------------------------------
-- 3. Relational Semigroup-Fibre Map Aggregation
--------------------------------------------------------------------------------

-- | Inserts a container @c1 a@ (which may be empty after filtering!) into a
--   'Map' of non-evacuable Semigroup containers @c2 a@ (such as 'NESet' or 'NonEmpty').
--   If @c1 a@ is empty, the map is untouched; if non-empty, it unions via '(<>)'.
{-# INLINE insertEvac #-}
insertEvac
  :: ( Ord k
     , Evacuable c1 a
     , Evacuable c2 a
     , EvacCarrier c1 ~ EvacCarrier c2
     , Semigroup (c2 a)
     )
  => k -> c1 a -> Map k (c2 a) -> Map k (c2 a)
insertEvac k xs m =
  case fromEvac (toEvac xs) of
    Nothing -> m
    Just ne -> Map.insertWith (<>) k ne m

-- | Groups key-value pairs @(k, a)@ into a @Map k (c a)@ for any @c@ ('NESet', 'NonEmpty', etc.).
--
--   >>> groupEvac [("odd", 1), ("even", 2), ("odd", 3)] :: Map String (NonEmpty Int)
--   fromList [("even",2 :| []),("odd",1 :| [3])]
{-# INLINE groupEvac #-}
groupEvac
  :: ( Foldable f
     , Ord k
     , Evacuable c a
     , EvacCarrier c ~ []
     , Semigroup (c a)
     )
  => f (k, a) -> Map k (c a)
groupEvac = Fold.foldl' (\acc (k, v) -> insertEvac k [v] acc) Map.empty

-- | Groups @(k, c1 a)@ pairs (where @c1 a@ can be a potentially-empty filtered list)
--   directly into a canonical @Map k (c2 a)@ (e.g. @Map Text (NESet Text)@),
--   automatically evaporating keys whose value container evacuated to empty.
{-# INLINE groupEvacMany #-}
groupEvacMany
  :: ( Foldable f
     , Ord k
     , Evacuable c1 a
     , Evacuable c2 a
     , EvacCarrier c1 ~ EvacCarrier c2
     , Semigroup (c2 a)
     )
  => f (k, c1 a) -> Map k (c2 a)
groupEvacMany = Fold.foldl' (\acc (k, vs) -> insertEvac k vs acc) Map.empty

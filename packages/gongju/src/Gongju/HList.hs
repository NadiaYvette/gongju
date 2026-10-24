{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.HList
-- Description: First-class argument lists and isomorphism between curried functions and HLists
--
-- Provides a lightweight heterogeneous list 'HList' and bidirectional isomorphisms ('CurryH')
-- enabling functions to be treated as taking first-class argument bundles.
module Gongju.HList
  ( -- * Heterogeneous List
    HList(..)
    -- * Currying Isomorphism
  , type (->>)
  , CurryH(..)
    -- * Introspection
  , ArgsOf
  , ResultOf
  ) where

import Data.Kind (Type)

-- | Infix right-associative heterogeneous list constructor.
infixr 5 :>

-- | A strongly-typed heterogeneous list storing elements of types @xs@.
data HList (xs :: [Type]) where
  -- | Empty heterogeneous list.
  HNil :: HList '[]
  -- | Prepend an element @x@ to an 'HList' of tail types @xs@.
  (:>) :: x -> HList xs -> HList (x ': xs)

instance Eq (HList '[]) where
  _ == _ = True

instance (Eq x, Eq (HList xs)) => Eq (HList (x ': xs)) where
  (x :> xs) == (y :> ys) = x == y && xs == ys

instance Show (HList '[]) where
  show HNil = "HNil"

instance (Show x, Show (HList xs)) => Show (HList (x ': xs)) where
  show (x :> xs) = show x ++ " :> " ++ show xs

-- | Type family converting a list of argument types and a return type into a curried function arrow.
infixr 0 ->>
type family (xs :: [Type]) ->> (r :: Type) :: Type where
  '[]       ->> r = r
  (x ': xs) ->> r = x -> (xs ->> r)

-- | Bidirectional isomorphism between curried function @f@ and uncurried function @HList xs -> r@.
class CurryH (xs :: [Type]) (r :: Type) (f :: Type) | xs r -> f where
  -- | Curry a function taking an 'HList' bundle into curried form.
  curryH   :: (HList xs -> r) -> f
  -- | Uncurry a curried function into one accepting an 'HList' bundle.
  uncurryH :: f -> (HList xs -> r)

instance CurryH '[] r r where
  curryH k = k HNil
  uncurryH val HNil = val

instance (CurryH xs r f', f ~ (x -> f')) => CurryH (x ': xs) r f where
  curryH k x = curryH (\xs -> k (x :> xs))
  uncurryH f (x :> xs) = uncurryH (f x) xs

-- | Type family decomposing a curried function type into its argument type list.
type family ArgsOf (f :: Type) :: [Type] where
  ArgsOf (a -> b) = a ': ArgsOf b
  ArgsOf _        = '[]

-- | Type family decomposing a curried function type into its terminal non-arrow return type.
type family ResultOf (f :: Type) :: Type where
  ResultOf (a -> b) = ResultOf b
  ResultOf r        = r

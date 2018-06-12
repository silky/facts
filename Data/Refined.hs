{-# LANGUAGE DataKinds              #-}
{-# LANGUAGE DeriveGeneric          #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE TypeFamilyDependencies #-}
{-# LANGUAGE TypeOperators          #-}
{-# LANGUAGE UndecidableInstances   #-}

module Data.Refined
  (
  )
where

import Data.Coerce
import Data.Either (fromRight)
import Data.Kind
import Data.Proxy
import GHC.Generics
import GHC.TypeLits

----------------------------------------------------------------------------
-- Set on type level

type family PropName (p :: *) :: Symbol where
  PropName p = PropName' (Rep p)

type family PropName' (p :: * -> *) :: Symbol where
  PropName' (D1 ('MetaData n m p nt) V1) =
    p `AppendSymbol` "-" `AppendSymbol` m `AppendSymbol` "-" `AppendSymbol` n

type family AddProp (a :: *) (as :: [*]) :: [*] where
  AddProp a '[] = '[a]
  AddProp a (b ': as) = AddPropC (CmpSymbol (PropName a) (PropName b)) a b as

type family AddPropC (o :: Ordering) (a :: *) (b :: *) (as :: [*]) :: [*] where
  AddPropC 'LT a b as = a ': b ': as
  AddPropC 'EQ a b as = a ': as
  AddPropC 'GT a b as = b ': AddProp a as

type family HasProp (a :: *) (ps :: [*]) :: Constraint where
  HasProp a '[] = TypeError
    ('ShowType a ':<>: 'Text " is not a proven property")

type family AddProps (as :: [*]) (ps :: [*]) :: [*] where
  AddProps '[] ps = ps
  AddProps (a ': as) ps = AddProps as (AddProp a ps)

-- type family AddProps (as :: [*]) (bs :: [*]) :: [*] where

----------------------------------------------------------------------------
-- Properties

class Prop a p where

  type PropProjection p :: *

  type PropPremises p :: [*]

  checkProp :: Proxy p -> a -> Either String (PropProjection p)

  -- TODO for efficiency it may make sense to add a special method that only
  -- does checking but not conversion

----------------------------------------------------------------------------
-- Refined data and its construction

newtype Refined (p :: *) (ps :: [*]) a = Refined a

assumeNothing :: a -> Refined p '[] a
assumeNothing = undefined

----------------------------------------------------------------------------
-- Assuming facts

-- TODO unsafe stuff, should fail immediately and show stack traces

----------------------------------------------------------------------------
-- Proving facts

-- TODO try to add stack traces

-- TODO via MonadThrow and MonadFail, and with Either

----------------------------------------------------------------------------
-- Deducing facts

deduce :: (Prop a p, HasProp p ps)
  => Refined p ps a
  -> Refined p' (AddProps (PropPremises p) ps) a
deduce = coerce

conclude :: (Prop a p, HasProps (PropPremises p) ps)
  => Refined p ps a
  -> Refined p' (AddProp p ps) a
conclude = coerce

----------------------------------------------------------------------------
-- Creating APIs that deal with properties

type family HasProps (as :: [*]) (ps :: [*]) :: Constraint where
  HasProps '[] ps = ()
  HasProps (a ': as) ps = (HasProp a ps, HasProps as ps)

----------------------------------------------------------------------------
-- Projections

projectRefined :: forall p ps a. (Prop a p, HasProp p ps)
  => Refined p ps a
  -> PropProjection p
projectRefined (Refined a) =
  fromRight (error "a property has been falsified")
            (checkProp (Proxy :: Proxy p) a)

----------------------------------------------------------------------------
-- Other TODO

-- TH helpers for compile-time validation

----------------------------------------------------------------------------
-- Playground

data FooProp deriving (Generic)
data GooProp deriving (Generic)
data EeeProp deriving (Generic)

foo :: Proxy (AddProp EeeProp (AddProp GooProp (AddProp FooProp '[])))
foo = Proxy

bar :: Proxy (AddProp EeeProp (AddProp FooProp (AddProp GooProp '[])))
bar = Proxy

{-# OPTIONS --cubical --no-import-sorts --safe #-}
module Cubical.Displayed.Properties where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.Equiv

open import Cubical.Functions.FunExtEquiv

open import Cubical.Data.Sigma

open import Cubical.Relation.Binary
open BinaryRelation

open import Cubical.Displayed.Base

private
  variable
    ℓ ℓA ℓA' ℓ≅A ℓ≅A' ℓB ℓB' ℓ≅B ℓ≅B' ℓC ℓ≅C : Level

-- UARel on Σ-type

module _ {A : Type ℓA} {ℓ≅A : Level} {𝒮-A : UARel A ℓ≅A}
  {B : A → Type ℓB} {ℓ≅B : Level}
  (𝒮ᴰ-B : DUARel 𝒮-A B ℓ≅B)
  where

  open UARel 𝒮-A
  open DUARel 𝒮ᴰ-B

  ∫ : UARel (Σ A B) (ℓ-max ℓ≅A ℓ≅B)
  UARel._≅_ ∫ (a , b) (a' , b') = Σ[ p ∈ a ≅ a' ] (b ≅ᴰ⟨ p ⟩ b')
  UARel.ua ∫ (a , b) (a' , b') =
    compEquiv
      (Σ-cong-equiv (ua a a') (λ p → uaᴰ b p b'))
      ΣPath≃PathΣ

-- UARel on Π-type

module _ {A : Type ℓA} (𝒮-A : UARel A ℓ≅A) {B : A → Type ℓB} (𝒮ᴰ-B : DUARel 𝒮-A B ℓ≅B) where

  open UARel 𝒮-A
  open DUARel 𝒮ᴰ-B

  DUARel→Π-UARel : UARel ((a : A) → B a) (ℓ-max ℓA ℓ≅B)
  UARel._≅_ DUARel→Π-UARel f f' = ∀ a → f a ≅ᴰ⟨ ρ a ⟩ f' a
  UARel.ua DUARel→Π-UARel f f' =
    compEquiv
      (equivΠCod λ a → uaᴰρ (f a) (f' a))
      funExtEquiv

-- induction principles

module _ {A : Type ℓA} {ℓ≅A : Level} (𝒮-A : UARel A ℓ≅A) where
  open UARel 𝒮-A
  J-UARel : {a : A}
            (P : (a' : A) → {p : a ≡ a'} → Type ℓ)
            (d : P a {refl})
            {a' : A}
            (p : a ≅ a')
            → P a' {≅→≡ p}
  J-UARel {a} P d {a'} p
    = J (λ y q → P y {q})
        d
        (≅→≡ p)


-- lifts

module _ {A : Type ℓA} (𝒮-A : UARel A ℓ≅A)
  {B : A → Type ℓB}
  {ℓ≅B : Level}
  (𝒮ᴰ-B : DUARel 𝒮-A B ℓ≅B)
  {C : A → Type ℓC}
  (𝒮ᴰ-C : DUARel 𝒮-A C ℓ≅C)
  where

  open DUARel 𝒮ᴰ-B

  Lift-𝒮ᴰ : DUARel (∫ 𝒮ᴰ-C) (λ (a , _) → B a) ℓ≅B
  DUARel._≅ᴰ⟨_⟩_ Lift-𝒮ᴰ b p b' = b ≅ᴰ⟨ p .fst ⟩ b'
  DUARel.uaᴰ Lift-𝒮ᴰ b p b' = uaᴰ b (p .fst) b'


-- associativity

module _ {A : Type ℓA} (𝒮-A : UARel A ℓ≅A)
  {B : A → Type ℓB} {ℓ≅B : Level} (𝒮ᴰ-B : DUARel 𝒮-A B ℓ≅B)
  {C : Σ A B → Type ℓC} {ℓ≅C : Level} (𝒮ᴰ-C : DUARel (∫ 𝒮ᴰ-B) C ℓ≅C)
  where

  open UARel 𝒮-A
  open DUARel 𝒮ᴰ-B renaming (_≅ᴰ⟨_⟩_ to _≅B⟨_⟩_ ; uaᴰ to uaB)
  open DUARel 𝒮ᴰ-C renaming (_≅ᴰ⟨_⟩_ to _≅C⟨_⟩_ ; uaᴰ to uaC)

  splitTotal-𝒮ᴰ : DUARel 𝒮-A (λ a → Σ[ b ∈ B a ] C (a , b)) (ℓ-max ℓ≅B ℓ≅C)
  DUARel._≅ᴰ⟨_⟩_ splitTotal-𝒮ᴰ (b , c) p (b' , c') =
    Σ[ q ∈ b ≅B⟨ p ⟩ b' ]  (c ≅C⟨ p , q ⟩ c')
  DUARel.uaᴰ splitTotal-𝒮ᴰ (b ,  c) p (b' , c') =
    compEquiv
      (Σ-cong-equiv (uaB b p b') (λ q → uaC c (p , q) c'))
      ΣPath≃PathΣ

-- combination

module _ {A : Type ℓA} {𝒮-A : UARel A ℓ≅A}
  {B : A → Type ℓB} {ℓ≅B : Level} (𝒮ᴰ-B : DUARel 𝒮-A B ℓ≅B)
  {C : A → Type ℓC} {ℓ≅C : Level} (𝒮ᴰ-C : DUARel 𝒮-A C ℓ≅C)
  where

  _×𝒮ᴰ_ : DUARel 𝒮-A (λ a → B a × C a) (ℓ-max ℓ≅B ℓ≅C)
  _×𝒮ᴰ_ = splitTotal-𝒮ᴰ 𝒮-A 𝒮ᴰ-B (Lift-𝒮ᴰ 𝒮-A 𝒮ᴰ-C 𝒮ᴰ-B)

-- constant displayed structure

module _ {A : Type ℓA} (𝒮-A : UARel A ℓ≅A)
  {B : Type ℓB} (𝒮-B : UARel B ℓ≅B)  where

  open UARel 𝒮-B
  open DUARel

  𝒮ᴰ-const : DUARel 𝒮-A (λ _ → B) ℓ≅B
  𝒮ᴰ-const ._≅ᴰ⟨_⟩_ b _ b' = b ≅ b'
  𝒮ᴰ-const .uaᴰ b p b' = ua b b'

  -- UARel product

  _×𝒮_ : UARel (A × B) (ℓ-max ℓ≅A ℓ≅B)
  _×𝒮_ = ∫ 𝒮ᴰ-const



-- relational isomorphisms

UARelIso→Iso : {A : Type ℓA} (𝒮-A : UARel A ℓ≅A)
               {B : Type ℓB} (𝒮-B : UARel B ℓ≅B)
               (F : RelIso (UARel._≅_ 𝒮-A) (UARel._≅_ 𝒮-B))
               → Iso A B
UARelIso→Iso 𝒮-A 𝒮-B F
  = RelIso→Iso (UARel._≅_ 𝒮-A)
               (UARel._≅_ 𝒮-B)
               (UARel.≅→≡ 𝒮-A)
               (UARel.≅→≡ 𝒮-B)
               F

-- fiberwise relational isomorphisms

module _ {A : Type ℓA} {𝒮-A : UARel A ℓ≅A}
  {A' : Type ℓA'} {𝒮-A' : UARel A' ℓ≅A'}
  (F : Iso A A')
  {B : A → Type ℓB} (𝒮ᴰ-B : DUARel 𝒮-A B ℓ≅B)
  {B' : A' → Type ℓB'} (𝒮ᴰ-B' : DUARel 𝒮-A' B' ℓ≅B') where

  open UARel 𝒮-A
  open DUARel 𝒮ᴰ-B renaming (_≅ᴰ⟨_⟩_ to _≅B⟨_⟩_
                            ; uaᴰ to uaB
                            ; fiberRel to fiberRelB
                            ; uaᴰρ to uaᴰρB)
  open DUARel 𝒮ᴰ-B' renaming (_≅ᴰ⟨_⟩_ to _≅B'⟨_⟩_
                             ; uaᴰ to uaB'
                             ; fiberRel to fiberRelB'
                             ; uaᴰρ to uaᴰρB')

  f = Iso.fun F

  -- the following can of course be done slightly more generally
  -- for fiberwise binary relations

  F*fiberRelB' : (a : A) → Rel (B' (f a)) (B' (f a)) ℓ≅B'
  F*fiberRelB' a = fiberRelB' (f a)

  module _ (G : (a : A) → RelIso (fiberRelB a) (F*fiberRelB' a)) where
    fiberIsoOver : (a : A) → Iso (B a) (B' (f a))
    fiberIsoOver a
      = RelIso→Iso (fiberRelB a)
                   (F*fiberRelB' a)
                   (equivFun (uaᴰρB _ _))
                   (equivFun (uaᴰρB' _ _))
                   (G a)

    DUARelFiberIsoOver→TotalIso : Iso (Σ A B) (Σ A' B')
    DUARelFiberIsoOver→TotalIso = Σ-cong-iso F fiberIsoOver

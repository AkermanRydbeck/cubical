{-A
Polynomials over commutative rings
==================================
-}
{-# OPTIONS --safe #-}

----------------------------------

module Cubical.Algebra.Polynomials where

open import Cubical.HITs.PropositionalTruncation

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.HLevels

open import Cubical.Data.Sigma
open import Cubical.Data.Nat renaming (_+_ to _Nat+_; _·_ to _Nat·_) hiding (·-comm)
open import Cubical.Data.Nat.Order
open import Cubical.Data.Empty.Base renaming (rec to ⊥rec )
open import Cubical.Data.Bool

open import Cubical.Algebra.Group hiding (Bool)
open import Cubical.Algebra.Ring
open import Cubical.Algebra.CommRing

------------------------------------------------------------------------------------

private
  variable
    ℓ ℓ' : Level
    A : Type ℓ

module PolyMod (R' : CommRing ℓ) where
  private
    R = fst R'
  open CommRingStr (snd R') public

-------------------------------------------------------------------------------------------
-- First definition of a polynomial.
-- A polynomial a₁ +  a₂x + ... + aⱼxʲ of order j is represented as a list [a₁, a₂, ...,aⱼ]
-------------------------------------------------------------------------------------------

  data Poly : Type ℓ where
    []    : Poly
    _∷_  : (a : R) → (p : Poly) → Poly
    drop0 : 0r ∷ [] ≡ []

  infixr 5 _∷_


  module Elim (B      : Poly → Type ℓ')
              ([]*    : B [])
              (cons*  : (r : R) (p : Poly) (b : B p) → B (r ∷ p))
              (drop0* : PathP (λ i → B (drop0 i)) (cons* 0r [] []*) []*) where

   f : (p : Poly) → B p
   f [] = []*
   f (x ∷ p) = cons* x p (f p)
   f (drop0 i) = drop0* i


  -- Given a proposition (as type) ϕ ranging over polynomials, we prove it by:
  -- ElimProp.f ϕ ⌜proof for base case []⌝ ⌜proof for induction case a ∷ p⌝
  --           ⌜proof that ϕ actually is a proposition over the domain of polynomials⌝
  module ElimProp (B : Poly → Type ℓ')
                  ([]* : B [])
                  (cons* : (r : R) (p : Poly) (b : B p) → B (r ∷ p))
                  (BProp : {p : Poly} → isProp (B p)) where
   f : (p : Poly) → B p
   f = Elim.f B []* cons* (toPathP (BProp (transport (λ i → B (drop0 i)) (cons* 0r [] []*)) []*))


  module Rec (B : Type ℓ')
             ([]* : B)
             (cons* : R → B → B)
             (drop0* : cons* 0r []* ≡ []*)
                          (Bset : isSet B) where
    f : Poly → B
    f = Elim.f (λ _ → B) []* (λ r p b → cons* r b) drop0*


  module RecPoly ([]* : Poly) (cons* : R → Poly → Poly) (drop0* : cons* 0r []* ≡ []*) where
    f : Poly → Poly
    f [] = []*
    f (a ∷ p) = cons* a (f p)
    f (drop0 i) = drop0* i



--------------------------------------------------------------------------------------------------
-- Second definition of a polynomial. The purpose of this second definition is to
-- facilitate the proof that the first definition is a set. The two definitions are
-- then shown to be equivalent.
-- A polynomial a₀ +  a₁x + ... + aⱼxʲ of order j is represented as a function f
-- such that for i ∈ ℕ we have  f(i) = aᵢ if i ≤ j, and 0 for i > j
--------------------------------------------------------------------------------------------------

  PolyFun : Type ℓ
  PolyFun = Σ[ p ∈ (ℕ → R) ] (∃[ n ∈ ℕ ] ((m : ℕ) → n ≤ m → p m ≡ 0r))


  IsSetPolyFun : isSet PolyFun
  IsSetPolyFun = isSetΣSndProp (isSetΠ (λ x → isSetCommRing R')) λ f x y → squash x y


  IsZero : ℕ → Bool
  IsZero zero = true
  IsZero (suc n) = false


  --construction of the function that represents the polynomial
  Poly→Fun : Poly → (ℕ → R)
  Poly→Fun [] = (λ _ → 0r)
  Poly→Fun (a ∷ p) = (λ n → if IsZero n then a else Poly→Fun p (predℕ n))
  Poly→Fun (drop0 i) = lemma i
    where
    lemma : (λ n → if IsZero n then 0r else 0r) ≡ (λ _ → 0r)
    lemma i zero = 0r
    lemma i (suc n) = 0r


  Poly→Prf : (p : Poly) → ∃[ n ∈ ℕ ] ((m : ℕ) → n ≤ m → (Poly→Fun p m ≡ 0r))
  Poly→Prf = ElimProp.f (λ p →  ∃[ n ∈ ℕ ] ((m : ℕ) → n ≤ m → (Poly→Fun p m ≡ 0r)))
                        ∣ 0 , (λ m ineq → refl) ∣
                        (λ r p → map ( λ (n , ineq) → (suc n) ,
                                       λ { zero h → ⊥rec (znots (sym (≤0→≡0 h))) ;
                                           (suc m) h → ineq m (pred-≤-pred h)
                                         }
                                     )
                        )
                        squash

  Poly→PolyFun : Poly → PolyFun
  Poly→PolyFun p = (Poly→Fun p) , (Poly→Prf p)


----------------------------------------------------
-- Start of code by Anders Mörtberg and Evan Cavallo


  at0 : (ℕ → R) → R
  at0 f = f 0

  atS : (ℕ → R) → (ℕ → R)
  atS f n = f (suc n)

  polyEq : (p p' : Poly) → Poly→Fun p ≡ Poly→Fun p' → p ≡ p'
  polyEq [] [] _ = refl
  polyEq [] (a ∷ p') α =
    sym drop0 ∙∙ cong₂ _∷_ (cong at0 α) (polyEq [] p' (cong atS α)) ∙∙ refl
  polyEq [] (drop0 j) α k =
    hcomp
      (λ l → λ
        { (j = i1) → drop0 l
        ; (k = i0) → drop0 l
        ; (k = i1) → drop0 (j ∧ l)
        })
      (is-set 0r 0r (cong at0 α) refl j k ∷ [])
  polyEq (a ∷ p) [] α =
    refl ∙∙ cong₂ _∷_ (cong at0 α) (polyEq p [] (cong atS α)) ∙∙ drop0
  polyEq (a ∷ p) (a₁ ∷ p') α =
    cong₂ _∷_ (cong at0 α) (polyEq p p' (cong atS α))
  polyEq (a ∷ p) (drop0 j) α k =
    hcomp -- filler
      (λ l → λ
        { (k = i0) → a ∷ p
        ; (k = i1) → drop0 (j ∧ l)
        ; (j = i0) → at0 (α k) ∷ polyEq p [] (cong atS α) k
        })
      (at0 (α k) ∷ polyEq p [] (cong atS α) k)
  polyEq (drop0 i) [] α k =
    hcomp
      (λ l → λ
        { (i = i1) → drop0 l
        ; (k = i0) → drop0 (i ∧ l)
        ; (k = i1) → drop0 l
        })
      (is-set 0r 0r (cong at0 α) refl i k ∷ [])
  polyEq (drop0 i) (a ∷ p') α k =
    hcomp -- filler
      (λ l → λ
        { (k = i0) → drop0 (i ∧ l)
        ; (k = i1) → a ∷ p'
        ; (i = i0) → at0 (α k) ∷ polyEq [] p' (cong atS α) k
        })
      (at0 (α k) ∷ polyEq [] p' (cong atS α) k)
  polyEq (drop0 i) (drop0 j) α k =
    hcomp
      (λ l → λ
        { (k = i0) → drop0 (i ∧ l)
        ; (k = i1) → drop0 (j ∧ l)
        ; (i = i0) (j = i0) → at0 (α k) ∷ []
        ; (i = i1) (j = i1) → drop0 l
        })
      (is-set 0r 0r (cong at0 α) refl (i ∧ j) k ∷ [])


  PolyFun→Poly+ : (q : PolyFun) → Σ[ p ∈ Poly ] Poly→Fun p ≡ q .fst
  PolyFun→Poly+ (f , pf) = rec lem (λ x → help f (x .fst) (x .snd) ,
                                               funExt (bar f (fst x) (snd x))
                                   ) pf
    where
    lem : isProp (Σ[ p ∈ Poly ] Poly→Fun p ≡ f)
    lem (p , α) (p' , α') =
      ΣPathP (polyEq p p' (α ∙ sym α'), isProp→PathP (λ i → (isSetΠ λ _ → is-set) _ _) _ _)

    help : (p : ℕ → R) (n : ℕ) → ((m : ℕ) → n ≤ m → p m ≡ 0r) → Poly
    help p zero h = []
    help p (suc n) h = p 0 ∷ help (λ x → p (suc x)) n (λ m x → h (suc m) (suc-≤-suc x))

    bar : (f : ℕ → R) (n : ℕ) → (h : (m : ℕ) → n ≤ m → f m ≡ 0r) (m : ℕ) →
                                                                 Poly→Fun (help f n h) m ≡ f m
    bar f zero h m = sym (h m zero-≤)
    bar f (suc n) h zero = refl
    bar f (suc n) h (suc m) = bar (λ x → f (suc x)) n (λ k p → h (suc k) (suc-≤-suc p)) m

  PolyFun→Poly : PolyFun → Poly
  PolyFun→Poly q = PolyFun→Poly+ q .fst

  lemmaisSet : (p : Poly) → PolyFun→Poly (Poly→PolyFun p) ≡ p
  lemmaisSet p = polyEq _ _ (PolyFun→Poly+ (Poly→PolyFun p) .snd)



--End of code by Mörtberg and Cavallo
-------------------------------------

  IsSetPoly : isSet Poly
  IsSetPoly = isSetRetract Poly→PolyFun
                           PolyFun→Poly
                           (λ p → lemmaisSet p)
                           IsSetPolyFun


-------------------------------------------------
-- The rest of the file uses the first definition
-------------------------------------------------

  open CommRingTheory R'
  open RingTheory (CommRing→Ring R')
  open GroupTheory (Ring→Group (CommRing→Ring R'))


  pattern [_] x = x ∷ []


  -- The proof that Poly is a set will be used in the propositional eliminations
  -- for the last case in ElimProp
  PolyIsSet : isSet Poly
  PolyIsSet = IsSetPoly


---------------------------------------
-- Definition
-- Identity for addition of polynomials
---------------------------------------
  0P : Poly
  0P = []


  --ReplicatePoly(n,p) returns 0 ∷ 0 ∷ ... ∷ [] (n zeros)
  ReplicatePoly : (n : ℕ)  → Poly
  ReplicatePoly zero  = 0P
  ReplicatePoly (suc n) = 0r ∷ ReplicatePoly n


  --The empty polynomial has multiple equal representations on the form 0 + 0x + 0 x² + ...
  ReplicatedZeros=[] : ∀ (n : ℕ) → ReplicatePoly n ≡ 0P
  ReplicatedZeros=[] zero = refl
  ReplicatedZeros=[] (suc n) = (cong (0r ∷_) (ReplicatedZeros=[] n)) ∙ drop0


-----------------------------
-- Definition
-- subtraction of polynomials
-----------------------------
  Poly- : Poly → Poly
  Poly- [] = []
  Poly- (a ∷ p) = (- a) ∷ (Poly- p)
  Poly- (drop0 i) = (cong (_∷ []) (inv1g) ∙ drop0) i

  -- Double negation (of subtraction of polynomials) is the identity mapping
  Poly-Poly-P=P : (p : Poly) → Poly- (Poly- p) ≡ p
  Poly-Poly-P=P = ElimProp.f (λ x → Poly- (Poly- x) ≡ x)
                             (refl)
                             (λ a p e → cong (_∷ (Poly- (Poly- p)))
                                             (-Idempotent a) ∙ cong (a ∷_ ) (e))
                             (PolyIsSet _ _)


---------------------------
-- Definition
-- addition for polynomials
---------------------------
  _Poly+_ : Poly → Poly → Poly
  p Poly+ [] = p
  [] Poly+ (drop0 i) = drop0 i
  [] Poly+ (b ∷ q) = b ∷ q
  (a ∷ p) Poly+ (b ∷ q) = (a + b) ∷ (p Poly+ q)
  (a ∷ p) Poly+ (drop0 i) = +Rid a i ∷ p
  (drop0 i) Poly+ (a ∷ q) = lem q i  where
                                 lem : ∀ q → (0r + a) ∷ ([] Poly+ q) ≡ a ∷ q
                                 lem = ElimProp.f (λ q → (0r + a) ∷ ([] Poly+ q) ≡ a ∷ q)
                                                  (λ i → (+Lid a i ∷ []))
                                                  (λ r p _ → λ i → +Lid a i ∷ r ∷ p )
                                                  (PolyIsSet _ _)
  (drop0 i) Poly+ (drop0 j) =  isSet→isSet' PolyIsSet  (cong ([_] ) (+Rid 0r)) drop0
                                                       (cong ([_] ) (+Lid 0r)) drop0 i j


  -- [] is the left identity for Poly+
  Poly+Lid : ∀ p → ([] Poly+ p ≡ p)
  Poly+Lid =  ElimProp.f (λ p → ([] Poly+ p ≡ p) )
                         (refl)
                         (λ r p prf → refl)
                         (λ x y → PolyIsSet _ _ x y)



  -- [] is the right identity for Poly+
  Poly+Rid : ∀ p → (p Poly+ [] ≡ p)
  Poly+Rid = λ p → refl



  --Poly+ is Associative
  Poly+Assoc : ∀ p q r → p Poly+ (q Poly+ r) ≡ (p Poly+ q) Poly+ r
  Poly+Assoc =
    ElimProp.f (λ p → (∀ q r → p Poly+ (q Poly+ r) ≡ (p Poly+ q) Poly+ r))
               (λ q r → Poly+Lid (q Poly+ r) ∙ cong (_Poly+ r)  (sym (Poly+Lid q)))
               (λ a p prf → ElimProp.f ((λ q → ∀ r → ((a ∷ p) Poly+ (q Poly+ r)) ≡
                                                   (((a ∷ p) Poly+ q) Poly+ r)))
                                       (λ r → cong ((a ∷ p) Poly+_) (Poly+Lid r))
                                       (λ b q prf2 →
                                       ElimProp.f
                                         (λ r → ((a ∷ p) Poly+ ((b ∷ q) Poly+ r)) ≡
                                                 ((a + b ∷ (p Poly+ q)) Poly+ r))
                                         refl
                                         (λ c r prfp → cong ((a + (b + c))∷_)
                                                            (prf q r) ∙
                                                            (cong (_∷ ((p Poly+ q) Poly+ r))
                                                                  (+Assoc a b c)))
                                         (PolyIsSet _ _))
                                       λ x y i r → PolyIsSet (x r i0) (y r i1) (x r) (y r) i)
                λ x y i q r  → PolyIsSet _ _ (x q r) (y q r) i



  -- for any polynomial, p, the additive inverse is given by Poly- p
  Poly+Inverses : ∀ p → p Poly+ (Poly- p) ≡ []
  Poly+Inverses = ElimProp.f ( λ p → p Poly+ (Poly- p) ≡ [])
                             (Poly+Lid (Poly- [])) --refl
                             (λ r p prf → cong (r + - r ∷_) prf ∙
                                          (cong (_∷ [])  (+Rinv r) ∙ drop0))
                             (PolyIsSet _ _)



  --Poly+ is commutative
  Poly+Comm : ∀ p q → p Poly+ q ≡ q Poly+ p
  Poly+Comm = ElimProp.f (λ p → (∀ q → p Poly+ q ≡ q Poly+ p))
                         (λ q → Poly+Lid q)
                         (λ a p prf → ElimProp.f (λ q → ((a ∷ p) Poly+ q) ≡ (q Poly+ (a ∷ p)))
                                                 refl
                                                 (λ b q prf2 → cong (_∷ (p Poly+ q)) (+Comm a b) ∙
                                                               cong ((b + a) ∷_) (prf q))
                                                 (PolyIsSet _ _)
                         )
                         (λ {p} → isPropΠ (λ q → PolyIsSet (p Poly+ q) (q Poly+ p)))

--------------------------------------------------------------
-- Definition
-- multiplication of a polynomial by a (constant) ring element
--------------------------------------------------------------
  _PolyConst*_ : (R) → Poly → Poly
  r PolyConst* [] = []
  r PolyConst* (a ∷ p) = (r · a) ∷ (r PolyConst* p)
  r PolyConst* (drop0 i) = lem r i where
                                 lem : ∀ r → [ r · 0r ] ≡ []
                                 lem =  λ r → [ r · 0r ] ≡⟨ cong (_∷ []) (0RightAnnihilates r) ⟩
                                        [ 0r ] ≡⟨ drop0 ⟩
                                        [] ∎


  -- For any polynomial p we have: 0 _PolyConst*_ p = []
  0rLeftAnnihilatesPoly : ∀ q → 0r PolyConst* q ≡ [ 0r ]
  0rLeftAnnihilatesPoly = ElimProp.f (λ q → 0r PolyConst* q ≡ [ 0r ])
                                         (sym drop0)
                                         (λ r p prf → cong ((0r · r) ∷_) prf ∙
                                                      cong (_∷ [ 0r ]) (0LeftAnnihilates r) ∙
                                                      cong (0r ∷_) drop0 )
                                         λ x y → PolyIsSet _ _ x y


  -- For any polynomial p we have: 1 _PolyConst*_ p = p
  PolyConst*Lid : ∀ q → 1r PolyConst* q ≡ q
  PolyConst*Lid = ElimProp.f (λ q → 1r PolyConst* q ≡ q ) refl
                             (λ a p prf → cong (_∷ (1r PolyConst* p)) (·Lid a) ∙
                                          cong (a ∷_) (prf) )
                             λ x y → PolyIsSet _ _ x y


--------------------------------
-- Definition
-- Multiplication of polynomials
--------------------------------
  _Poly*_ : Poly → Poly → Poly
  [] Poly* q = []
  (a ∷ p) Poly* q = (a PolyConst* q) Poly+ (0r ∷ (p Poly* q))
  (drop0 i) Poly* q = lem q i where
                               lem : ∀ q → (0r PolyConst* q) Poly+ [ 0r ] ≡ []
                               lem = λ q → ((0r PolyConst* q) Poly+ [ 0r ]) ≡⟨ cong ( _Poly+ [ 0r ] ) (0rLeftAnnihilatesPoly q)⟩
                                           ([ 0r ] Poly+ [ 0r ]) ≡⟨ cong (_∷ []) 0Idempotent  ∙ drop0 ⟩
                                           [] ∎


--------------------
--Definition
--Identity for Poly*
--------------------
  1P : Poly
  1P = [ 1r ]


  -- For any polynomial p we have: p Poly* [] = []
  0PRightAnnihilates : ∀ q → 0P Poly* q ≡ 0P
  0PRightAnnihilates = ElimProp.f (λ q → 0P Poly* q ≡ 0P)
                                  refl
                                  (λ r p prf → prf)
                                  λ x y → PolyIsSet _ _ x y


  -- For any polynomial p we have: [] Poly* p = []
  0PLeftAnnihilates : ∀ p → p Poly* 0P ≡ 0P
  0PLeftAnnihilates = ElimProp.f (λ p → p Poly* 0P ≡ 0P )
                                 refl
                                 (λ r p prf → cong (0r ∷_) prf ∙ drop0)
                                 λ x y → PolyIsSet _ _ x y


  -- For any polynomial p we have: p Poly* [ 1r ] = p
  Poly*Lid : ∀ q → 1P Poly* q ≡ q
  Poly*Lid =
    ElimProp.f (λ q → 1P Poly* q ≡ q)
               drop0
               (λ r p prf → lemma r p)
               (λ x y → PolyIsSet _ _ x y)
                 where
                 lemma : ∀ r p → 1r · r + 0r ∷ (1r PolyConst* p) ≡ r ∷ p
                 lemma =
                   λ r p → 1r · r + 0r ∷ (1r PolyConst* p) ≡⟨ cong (_∷ (1r PolyConst* p) )
                                                                   (+Rid (1r · r)) ⟩
                           1r · r ∷ (1r PolyConst* p) ≡⟨ cong (_∷ 1r PolyConst* p) (·Lid r) ⟩
                           r ∷ (1r PolyConst* p) ≡⟨ cong (r ∷_) (PolyConst*Lid p) ⟩
                           r ∷ p ∎


  -- Distribution of indeterminate: (p + q)x = px + qx
  XLDistrPoly+ : ∀ p q → (0r ∷ (p Poly+ q)) ≡ ((0r ∷ p) Poly+ (0r ∷ q))
  XLDistrPoly+ =
    ElimProp.f (λ p → ∀ q → (0r ∷ (p Poly+ q)) ≡ ((0r ∷ p) Poly+ (0r ∷ q)) )
               (λ q → (cong (0r ∷_) (Poly+Lid q)) ∙
                      cong (0r ∷_) (sym (Poly+Lid q)) ∙
                      sym (cong (_∷ [] Poly+ q) (+Lid 0r)))
               (λ a p prf → ElimProp.f (λ q → 0r ∷ ((a ∷ p) Poly+ q) ≡
                                         ((0r ∷ a ∷ p) Poly+ (0r ∷ q)))
                                       (cong (_∷ a ∷ p ) (sym (+Lid 0r)))
                                       (λ b q prf2 → cong (_∷ a + b ∷ (p Poly+ q)) (sym (+Lid 0r)))
                                       (λ x y i → PolyIsSet (x i0) (x i1) x y i))
               (λ x y i q → PolyIsSet (x q i0) (x q i1) (x q) (y q) i)


  -- Distribution of a constant ring element over added polynomials p, q: a (p + q) = ap + aq
  PolyConst*LDistrPoly+ : ∀ a p q → a PolyConst* (p Poly+ q) ≡
                                    (a PolyConst* p) Poly+ (a PolyConst* q)
  PolyConst*LDistrPoly+ =
    λ a → ElimProp.f (λ p → ∀ q → a PolyConst* (p Poly+ q) ≡
                                  (a PolyConst* p) Poly+ (a PolyConst* q))
                     (λ q → cong (a PolyConst*_) (Poly+Lid q) ∙
                            (sym (Poly+Lid (a PolyConst* q))))
                     (λ b p prf → ElimProp.f (λ q → (a PolyConst* ((b ∷ p) Poly+ q)) ≡
                                                    (a PolyConst* (b ∷ p)) Poly+ (a PolyConst* q))
                                             refl
                                             (λ c q prf2  → cong (_∷ (a PolyConst* (p Poly+ q)))
                                                                 (·Rdist+ a b c) ∙
                                                            cong (a · b + a · c ∷_) (prf q))
                                             (PolyIsSet _ _))
                     (λ x y i q  → PolyIsSet (x q i0) (x q i1) (x q) (y q) i)



  --Poly* left distributes over Poly+
  Poly*LDistrPoly+ : ∀ p q r → p Poly* (q Poly+ r) ≡ (p Poly* q) Poly+ (p Poly* r)
  Poly*LDistrPoly+ =
    ElimProp.f
      (λ p → ∀ q r → p Poly* (q Poly+ r) ≡ (p Poly* q) Poly+ (p Poly* r))
      (λ _ _ → refl)
      (λ a p prf q r → ((a PolyConst* (q Poly+ r)) Poly+
                        (0r ∷(p Poly*(q Poly+ r)))) ≡⟨
                                                      cong (_Poly+ (0r ∷ (p Poly* (q Poly+ r))))
                                                           (PolyConst*LDistrPoly+ a q r)
                                                     ⟩
      (((a PolyConst* q) Poly+ (a PolyConst* r)) Poly+
        (0r ∷ (p Poly* (q Poly+ r)))) ≡⟨
                                        cong (((a PolyConst* q) Poly+ (a PolyConst* r)) Poly+_)
                                             (cong (0r ∷_) (prf q r))
                                       ⟩
      (((a PolyConst* q) Poly+ (a PolyConst* r)) Poly+
        (0r ∷ ((p Poly* q) Poly+ (p Poly* r)))) ≡⟨
                                                  cong (((a PolyConst* q) Poly+
                                                         (a PolyConst* r)) Poly+_)
                                                  (XLDistrPoly+ (p Poly* q) (p Poly* r))
                                                 ⟩
      (((a PolyConst* q) Poly+ (a PolyConst* r)) Poly+
        ((0r ∷ (p Poly* q)) Poly+ (0r ∷ (p Poly* r)))) ≡⟨
                                                         Poly+Assoc ((a PolyConst* q) Poly+
                                                                      (a PolyConst* r))
                                                                    (0r ∷ (p Poly* q))
                                                                    (0r ∷ (p Poly* r))
                                                        ⟩
      (((a PolyConst* q) Poly+ (a PolyConst* r)) Poly+
        (0r ∷ (p Poly* q))) Poly+ (0r ∷ (p Poly* r)) ≡⟨ cong (_Poly+ (0r ∷ (p Poly* r)))
                                                             (sym (Poly+Assoc (a PolyConst* q)
                                                                              (a PolyConst* r)
                                                                              (0r ∷ (p Poly* q))))
                                                    ⟩
      (((a PolyConst* q) Poly+ ((a PolyConst* r) Poly+
        (0r ∷ (p Poly* q)))) Poly+ (0r ∷ (p Poly* r))) ≡⟨
                                                         cong (_Poly+ (0r ∷ (p Poly* r)))
                                                              (cong ((a PolyConst* q) Poly+_)
                                                                    (Poly+Comm (a PolyConst* r)
                                                                               (0r ∷ (p Poly* q))))
                                                         ⟩
      (((a PolyConst* q) Poly+ ((0r ∷ (p Poly* q)) Poly+
        (a PolyConst* r))) Poly+ (0r ∷ (p Poly* r))) ≡⟨
                                                       cong (_Poly+ (0r ∷ (p Poly* r)))
                                                            (Poly+Assoc (a PolyConst* q)
                                                                        (0r ∷ (p Poly* q))
                                                                        (a PolyConst* r))
                                                            ⟩
      ((((a PolyConst* q) Poly+ (0r ∷ (p Poly* q))) Poly+
        (a PolyConst* r)) Poly+ (0r ∷ (p Poly* r))) ≡⟨
                                                      sym (Poly+Assoc ((a PolyConst* q) Poly+
                                                                         (0r ∷ (p Poly* q)))
                                                                      ((a PolyConst* r))
                                                                      ((0r ∷ (p Poly* r))))
                                                     ⟩
      ((a PolyConst* q) Poly+ (0r ∷ (p Poly* q))) Poly+
        ((a PolyConst* r) Poly+ (0r ∷ (p Poly* r))) ∎)
      (λ x y i q r → PolyIsSet _ _ (x q r) (y q r) i)


  -- The constant multiplication of a ring element, a, with a polynomial, p, can be
  -- expressed by polynomial multiplication with the singleton polynomial [ a ]
  PolyConst*r=Poly*[r] : ∀ a p → a PolyConst* p ≡ p Poly* [ a ]
  PolyConst*r=Poly*[r] =
    λ a → ElimProp.f (λ p → a PolyConst* p ≡ p Poly* [ a ])
                     refl
                     ( λ r p prf →  a · r ∷ (a PolyConst* p) ≡⟨
                                                              cong (a · r ∷_) prf
                                                             ⟩
                       a · r ∷ (p Poly* [ a ]) ≡⟨
                                                 cong (a · r ∷_)
                                                      (sym (Poly+Lid (p Poly* [ a ])))
                                                ⟩
                       a · r ∷ ([] Poly+ (p Poly* [ a ])) ≡⟨
                                                            cong (_∷ ([] Poly+ (p Poly* [ a ])))
                                                                 (·Comm a r )
                                                           ⟩
                       r · a ∷ ([] Poly+ (p Poly* [ a ])) ≡⟨
                                                            cong (_∷ ([] Poly+ (p Poly* [ a ])))
                                                                 (sym (+Rid (r · a)))
                                                           ⟩
                       r · a + 0r ∷ ([] Poly+ (p Poly* [ a ])) ∎)
                     ( λ x y i → PolyIsSet (x i0) (x i1) x y i)


  -- Connection between the constant multiplication and the multiplication in the ring
  PolyConst*Nested· : ∀ a b p → a PolyConst* (b PolyConst* p) ≡ (a · b) PolyConst* p
  PolyConst*Nested· =
    λ a b → ElimProp.f (λ p → a PolyConst* (b PolyConst* p) ≡ (a · b) PolyConst* p)
                       refl
                       (λ c p prf → cong ((a · (b · c)) ∷_) prf ∙
                                    cong (_∷ ((a · b) PolyConst* p)) (·Assoc a b c))
                       (PolyIsSet _ _)


  -- We can move the indeterminate from left to outside: px * q = (p * q)x
  0r∷LeftAssoc : ∀ p q → (0r ∷ p) Poly* q ≡ 0r ∷ (p Poly* q)
  0r∷LeftAssoc =
    ElimProp.f (λ p → ∀ q → (0r ∷ p) Poly* q ≡ 0r ∷ (p Poly* q))
               (λ q → cong (_Poly+ [ 0r ])((cong (_Poly+ []) (0rLeftAnnihilatesPoly q))) ∙
                      cong (_∷ []) (+Lid 0r))
               (λ r p b q → cong (_Poly+ (0r ∷ ((r PolyConst* q) Poly+ (0r ∷ (p Poly* q)))))
                                 ((0rLeftAnnihilatesPoly q) ∙ drop0))
               (λ x y i q → PolyIsSet _ _ (x q) (y q) i)


  --Associativity of constant multiplication in relation to polynomial multiplication
  PolyConst*AssocPoly* : ∀ a p q → a PolyConst* (p Poly* q) ≡ (a PolyConst* p) Poly* q
  PolyConst*AssocPoly* =
    λ a → ElimProp.f (λ p → ∀ q → a PolyConst* (p Poly* q) ≡ (a PolyConst* p) Poly* q)
                     (λ q → refl)
                     (λ b p prf q → a PolyConst* ((b PolyConst* q) Poly+
                                    (0r ∷ (p Poly* q))) ≡⟨
                                                          PolyConst*LDistrPoly+ a
                                                                                (b PolyConst* q)
                                                                                (0r ∷ (p Poly* q))
                                                         ⟩
                     (a PolyConst* (b PolyConst* q)) Poly+
                      (a PolyConst* (0r ∷ (p Poly* q))) ≡⟨
                                             cong (_Poly+ (a · 0r ∷ (a PolyConst* (p Poly* q))))
                                                  (PolyConst*Nested· a b q)
                                                         ⟩
                     ((a · b) PolyConst* q) Poly+
                      (a PolyConst* (0r ∷ (p Poly* q))) ≡⟨
                                                    cong (((a · b) PolyConst* q) Poly+_)
                                                         (cong (a · 0r  ∷_)
                                                               (PolyConst*r=Poly*[r] a
                                                                                     (p Poly* q)))
                                                         ⟩
                     ((a · b) PolyConst* q) Poly+
                      (a · 0r ∷ ((p Poly* q) Poly* [ a ])) ≡⟨
                                                         cong (((a · b) PolyConst* q) Poly+_)
                                                              (cong (_∷ ((p Poly* q) Poly* [ a ]))
                                                                    (0RightAnnihilates a))  ⟩
                     ((a · b) PolyConst* q) Poly+
                      (0r ∷ ((p Poly* q) Poly* [ a ])) ≡⟨
                                            cong (((a · b) PolyConst* q) Poly+_)
                                                 (cong (0r ∷_)
                                                       (sym (PolyConst*r=Poly*[r] a (p Poly* q))))
                                                        ⟩
                     ((a · b) PolyConst* q) Poly+
                      (0r ∷ (a PolyConst* (p Poly* q))) ≡⟨
                                                         cong (((a · b) PolyConst* q) Poly+_)
                                                              (cong (0r ∷_) (prf q))
                                                         ⟩
                     ((a · b) PolyConst* q) Poly+
                      (0r ∷ ((a PolyConst* p) Poly* q)) ∎)
                     (λ x y i q → PolyIsSet (x q i0) (x q i1) (x q) (y q) i)


  -- We can move the indeterminate from left to outside: p * qx = (p * q)x
  0r∷RightAssoc : ∀ p q → p Poly* (0r ∷  q) ≡ 0r ∷ (p Poly* q)
  0r∷RightAssoc =
    ElimProp.f (λ p → ∀ q → p Poly* (0r ∷  q) ≡ 0r ∷ (p Poly* q))
               (λ q → sym drop0)
               (λ a p prf q → ((a ∷ p) Poly* (0r ∷ q)) ≡⟨
                                                        cong ( a · 0r + 0r ∷_)
                                                             (cong ((a PolyConst* q) Poly+_ )
                                                                   (prf q))
                                                        ⟩
               a · 0r + 0r ∷ ((a PolyConst* q) Poly+
                 (0r ∷ (p Poly* q))) ≡⟨
                                       cong (_∷ ((a PolyConst* q) Poly+ (0r ∷ (p Poly* q))))
                                            ((+Rid (a · 0r)))
                                      ⟩
               a · 0r ∷ ((a PolyConst* q) Poly+
                 (0r ∷ (p Poly* q))) ≡⟨
                                      cong (_∷ ((a PolyConst* q) Poly+ (0r ∷ (p Poly* q))))
                                           (0RightAnnihilates a) ⟩
               0r ∷ ((a PolyConst* q) Poly+ (0r ∷ (p Poly* q))) ∎)
               (λ x y i q  → PolyIsSet (x q i0) (x q i1) (x q) (y q) i)


  -- We can move the indeterminate around: px * q = p * qx
  0r∷Comm : ∀ p q → (0r ∷ p) Poly* q ≡ p Poly* (0r ∷ q)
  0r∷Comm = ElimProp.f (λ p → ∀ q → (0r ∷ p) Poly* q ≡ p Poly* (0r ∷ q))
                         (λ q → (cong ((0r PolyConst* q) Poly+_) drop0) ∙
                                                0rLeftAnnihilatesPoly q ∙
                                                                 drop0  )
                         (λ a p prf q → ((0r ∷ a ∷ p) Poly* q) ≡⟨ 0r∷LeftAssoc (a ∷ p) q ⟩
                                        0r ∷ ((a ∷ p) Poly* q) ≡⟨ sym (0r∷RightAssoc (a ∷ p) q) ⟩
                                      ((a ∷ p) Poly* (0r ∷ q)) ∎
                       )
                       λ x y i q → PolyIsSet (x q i0) (x q i1) (x q) (y q) i



  --Poly* is commutative
  Poly*Commutative : ∀ p q → p Poly* q ≡ q Poly* p
  Poly*Commutative =
    ElimProp.f (λ p → ∀ q → p Poly* q ≡ q Poly* p)
               (λ q → sym (0PLeftAnnihilates q))
               (λ a p prf q → (a PolyConst* q) Poly+ (0r ∷ (p Poly* q)) ≡⟨
                                       cong ((a PolyConst* q) Poly+_)
                                            (cong (0r ∷_) (prf q)) ⟩
               ((a PolyConst* q) Poly+ (0r ∷ (q Poly* p))) ≡⟨
                                                            cong ((a PolyConst* q) Poly+_)
                                                            (sym (0r∷LeftAssoc q p))
                                                            ⟩
               ((a PolyConst* q) Poly+ ((0r ∷ q) Poly* p)) ≡⟨
                                      cong (_Poly+ ((0r PolyConst* p) Poly+ (0r ∷ (q Poly* p))))
                                           (PolyConst*r=Poly*[r] a q) ⟩
               ((q Poly* [ a ]) Poly+ ((0r ∷ q) Poly* p)) ≡⟨
                                                           cong ((q Poly* [ a ]) Poly+_)
                                                                (0r∷Comm q p)
                                                           ⟩
               ((q Poly* [ a ]) Poly+ (q Poly* (0r ∷ p))) ≡⟨
                                                           sym (Poly*LDistrPoly+ q [ a ] (0r ∷ p))
                                                           ⟩
               (((q Poly* ([ a ] Poly+ (0r ∷ p))))) ≡⟨
                                                     cong (q Poly*_)
                                                          (Poly+Comm [ a ] (0r ∷ p))
                                                     ⟩
               ((q Poly* ((0r ∷ p) Poly+ [ a ]))) ≡⟨
                                                   refl
                                                   ⟩
               (q Poly* ((0r + a) ∷ p)) ≡⟨ cong (q Poly*_)
                                                (cong (_∷ p) (+Lid a))
                                         ⟩
               (q Poly* (a ∷ p)) ∎)
               (λ x y i q → PolyIsSet _ _ (x q ) (y q) i)



  --1P is the right identity of Poly*.
  Poly*Rid : ∀ p → p Poly* 1P ≡ p
  Poly*Rid = λ p → (Poly*Commutative p 1P ∙ Poly*Lid p)


  --Polynomial multiplication right distributes over polynomial addition.
  Poly*RDistrPoly+ : ∀ p q r → (p Poly+ q) Poly* r ≡ (p Poly* r) Poly+ (q Poly* r)
  Poly*RDistrPoly+ = λ p q r → sym (Poly*Commutative r (p Poly+ q)) ∙
                                       Poly*LDistrPoly+ r p q ∙
                                       cong (_Poly+ (r Poly* q)) (Poly*Commutative r p) ∙
                                       cong ((p Poly* r) Poly+_) (Poly*Commutative r q)


  --Polynomial multiplication is associative
  Poly*Associative : ∀ p q r → p Poly* (q Poly* r) ≡  (p Poly* q) Poly* r
  Poly*Associative =
    ElimProp.f (λ p → ∀ q r → p Poly* (q Poly* r) ≡  (p Poly* q) Poly* r )
               (λ _ _ → refl)
               (λ a p prf q r  →
                 ((a ∷ p) Poly* (q Poly* r)) ≡⟨
                                               cong (_Poly+ (0r ∷ (p Poly* (q Poly* r))))
                                                    (PolyConst*AssocPoly* a q r)
                                              ⟩
                 (((a PolyConst* q) Poly* r) Poly+
                  (0r ∷ (p Poly* (q Poly* r)))) ≡⟨
                                                 sym (cong (((a PolyConst* q) Poly* r) Poly+_)
                                                           (cong (_∷ (p Poly* (q Poly* r)))
                                                                 (+Lid 0r)))
                                                 ⟩
                 (((a PolyConst* q) Poly* r) Poly+
                  (0r + 0r ∷ (p Poly* (q Poly* r)))) ≡⟨
                                                 cong (((a PolyConst* q) Poly* r) Poly+_)
                                                      (cong (0r + 0r ∷_)
                                                            (sym (Poly+Lid (p Poly* (q Poly* r)))))
                                                      ⟩
                 (((a PolyConst* q) Poly* r) Poly+
                  (0r + 0r ∷ ([] Poly+ (p Poly* (q Poly* r))))) ≡⟨
                                                         cong (((a PolyConst* q) Poly* r) Poly+_)
                                                              (cong (0r + 0r ∷_)
                                                                    (cong ([] Poly+_)
                                                                          (prf q r)))
                                                                 ⟩
                 (((a PolyConst* q) Poly* r) Poly+
                  (0r + 0r ∷ ([] Poly+ ((p Poly* q) Poly* r)))) ≡⟨
                                                  cong (((a PolyConst* q) Poly* r) Poly+_)
                                                       (cong (_Poly+ (0r ∷ ((p Poly* q) Poly* r)))
                                                             (sym (0rLeftAnnihilatesPoly r)))
                                                                 ⟩
                 (((a PolyConst* q) Poly* r) Poly+
                  ((0r PolyConst* r) Poly+ (0r ∷ ((p Poly* q) Poly* r)))) ≡⟨
                                                     sym (Poly*RDistrPoly+ (a PolyConst* q)
                                                                           (0r ∷ (p Poly* q)) r)
                                                                           ⟩
                 ((((a ∷ p) Poly* q) Poly* r)) ∎)
               (λ x y i q r  → PolyIsSet _ _ (x q r) (y q r) i)



-----------------------------------
-- Main Theorem                  --
-- PolyMod is a Commutative Ring --
-----------------------------------
  PolyCommRing : CommRing ℓ
  PolyCommRing = makeCommRing 0P 1P
                              _Poly+_ _Poly*_ Poly-
                              PolyIsSet
                              Poly+Assoc Poly+Rid Poly+Inverses Poly+Comm
                              Poly*Associative Poly*Rid Poly*LDistrPoly+ Poly*Commutative

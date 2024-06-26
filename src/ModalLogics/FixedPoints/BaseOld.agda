{-# OPTIONS --without-K --safe --guardedness #-}
module ModalLogics.FixedPoints.BaseOld where

open import Common.Program using (Program; free; pure; impure)
open import Common.RegularFormulas using (ActionFormula; _∈_)
open import Data.Bool using (Bool; not)
open import Data.Container using () renaming (Container to Containerˢᵗᵈ; Position to Positionˢᵗᵈ)
open import Data.Empty.Polymorphic using (⊥)
open import Data.Fin using (Fin; _≟_)
open import Data.List using (List; length; findIndexᵇ) renaming (lookup to lookup')
open import Data.List.NonEmpty using (List⁺; [_]; _∷_; _∷⁺_; foldr; toList) renaming (length to length⁺)
open import Data.Maybe using (just; nothing)
open import Data.Nat using (ℕ; _<′_; ≤′-refl)
open import Data.Nat.Induction using (<′-wellFounded)
open import Data.Product using (_×_; _,_; ∃-syntax)
open import Data.String using (String; _==_)
open import Data.Sum using (_⊎_)
open import Data.Unit.Polymorphic using (⊤)
open import Induction.WellFounded using (WellFounded; Acc)
open import Level using (Level; 0ℓ; _⊔_)
open import Relation.Binary using (Rel)
open import Relation.Binary.PropositionalEquality using (_≡_)
open import Relation.Nullary using (¬_; yes; no)

open Bool
open Fin
open List
open ℕ
open Acc

private variable
  ℓ ℓ₁ ℓ₂ ℓ₃ : Level

data Formulaᵈⁿᶠ-var (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁
data Formulaᵈⁿᶠ-con (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁
data Formulaᵈⁿᶠ-dis (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁

infix 60 refᵈⁿᶠ_
infix 55 ⟨_⟩ᵈⁿᶠ_
infix 55 [_]ᵈⁿᶠ_
infix 50 μᵈⁿᶠ_
infix 50 νᵈⁿᶠ_

data Formulaᵈⁿᶠ-var C where
  trueᵈⁿᶠ falseᵈⁿᶠ : ∀ {n} → Formulaᵈⁿᶠ-var C n
  ⟨_⟩ᵈⁿᶠ_ [_]ᵈⁿᶠ_ : ∀ {n} → ActionFormula C → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-var C n
  μᵈⁿᶠ_ νᵈⁿᶠ_ : ∀ {n} → Formulaᵈⁿᶠ-dis C (suc n) → Formulaᵈⁿᶠ-var C n
  refᵈⁿᶠ_ : ∀ {n} → Fin n → Formulaᵈⁿᶠ-var C n

infix 45 con-var_
infixr 40 _∧ᵈⁿᶠ_

data Formulaᵈⁿᶠ-con C where
  con-var_ : ∀ {n} → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-con C n
  _∧ᵈⁿᶠ_ : ∀ {n} → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n

infix 35 dis-con_
infixr 30 _∨ᵈⁿᶠ_

data Formulaᵈⁿᶠ-dis C where
  dis-con_ : ∀ {n} → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-dis C n
  _∨ᵈⁿᶠ_ : ∀ {n} → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n

data FixedPoint : Set where
  leastFP : FixedPoint
  greatestFP : FixedPoint

data Previous (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set (ℓ₁ ⊔ ℓ₂) where
  〔_〕 : FixedPoint × Formulaᵈⁿᶠ-dis C (suc zero) → Previous C (suc zero)
  _∷_ : ∀ {n} → FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) → Previous C n → Previous C (suc n)

lookup : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n₁ : ℕ} → Previous C n₁ → Fin n₁ → FixedPoint × ∃[ n₂ ] Formulaᵈⁿᶠ-dis C (suc n₂) × Previous C (suc n₂)
lookup prev@(〔 fp , d 〕) zero = fp , zero , d , prev
lookup {n₁ = suc n} prev@((fp , d) ∷ _) zero = fp , n , d , prev
lookup (_ ∷ prev) (suc i) = lookup prev i

data Maybe' (α : Set ℓ) : Set ℓ where
  val_ : α → Maybe' α
  done : Maybe' α
  fail : Maybe' α

data Result (C : Containerˢᵗᵈ ℓ₁ ℓ₂) (α : Set ℓ₃) : Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃) where
  res_ : Maybe' (Program C α × FixedPoint × ∃[ n ] Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)) → Result C α
  _×∃_ : ∀ {s} → ActionFormula C → (Positionˢᵗᵈ C s → Result C α) → Result C α
  _×∀_ : ∀ {s} → ActionFormula C → (Positionˢᵗᵈ C s → Result C α) → Result C α

unfold : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → Result C α → Maybe' (Program C α × FixedPoint × ∃[ n ] Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
unfold (res v) o x = o ≡ v → x
unfold (_×∃_ {s = s} af c) o x = s ∈ af × ∃[ p ] unfold (c p) o x
unfold (_×∀_ {s = s} af c) o x = s ∈ af → ∀ p → unfold (c p) o x

_<_ : {α : Set ℓ} → Rel (List⁺ α) 0ℓ
xs < ys = length⁺ xs <′ length⁺ ys

<-wf : {α : Set ℓ} → WellFounded (_<_ {α = α})
<-wf xs = acc<′⇒acc< (<′-wellFounded (length⁺ xs))
  where
    acc<′⇒acc< : {α : Set ℓ} → {xs : List⁺ α} → Acc _<′_ (length⁺ xs) → Acc _<_ xs
    acc<′⇒acc< (acc h) = acc λ hlt → acc<′⇒acc< (h hlt)

unfold⁺ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → (rs : List⁺ (Result C α)) → Acc _<_ rs → Maybe' (Program C α × FixedPoint × ∃[ n ] Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
unfold⁺ (r ∷ []) _ o x = unfold r o x
unfold⁺ (r₁ ∷ r₂ ∷ rs) (acc h) o x = unfold r₁ o x × unfold⁺ (r₂ ∷ rs) (h ≤′-refl) o x

record Container (C : Containerˢᵗᵈ ℓ₁ ℓ₂) (α : Set ℓ₃) : Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃) where
  constructor _▷_
  field
    Shape : ℕ
    Position : Fin Shape → Program C α → List⁺ (Result C α)

open Container

data ModalitySequence (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : Set ℓ₁ where
  ⟪_⟫_ ⟦_⟧_ : ActionFormula C → ModalitySequence C → ModalitySequence C
  ε : ModalitySequence C

apply : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → ModalitySequence C → Program C α → (Maybe' (Program C α) → Result C α) → Result C α
apply (⟪ af ⟫ m) x f with free x
... | pure _ = f fail
... | impure (_ , c) = af ×∃ λ p → apply m (c p) f
apply (⟦ af ⟧ m) x f with free x
... | pure _ = f done
... | impure (_ , c) = af ×∀ λ p → apply m (c p) f
apply ε x f = f (val x)

containerize-var : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n₁ : ℕ} → Formulaᵈⁿᶠ-var C (suc n₁) → Previous C (suc n₁) → ModalitySequence C × Maybe' (FixedPoint × ∃[ n₂ ] Formulaᵈⁿᶠ-dis C (suc n₂) × Previous C (suc n₂))
containerize-var trueᵈⁿᶠ _ = ε , done
containerize-var falseᵈⁿᶠ _ = ε , fail
containerize-var (⟨ af ⟩ᵈⁿᶠ v) prev with containerize-var v prev
... | m , x = ⟪ af ⟫ m , x
containerize-var ([ af ]ᵈⁿᶠ v) prev with containerize-var v prev
... | m , x = ⟦ af ⟧ m , x
containerize-var {n₁ = n₁} (μᵈⁿᶠ d) prev = ε , (val (leastFP , suc n₁ , d , (leastFP , d) ∷ prev))
containerize-var {n₁ = n₁} (νᵈⁿᶠ d) prev = ε , (val (greatestFP , suc n₁ , d , (greatestFP , d) ∷ prev))
containerize-var (refᵈⁿᶠ i) prev = ε , val lookup prev i

containerize-con : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n₁ : ℕ} → Formulaᵈⁿᶠ-con C (suc n₁) → Previous C (suc n₁) → List⁺ (ModalitySequence C × Maybe' (FixedPoint × ∃[ n₂ ] Formulaᵈⁿᶠ-dis C (suc n₂) × Previous C (suc n₂)))
containerize-con (con-var v) prev = [ containerize-var v prev ]
containerize-con (v ∧ᵈⁿᶠ c) prev = containerize-var v prev ∷⁺ containerize-con c prev

containerize-dis : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n₁ : ℕ} → Formulaᵈⁿᶠ-dis C (suc n₁) → Previous C (suc n₁) → List⁺ (List⁺ (ModalitySequence C × Maybe' (FixedPoint × ∃[ n₂ ] Formulaᵈⁿᶠ-dis C (suc n₂) × Previous C (suc n₂))))
containerize-dis (dis-con c) prev = [ containerize-con c prev ]
containerize-dis (c ∨ᵈⁿᶠ d) prev = containerize-con c prev ∷⁺ containerize-dis d prev

containerize : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaᵈⁿᶠ-dis C (suc n) → Previous C (suc n) → (α : Set ℓ₃) → Container C α
containerize {C = C} {n = n} d prev α with containerize-dis d prev
... | xs = container
  where
  container : Container C α
  Shape container = length⁺ xs
  Position container s i = foldr (λ (m , x) acc → position m i x ∷⁺ acc) (λ (m , x) → [ position m i x ]) (lookup' (toList xs) s)
    where
    position : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → ModalitySequence C → Program C α → Maybe' (FixedPoint × ∃[ n ] Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)) → Result C α
    position m i (val x) = apply m i λ { (val o) → res (val (o , x)) ; done → res done ; fail → res fail }
    position m i done = apply m i λ { (val _) → res done ; done → res done ; fail → res fail }
    position m i fail = apply m i λ { (val _) → res fail ; done → res done ; fail → res fail }

extend : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → (Maybe' (Program C α × FixedPoint × ∃[ n ] Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)) → (Maybe' (Program C α × FixedPoint × ∃[ n ] Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)) → Maybe' (Program C α × FixedPoint × ∃[ n ] Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
extend {α = α} w _ (val (x , leastFP , _ , d , prev)) = ∃[ s ] ∀ {o} → let rs = Position (containerize d prev α) s x in unfold⁺ rs (<-wf rs) o (w o)
extend {α = α} _ m (val (x , greatestFP , _ , d , prev)) = ∃[ s ] ∀ {o} → let rs = Position (containerize d prev α) s x in unfold⁺ rs (<-wf rs) o (m o)
extend _ _ done = ⊤
extend _ _ fail = ⊥

record W {C : Containerˢᵗᵈ ℓ₁ ℓ₂} {α : Set ℓ₃} (_ : Maybe' (Program C α × FixedPoint × ∃[ n ] Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n))) : Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
record M {C : Containerˢᵗᵈ ℓ₁ ℓ₂} {α : Set ℓ₃} (_ : Maybe' (Program C α × FixedPoint × ∃[ n ] Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n))) : Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)

record W i where
  inductive
  constructor wᶜ
  field
    In : extend W M i

record M i where
  coinductive
  constructor mᶜ
  field
    Ni : extend W M i

infix 25 _⊨ᵛ_

_⊨ᵛ_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → Program C α → Formulaᵈⁿᶠ-var C zero → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
_ ⊨ᵛ trueᵈⁿᶠ = ⊤
_ ⊨ᵛ falseᵈⁿᶠ = ⊥
x ⊨ᵛ ⟨ af ⟩ᵈⁿᶠ v with free x
... | pure _ = ⊥
... | impure (s , c) = s ∈ af × ∃[ p ] c p ⊨ᵛ v
x ⊨ᵛ [ af ]ᵈⁿᶠ v with free x
... | pure _ = ⊤
... | impure (s , c) = s ∈ af → ∀ p → c p ⊨ᵛ v
x ⊨ᵛ μᵈⁿᶠ d = W (val (x , leastFP , zero , d , 〔 leastFP , d 〕))
x ⊨ᵛ νᵈⁿᶠ d = M (val (x , greatestFP , zero , d , 〔 greatestFP , d 〕))

infix 25 _⊨ᶜ_

_⊨ᶜ_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → Program C α → Formulaᵈⁿᶠ-con C zero → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
x ⊨ᶜ con-var v = x ⊨ᵛ v
x ⊨ᶜ v ∧ᵈⁿᶠ c = x ⊨ᵛ v × x ⊨ᶜ c

infix 25 _⊨ᵈ_

_⊨ᵈ_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → Program C α → Formulaᵈⁿᶠ-dis C zero → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
x ⊨ᵈ dis-con c = x ⊨ᶜ c
x ⊨ᵈ c ∨ᵈⁿᶠ d = x ⊨ᶜ c ⊎ x ⊨ᵈ d

infix 60 refⁱ_
infix 55 ~ⁱ_
infix 50 ⟨_⟩ⁱ_
infix 50 [_]ⁱ_
infixr 45 _∧ⁱ_
infixr 40 _∨ⁱ_
infixr 35 _⇒ⁱ_
infix 30 μⁱ_
infix 30 νⁱ_

data Formulaⁱ (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁ where
  trueⁱ falseⁱ : ∀ {n} → Formulaⁱ C n
  ~ⁱ_ : ∀ {n} → Formulaⁱ C n → Formulaⁱ C n
  _∧ⁱ_ _∨ⁱ_ _⇒ⁱ_ : ∀ {n} → Formulaⁱ C n → Formulaⁱ C n → Formulaⁱ C n
  ⟨_⟩ⁱ_ [_]ⁱ_ : ∀ {n} → ActionFormula C → Formulaⁱ C n → Formulaⁱ C n
  μⁱ_ νⁱ_ : ∀ {n} → Formulaⁱ C (suc n) → Formulaⁱ C n
  refⁱ_ : ∀ {n} → Fin n → Formulaⁱ C n

infix 25 _⊨ⁱ_

_⊨ⁱ_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → Program C α → Formulaⁱ C zero → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
x ⊨ⁱ fⁱ = x ⊨ᵈ f'→fᵈⁿᶠ (fⁱ→f' fⁱ)
  where
  infix 60 ref'〔_〕_
  infix 50 ⟨_⟩'_
  infix 50 [_]'_
  infixr 45 _∧'_
  infixr 40 _∨'_
  infix 30 μ'_
  infix 30 ν'_

  data Formula' (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁ where
    true' false' : ∀ {n} → Formula' C n
    _∧'_ _∨'_ : ∀ {n} → Formula' C n → Formula' C n → Formula' C n
    ⟨_⟩'_ [_]'_ : ∀ {n} → ActionFormula C → Formula' C n → Formula' C n
    μ'_ ν'_ : ∀ {n} → Formula' C (suc n) → Formula' C n
    ref'〔_〕_ : ∀ {n} → Bool → Fin n → Formula' C n

  flipRef : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Fin n → Formula' C n → Formula' C n
  flipRef _ true' = true'
  flipRef _ false' = false'
  flipRef x (f'₁ ∧' f'₂) = flipRef x f'₁ ∧' flipRef x f'₂
  flipRef x (f'₁ ∨' f'₂) = flipRef x f'₁ ∨' flipRef x f'₂
  flipRef x (⟨ af ⟩' f') = ⟨ af ⟩' flipRef x f'
  flipRef x ([ af ]' f') = [ af ]' flipRef x f'
  flipRef x (μ' f') = μ' flipRef (suc x) f'
  flipRef x (ν' f') = ν' flipRef (suc x) f'
  flipRef x (ref'〔 b 〕 i) with i ≟ x
  ... | no _ = ref'〔 b 〕 i
  ... | yes _ = ref'〔 not b 〕 i

  negate : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formula' C n → Formula' C n
  negate true' = false'
  negate false' = true'
  negate (f'₁ ∧' f'₂) = negate f'₁ ∨' negate f'₂
  negate (f'₁ ∨' f'₂) = negate f'₁ ∧' negate f'₂
  negate (⟨ af ⟩' f') = [ af ]' negate f'
  negate ([ af ]' f') = ⟨ af ⟩' negate f'
  negate (μ' f') = ν' flipRef zero (negate f')
  negate (ν' f') = μ' flipRef zero (negate f')
  negate (ref'〔 b 〕 i) = ref'〔 not b 〕 i

  fⁱ→f' : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaⁱ C n → Formula' C n
  fⁱ→f' trueⁱ = true'
  fⁱ→f' falseⁱ = false'
  fⁱ→f' (~ⁱ fⁱ) = negate (fⁱ→f' fⁱ)
  fⁱ→f' (fⁱ₁ ∧ⁱ fⁱ₂) = fⁱ→f' fⁱ₁ ∧' fⁱ→f' fⁱ₂
  fⁱ→f' (fⁱ₁ ∨ⁱ fⁱ₂) = fⁱ→f' fⁱ₁ ∨' fⁱ→f' fⁱ₂
  fⁱ→f' (fⁱ₁ ⇒ⁱ fⁱ₂) = negate (fⁱ→f' fⁱ₁) ∨' fⁱ→f' fⁱ₂
  fⁱ→f' (⟨ af ⟩ⁱ fⁱ) = ⟨ af ⟩' fⁱ→f' fⁱ
  fⁱ→f' ([ af ]ⁱ fⁱ) = [ af ]' fⁱ→f' fⁱ
  fⁱ→f' (μⁱ fⁱ) = μ' fⁱ→f' fⁱ
  fⁱ→f' (νⁱ fⁱ) = ν' fⁱ→f' fⁱ
  fⁱ→f' (refⁱ i) = ref'〔 true 〕 i

  merge-dis-dis-or : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
  merge-dis-dis-or (dis-con c) d = c ∨ᵈⁿᶠ d
  merge-dis-dis-or (c ∨ᵈⁿᶠ d₁) d₂ = c ∨ᵈⁿᶠ merge-dis-dis-or d₁ d₂

  merge-con-con : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n
  merge-con-con (con-var v) c = v ∧ᵈⁿᶠ c
  merge-con-con (v ∧ᵈⁿᶠ c₁) c₂ = v ∧ᵈⁿᶠ merge-con-con c₁ c₂

  merge-con-dis : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
  merge-con-dis c₁ (dis-con c₂) = dis-con (merge-con-con c₁ c₂)
  merge-con-dis c₁ (c₂ ∨ᵈⁿᶠ d₂) = merge-con-con c₁ c₂ ∨ᵈⁿᶠ merge-con-dis c₁ d₂

  merge-dis-dis-and : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
  merge-dis-dis-and (dis-con c) d = merge-con-dis c d
  merge-dis-dis-and (c ∨ᵈⁿᶠ d₁) d₂ = merge-dis-dis-or (merge-con-dis c d₂) (merge-dis-dis-and d₁ d₂)

  f'→fᵈⁿᶠ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formula' C n → Formulaᵈⁿᶠ-dis C n
  f'→fᵈⁿᶠ true' = dis-con (con-var trueᵈⁿᶠ)
  f'→fᵈⁿᶠ false' = dis-con (con-var falseᵈⁿᶠ)
  f'→fᵈⁿᶠ (f'₁ ∧' f'₂) = merge-dis-dis-and (f'→fᵈⁿᶠ f'₁) (f'→fᵈⁿᶠ f'₂)
  f'→fᵈⁿᶠ (f'₁ ∨' f'₂) = merge-dis-dis-or (f'→fᵈⁿᶠ f'₁) (f'→fᵈⁿᶠ f'₂)
  f'→fᵈⁿᶠ (⟨ af ⟩' f') = merge-∃-dis af (f'→fᵈⁿᶠ f')
    where
    merge-∃-var : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-var C n
    merge-∃-var af v = ⟨ af ⟩ᵈⁿᶠ v

    merge-∃-con : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n
    merge-∃-con af (con-var v) = con-var (merge-∃-var af v)
    merge-∃-con af (v ∧ᵈⁿᶠ c) = merge-∃-var af v ∧ᵈⁿᶠ merge-∃-con af c

    merge-∃-dis : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
    merge-∃-dis af (dis-con c) = dis-con (merge-∃-con af c)
    merge-∃-dis af (c ∨ᵈⁿᶠ d) = merge-∃-con af c ∨ᵈⁿᶠ merge-∃-dis af d
  f'→fᵈⁿᶠ ([ af ]' f') = merge-∀-dis af (f'→fᵈⁿᶠ f')
    where
    merge-∀-var : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-var C n
    merge-∀-var af v = [ af ]ᵈⁿᶠ v

    merge-∀-con : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n
    merge-∀-con af (con-var v) = con-var (merge-∀-var af v)
    merge-∀-con af (v ∧ᵈⁿᶠ c) = merge-∀-var af v ∧ᵈⁿᶠ merge-∀-con af c

    merge-∀-dis : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
    merge-∀-dis af (dis-con c) = dis-con (merge-∀-con af c)
    merge-∀-dis af (c ∨ᵈⁿᶠ d) = merge-∀-con af c ∨ᵈⁿᶠ merge-∀-dis af d
  f'→fᵈⁿᶠ (μ' f') = dis-con (con-var (μᵈⁿᶠ f'→fᵈⁿᶠ f'))
  f'→fᵈⁿᶠ (ν' f') = dis-con (con-var (νᵈⁿᶠ f'→fᵈⁿᶠ f'))
  f'→fᵈⁿᶠ (ref'〔 false 〕 _) = dis-con con-var falseᵈⁿᶠ
  f'→fᵈⁿᶠ (ref'〔 true 〕 i) = dis-con (con-var (refᵈⁿᶠ i))

infix 60 ref_
infix 55 ~_
infix 50 ⟨_⟩_
infix 50 [_]_
infixr 45 _∧_
infixr 40 _∨_
infixr 35 _⇒_
infix 30 μ_．_
infix 30 ν_．_

data Formula (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : Set ℓ₁ where
  true false : Formula C
  ~_ : Formula C → Formula C
  _∧_ _∨_ _⇒_ : Formula C → Formula C → Formula C
  ⟨_⟩_ [_]_ : ActionFormula C → Formula C → Formula C
  μ_．_ ν_．_ : String → Formula C → Formula C
  ref_ : String → Formula C

infix 25 _⊨_

_⊨_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → Program C α → Formula C → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
x ⊨ f = x ⊨ⁱ f→fⁱ f []
  where
  f→fⁱ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → Formula C → (xs : List String) → Formulaⁱ C (length xs)
  f→fⁱ true _ = trueⁱ
  f→fⁱ false _ = falseⁱ
  f→fⁱ (~ f) xs = ~ⁱ f→fⁱ f xs
  f→fⁱ (f₁ ∧ f₂) xs = f→fⁱ f₁ xs ∧ⁱ f→fⁱ f₂ xs
  f→fⁱ (f₁ ∨ f₂) xs = f→fⁱ f₁ xs ∨ⁱ f→fⁱ f₂ xs
  f→fⁱ (f₁ ⇒ f₂) xs = f→fⁱ f₁ xs ⇒ⁱ f→fⁱ f₂ xs
  f→fⁱ (⟨ af ⟩ f) xs = ⟨ af ⟩ⁱ f→fⁱ f xs
  f→fⁱ ([ af ] f) xs = [ af ]ⁱ f→fⁱ f xs
  f→fⁱ (μ x ． f) xs = μⁱ f→fⁱ f (x ∷ xs)
  f→fⁱ (ν x ． f) xs = νⁱ f→fⁱ f (x ∷ xs)
  f→fⁱ (ref x) xs with findIndexᵇ (_==_ x) xs
  ... | just i = refⁱ i
  ... | nothing = falseⁱ

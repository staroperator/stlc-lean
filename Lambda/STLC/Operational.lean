import Lambda.Rel
import Lambda.STLC.Syntax

open Term in
@[aesop unsafe [constructors]]
inductive Step : Rel (Term Γ T) where
| lam : Step t t' → Step (λ' t) (λ' t')
| app₁ : Step t₁ t₁' → Step (t₁ ⬝ t₂) (t₁' ⬝ t₂)
| app₂ : Step t₂ t₂' → Step (t₁ ⬝ t₂) (t₁ ⬝ t₂')
| beta : Step (λ' t₁ ⬝ t₂) (t₁[↦ t₂]ˢ)
| ite₁ : Step t₁ t₁' → Step (ite t₁ t₂ t₃) (ite t₁' t₂ t₃)
| ite₂ : Step t₂ t₂' → Step (ite t₁ t₂ t₃) (ite t₁ t₂' t₃)
| ite₃ : Step t₃ t₃' → Step (ite t₁ t₂ t₃) (ite t₁ t₂ t₃')
| ite_true : Step (Term.ite true t₁ t₂) t₁
| ite_false : Step (Term.ite false t₁ t₂) t₂
| pair₁ : Step t₁ t₁' → Step ⟪t₁, t₂⟫ ⟪t₁', t₂⟫
| pair₂ : Step t₂ t₂' → Step ⟪t₁, t₂⟫ ⟪t₁, t₂'⟫
| fst : Step t₁ t₂ → Step t₁.fst t₂.fst
| snd : Step t₁ t₂ → Step t₁.snd t₂.snd
| sigma₁ : Step ⟪t₁, t₂⟫.fst t₁
| sigma₂ : Step ⟪t₁, t₂⟫.snd t₂
infix:55 " ⟶ " => Step

def Reduce : Rel (Term Γ T) := Step.Multi
infix:55 " ⟶* " => Reduce

def DefEquiv : Rel (Term Γ T) := Step.Equiv
infix:55 " ≡ " => DefEquiv



lemma Step.weaken {ρ : Γ ⊆ʷ Δ} :
  t ⟶ t' → t[ρ]ʷ ⟶ t'[ρ]ʷ := by
  intro h
  induction h generalizing Δ <;> simp
  case beta =>
    rw [substitution_weaken]
    constructor
  all_goals aesop

lemma Step.inversion_weaken {ρ : Γ ⊆ʷ Δ} :
  t[ρ]ʷ ⟶ t' → ∃ t'', t ⟶ t'' ∧ t' = t''[ρ]ʷ := by
  intro h
  generalize h₁ : t[ρ]ʷ = t₁ at h
  induction h generalizing Γ
  case beta =>
    cases t <;> simp at h₁
    rcases h₁ with ⟨h₁, h₂, h₃⟩; subst h₁ h₃
    rename Term _ (_ ⇒ _) => t
    cases t <;> simp at h₂; subst h₂
    exists _, Step.beta
    rw [substitution_weaken]
  case ite_true | ite_false =>
    cases t <;> simp at h₁
    rcases h₁ with ⟨h₁, h₂, h₃⟩; subst h₂ h₃
    rename Term _ TBool => t
    cases t <;> simp at h₁
    aesop
  case sigma₁ | sigma₂ =>
    cases t <;> simp at h₁
    rcases h₁ with ⟨h₁, h₂⟩; subst h₁
    rename Term _ (_ * _) => t
    cases t <;> simp at h₂
    rcases h₂ with ⟨h₂, h₃⟩; subst h₂ h₃
    aesop
  all_goals
    cases t <;> injection h₁
    subst_vars
    rename ∀ _, _ => ih
    rcases ih rfl with ⟨_, h₁, h₂⟩
    subst h₂
    rw [←Term.weaken]
    aesop

lemma Step.subst {σ : Subst Γ Δ} : t ⟶ t' → t[σ]ˢ ⟶ t'[σ]ˢ := by
  intro h
  induction h generalizing Δ <;> simp
  case beta =>
    rw [substitution]
    constructor
  all_goals aesop



def Normal (t : Term Γ T) := Step.Normal t

mutual
def NeutralForm : Term Γ T → Prop
| #_ => True
| t₁ ⬝ t₂ => NeutralForm t₁ ∧ NormalForm t₂
| Term.ite t₁ t₂ t₃ => NeutralForm t₁ ∧ NormalForm t₂ ∧ NormalForm t₃
| Term.fst t => NeutralForm t
| Term.snd t => NeutralForm t
| _ => False
def NormalForm : Term Γ T → Prop
| λ' t => NormalForm t
| Term.true | Term.false => True
| ⟪t₁, t₂⟫ => NormalForm t₁ ∧ NormalForm t₂
| t => NeutralForm t
end

lemma neutral_normal : NeutralForm t → NormalForm t := by
  cases t <;> simp [NeutralForm, NormalForm]

theorem normal_iff_normal_form : Normal t ↔ NormalForm t := by
  constructor
  · intro h₁
    induction t with simp [NeutralForm, NormalForm] at *
    | lam t ih => apply ih; intro _ _; aesop
    | app t₁ t₂ ih₁ ih₂ =>
      constructor
      · have h₂ : Normal t₁ := by intro _ _; aesop
        apply ih₁ at h₂
        cases t₁ <;> (unfold NormalForm at h₂; try exact h₂)
        exfalso; aesop
      · apply ih₂; intro _ _; aesop
    | ite t₁ t₂ t₃ ih₁ ih₂ ih₃ =>
      constructor
      · have h₂ : Normal t₁ := by intro _ _; aesop
        apply ih₁ at h₂
        cases t₁ <;> unfold NormalForm at h₂ <;>
          (try exact h₂) <;> exfalso <;> aesop
      constructor <;> apply_assumption <;> intro _ _ <;> aesop
    | pair t₁ t₂ ih₁ ih₂ =>
      constructor <;> apply_assumption <;> intro _ _ <;> aesop
    | fst t ih | snd t ih =>
      have h₂ : Normal t := by intro _ h₂; aesop
      apply ih at h₂
      cases t <;> unfold NormalForm at h₂ <;>
        (try exact h₂); exfalso; aesop
  · intro h₁
    induction t with simp [NeutralForm, NormalForm] at *
    | var | true | false => intros _ h₂; cases h₂
    | lam t ih =>
      intros _ h₂
      cases h₂ with
      | lam h₂ => apply ih h₁; exact h₂
    | app t₁ t₂ ih₁ ih₂ =>
      rcases h₁ with ⟨h₁, h₂⟩
      intros _ h₃
      cases h₃ with
      | app₁ h₃ => apply ih₁ (neutral_normal h₁); exact h₃
      | app₂ h₃ => apply ih₂ h₂; exact h₃
      | beta => simp [NeutralForm] at h₁
    | ite t₁ t₂ t₃ ih₁ ih₂ ih₃ =>
      rcases h₁ with ⟨h₁, h₂, h₃⟩
      intros _ h₄
      cases h₄ with
      | ite₁ h₄ => apply ih₁ (neutral_normal h₁); exact h₄
      | ite₂ h₄ => apply ih₂ h₂; exact h₄
      | ite₃ h₄ => apply ih₃ h₃; exact h₄
      | ite_true | ite_false => simp [NeutralForm] at h₁
    | pair t₁ t₂ ih₁ ih₂ =>
      rcases h₁ with ⟨h₁, h₂⟩
      intros _ h₃
      cases h₃ with
      | pair₁ h₃ => apply ih₁ h₁; exact h₃
      | pair₂ h₃ => apply ih₂ h₂; exact h₃
    | fst t ih =>
      intros _ h₂
      cases h₂ with
      | fst h₂ => apply ih (neutral_normal h₁); exact h₂
      | sigma₁ => simp [NeutralForm] at h₁
    | snd t ih =>
      intros _ h₂
      cases h₂ with
      | snd h₂ => apply ih (neutral_normal h₁); exact h₂
      | sigma₂ => simp [NeutralForm] at h₁

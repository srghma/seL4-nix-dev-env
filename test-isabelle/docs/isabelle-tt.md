### 1. What Isabelle/HOL has instead
Isabelle/HOL is based on **Church's simple type theory** with:

### 2. The nuance: Isabelle is a generic framework
Isabelle/Pure is a meta-logic that hosts multiple object logics. Technically, Isabelle ships with:
- **`src/CTT`** — Martin-Löf Constructive Type Theory (with dependent types, no universes)
- **`src/Cube`** — Barendregt's $\lambda$-cube
- **`src/ZF`** — Untyped Zermelo–Fraenkel set theory, which has set-level $\Pi$ and $\Sigma$ constructions

In practice, though, those are small/specialized—they do **not** have HOL's libraries, `datatype`/`fun` packages, or automation (`auto`, Sledgehammer, SMT solvers).

### 3. How dependent-type use cases are handled in Isabelle/HOL
- **Explicit invariants (most common, e.g. in `l4v`):** Use `'a list` plus an assumption/invariant like `length xs = n`, or use `locale`s to fix parameters and assumptions.
- **Finite index types (John Harrison's trick, e.g. `HOL-Analysis` `vec`):** Encode a fixed size as the cardinality `CARD('n)` of a finite type `'n :: finite` (for example, `real^3` is `(real, 3) vec` where `3` is a type). You still can't quantify over a *term* `n :: nat` inside a type, though `Types_To_Sets` can sometimes transfer theorems between type-level and set-level formulations.
- **Shallow/deep embeddings:** Embed a typed language as an inductive typing relation `\<Gamma> \<turnstile> e : \<tau>` over an untyped/simply-typed AST (which is the standard Isabelle style for programming language metatheory).

### Why?
Giving up dependent types keeps type inference automatic (no `eq_rect` / transport hell when `n + m` vs `m + n` show up in types) and makes first-order/SMT automation like **Sledgehammer** work directly out of the box.


### 1. What is Church's Simple Type Theory (STT)?

Proposed by Alonzo Church in 1940, it is **classical higher-order logic built on top of the simply typed $\lambda$-calculus**:
- Every term has a **type** (preventing Russell's paradox by forbidding untyped self-application `x x`).
- Base types include `bool` (Church's $o$) and individuals (`ind`, Church's $\iota$), plus function types `'a ⇒ 'b`.
- "Simple" means types only classify *values* (unlike Russell's *ramified* type theory with orders/levels) and **cannot depend on terms**.
- **Isabelle/HOL** extends Church's STT with **ML-style (Hindley–Milner) polymorphism**, **Haskell-style type classes**, and **non-empty subtypes (`typedef`)**. Every type in HOL is guaranteed to be non-empty.

---

### 2. What are the axioms of Isabelle/HOL?

Isabelle/HOL sits inside **Isabelle/Pure** (a minimal intuitionistic higher-order meta-logic providing $\bigwedge$, $\Longrightarrow$, $\equiv$, and $\alpha\beta\eta$-conversion). Inside `src/HOL/`, everything (`nat`, `int`, `real`, `list`, `datatype`, `fun`, etc.) is derived *conservatively* (by definitions, not axioms) from just **13 axioms** across 4 theories:

**`HOL.thy` (8 core axioms — equality, logic, definite description):**
1. `refl`: `t = (t::'a)` *(reflexivity)*
2. `subst`: `s = t ⟹ P s ⟹ P t` *(Leibniz substitution)*
3. `ext`: `(⋀x::'a. (f x :: 'b) = g x) ⟹ (λx. f x) = (λx. g x)` *(function extensionality)*
4. `the_eq_trivial`: `(THE x. x = a) = (a::'a)` *(definite description operator)*
5. `impI`: `(P ⟹ Q) ⟹ P ⟶ Q` *(implication intro)*
6. `mp`: `P ⟶ Q ⟹ P ⟹ Q` *(modus ponens)*
7. `iff`: `(P ⟶ Q) ⟹ (Q ⟶ P) ⟹ (P = Q)` *(propositional extensionality)*
8. `True_or_False`: `(P = True) ∨ (P = False)` *(excluded middle — makes HOL classical)*

**`Hilbert_Choice.thy` (1 axiom — Axiom of Choice):**
9. `someI`: `P x ⟹ P (SOME x. P x)` *(Hilbert's $\varepsilon$-operator)*

**`Nat.thy` (2 axioms — Axiom of Infinity on `ind`):**
10. `Suc_Rep_inject`: `Suc_Rep x = Suc_Rep y ⟹ x = y`
11. `Suc_Rep_not_Zero_Rep`: `Suc_Rep x ≠ Zero_Rep`

**`Set.thy` (2 axioms — `'a set` isomorphic to `'a ⇒ bool`):**
12. `mem_Collect_eq`: `member a (Collect P) = P a`
13. `Collect_mem_eq`: `Collect (λx. member x A) = A`

*(Plus `typedef`, a checked definitional mechanism that creates a new type isomorphic to a proven non-empty subset `{x. P x}`.)*

---

### 3. Where in the $\lambda$-cube is it?

First, a key distinction: Barendregt's $\lambda$-cube classifies **propositions-as-types (Curry–Howard)** type theories. **Isabelle/HOL is not propositions-as-types**: propositions are just terms of type `bool`, and proofs are ML kernel derivations rather than typed $\lambda$-terms inside the language.

Looking purely at the **term & type system** on the $\lambda$-cube's 3 axes (*terms→types* = dependent types $\lambda P$, *types→terms* = polymorphism $\lambda 2$, *types→types* = type operators $\lambda\underline{\omega}$):

- **Church's original 1940 STT** sits at the **bottom origin corner: $\lambda\!\to$** (simply typed $\lambda$-calculus — none of the 3 axes enabled).
- **Isabelle/HOL's type system** sits **strictly between $\lambda\!\to$ and $\lambda 2$** (plus fixed-arity type constructors like `'a list`):
  - **Dependent types ($\lambda P$ axis): OFF** — types cannot depend on terms.
  - **Polymorphism ($\lambda 2$ axis): PARTIAL** — it has rank-1 (prenex/ML-style) schematic type variables `'a`, *not* full first-class impredicative `∀α.` quantifiers inside terms like System F ($\lambda 2$).
  - **Type operators ($\lambda\underline{\omega}$ axis): PARTIAL** — it has built-in/defined type constructors (`'a list`, `'a × 'b`), *not* arbitrary type-level $\lambda$-abstractions (`Λα. ...`).

By contrast, **Lean** and **Rocq/Coq** sit at the **top corner $\lambda C$** (Calculus of Constructions, extended with inductive types and universes) where all three axes are fully enabled.
